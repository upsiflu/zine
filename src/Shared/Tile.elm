module Shared.Tile exposing
    ( Tile, singleton
    , Msg, update
    , view
    , Mode(..)
    )

{-|

@docs Tile, singleton


# Update

@docs Msg, update


# View

@docs view


# Gui Schema

We have a pool of Tiles.
One of these tiles is selected (Zipper.current).
(For multiselect, we will introduce a marching ants or Lasso tile which can be created by the Shift+Click)

The Gui offers three mutually exclusive modes to represent any Ui item:

  - _Deselected_: any tile not above a selected one
  - _Selected_: the current tile plus the ones it carries
  - _Current_: the current tile. It is implicitly selected, of course.

We have to distinguish these states from the css pseudoclasses, which are cascading:

  - :target is very similar to Gui.Current
  - :active is very similar to Gui.Selected
  - :focus is mostly controlled by the user agent, for accessibility. It's where input happens.
  - :focus-visible is a subset of :focus that needs a loud visual bell for accessibility.
  - :focus-within may be useful just in css to help orient on the page. Can be raised or blinking.

**Dragging** the selected tile will move all tiles above it whose surface is more than half overlapping it.

**Clicking** an unselected tile will

  - deselect the previously selected tile and those on top of it
  - change Tile.Mode to `Normal { onSelect : msg }`
  - change the Url to reflect the new :target
  - select the newly clicked tile as well as those on top of it
  - change their Tile.Mode to `Selected { onBlur : msg }`

type Mode msg
= Normal { onSelect : msg }
| Selected { onDeselect : msg }
| Editor { onBlur : msg, howToMessage : Msg -> msg }

-}

import Json.Decode as Decode exposing (index, int, list, map2, string)
import Json.Decode.Pipeline exposing (requiredAt)
import View.Gui as Gui exposing (On)
import W3.Html exposing (Event, div, node, on, text)
import W3.Html.Attributes exposing (attribute, class)


{-| **Attributes** are managed by Elm, synchronized through the `view` cycle, and may be superseded on the JS side by recent user input:

  - `release` (the contents of the article);
  - `format` (the most recent formatting command issued through the toolbar)

**Shadows** are managed on the JS side and synchronized via custom events:

  - `draft` (the momentary editor contents);
  - `caret` (the style properties at the momentary user cursor or selection)

-}
type Tile
    = Hypertext HypertextProperties


type alias HypertextProperties =
    -- Shadows (state held by the JS cusom element and sent through custom events)
    { draft : Draft
    , caret : Caret
    , size : Vector
    , delta : Vector

    -- Attributes (state held by Elm)
    , release : Release
    , format : Format
    }


{-| -}
singleton : String -> Tile
singleton s =
    Hypertext
        -- Events
        { draft = Draft s
        , caret = Caret []
        , size = Vector ( 0, 0 )
        , delta = Vector ( 0, 0 )

        -- Attributes
        , release = s
        , format = ""
        }



-- Shadows


{-| The text that the user is actually editing (received from JS)
-}
type Draft
    = Draft String


{-| Active formats under the current cursor
-}
type Caret
    = Caret (List String)


{-| -}
type Vector
    = Vector ( Int, Int )


vector =
    map2 Tuple.pair (index 0 int) (index 1 int)



-- Attributes


{-| The most recent formatting command (sent to JS through view)
-}
type alias Format =
    String


type alias Release =
    String


{-| A `Mode` determines interactivity,
and is itself determined by the caller.
-}
type Mode msg
    = Normal { onSelect : msg }
    | Selected { onDeselect : msg }
    | Editor { onDeselect : msg, howToMessage : Msg -> msg }


{-| -}
type Msg
    = DraftChanged Draft
    | CaretChanged Caret
    | SizeChanged Vector
    | DeltaChanged Vector
      -- Attributes
    | FormatIssued Format


{-| -}
update : Msg -> Tile -> Tile
update msg tile =
    case tile of
        Hypertext properties ->
            updateHypertext msg properties


{-| -}
updateHypertext : Msg -> HypertextProperties -> Tile
updateHypertext msg properties =
    Hypertext <|
        case msg of
            -- Events
            DraftChanged new ->
                { properties | draft = new }

            CaretChanged new ->
                { properties | caret = new }

            SizeChanged new ->
                { properties | size = new }

            DeltaChanged new ->
                { properties | delta = new }

            -- Attributes
            FormatIssued new ->
                { properties | format = new }


{-| Mosaic constructs the `Mode` viewModel.
-}
view :
    Mode msg
    -> Tile
    -> Gui.Document { mode | expanded : On, collapsed : On } msg
view mode tile =
    let
        face =
            Gui.icon "Hypertext" "text_fields"

        propagate key shape message decoder =
            requiredAt [ "detail", key ] decoder (Decode.succeed shape)
                |> Decode.map (\result -> Event (message result) False False)
                |> on key

        viewHypertext properties =
            case mode of
                Normal { onSelect } ->
                    Gui.collapsed_document
                        (Gui.createToolbar
                            (Gui.literal "Focused Tile" |> Gui.with_hint "This tile is focused")
                            [ Gui.Toggle (Gui.literal "Edit") { toggle = onSelect, is_on = False } ]
                        )
                        []
                        [ node "custom-editor"
                            [ attribute "state" "done"
                            , attribute "release" properties.release
                            , attribute "format" properties.format
                            , attribute "id" "no_id"
                            ]
                            []
                        ]

                Selected { onDeselect } ->
                    Gui.collapsed_document
                        (Gui.createToolbar
                            (Gui.literal "Focused Tile" |> Gui.with_hint "This tile is focused")
                            [ Gui.Toggle (Gui.literal "Edit") { toggle = onSelect, is_on = False } ]
                        )
                        []
                        [ node "custom-editor"
                            [ attribute "state" "done"
                            , attribute "release" properties.release
                            , attribute "format" properties.format
                            , attribute "id" "no_id"
                            ]
                            []
                        ]

                Editor { howToMessage, onDeselect } ->
                    Gui.expanded_document
                        (properties.caret |> toolbar (FormatIssued >> howToMessage) onDeselect)
                        []
                        [ node "custom-editor"
                            [ attribute "state" "editing"
                            , attribute "release" properties.release
                            , attribute "format" properties.format
                            , attribute "id" "no_id"

                            -- article
                            , string |> propagate "draft" Draft (DraftChanged >> howToMessage)
                            , list string |> propagate "caret" Caret (CaretChanged >> howToMessage)
                            ]
                            []
                        ]
    in
    case tile of
        Hypertext properties ->
            viewHypertext properties


toolbar : (Format -> msg) -> msg -> Caret -> Gui.Toolbar msg
toolbar on_format onDeselect (Caret caret) =
    let
        is_in : List a -> a -> Bool
        is_in l a =
            List.member a l

        toggle : String -> String -> String -> Gui.Face msg -> Gui.Control msg
        toggle command revert match face =
            face
                |> Gui.Toggle
                |> (\needs_toggle_and_is_on -> decide_state command revert match |> needs_toggle_and_is_on)

        decide_state on off =
            is_in caret
                >> (\activated ->
                        { toggle =
                            on_format
                                (if activated then
                                    off

                                 else
                                    on
                                )
                        , is_on = activated
                        }
                   )
    in
    [ Gui.icon "Numbered list" "format_list_numbered"
        |> toggle "makeOrderedList" "removeList" "OL"
    , Gui.icon "List with bullet points" "format_list_bulleted"
        |> toggle "makeUnorderedList" "removeList" "UL"
    , Gui.icon "Decrease Level" "format_indent_decrease"
        |> toggle "decreaseLevel" "increaseListLevel" "neverj"
    , Gui.icon "Increase Level" "format_indent_increase"
        |> toggle "increaseLevel" "decreaseListLevel" "never"
    , Gui.sample "Title" "h1" [ text "Title" ]
        |> toggle "makeTitle" "removeHeader" "H1"
    , Gui.sample "Chapter Heading" "h2" [ text "Heading" ]
        |> toggle "makeHeader" "removeHeader" "H2"
    , Gui.sample "Secondary Heading" "h3" [ text "Secondary" ]
        |> toggle "makeSubheader" "removeHeader" "H3"
    , Gui.sample "Strong emphasis" "T b" [ text "B" ]
        |> toggle "bold" "removeBold" "b"
    , Gui.sample "Emphasis" "T i" [ text "I" ]
        |> toggle "italic" "removeItalic" "i"
    , Gui.icon "Clear formatting" "format_clear"
        |> toggle "removeAllFormatting" "" "?"
    , Gui.icon "Hyperlink" "link"
        |> toggle "addLink" "removeLink" "a"
    , Gui.icon "Clear hyperlink" "link_off"
        |> toggle "removeLink" "" "?"
    , Gui.Toggle
        -- Should be more like, action...
        (Gui.literal "OK")
        { toggle = onDeselect, is_on = False }
    ]
        |> Gui.createToolbar
            (Gui.literal "❦" |> Gui.with_hint "Formatting")
