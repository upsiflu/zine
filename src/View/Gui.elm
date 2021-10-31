module View.Gui exposing
    ( Item(..)
    , Document(..), State(..), On, collapsed_document, nest_collapsed, expanded_document, nest_expanded, view
    , with_toolbar, with_position, with_delta, with_draggability, with_attributes, with_class, with_info
    , Control(..), Toolbar
    , Face, icon, literal, sample, with_hint, view_face
    , Position, midpoint, add_delta, Delta, zero, running_delta, final_delta, DragTrace(..), new_trace
    , collect, createToolbar
    )

{-| Compose a stateless UI in the `view` phase, based on W3.Aria.


## Create and view nested `Item`s

@docs Item


## Add editable `Document`s

@docs Document, State, On, collapsed_document, nest_collapsed, expanded_document, nest_expanded, view


## Decorate a Document

@docs with_toolbar, with_position, with_delta, with_draggability, with_attributes, with_class, with_info


## Interactivity

@docs Control, Toolbar, toolbar


## Faces

@docs Face, icon, literal, sample, with_hint, view_face


## Positioning and tracing

@docs Position, midpoint, add_delta, Delta, zero, running_delta, final_delta, DragTrace, new_trace

-}

import Html as Untyped
import Json.Decode as Decode exposing (float)
import Json.Decode.Pipeline exposing (required)
import W3.Aria as Aria
import W3.Aria.Attributes exposing (checked, expanded, false, horizontal, orientation, pressed, true)
import W3.Html exposing (..)
import W3.Html.Attributes exposing (class, disabled, draggable, style, title)


{-| has a `Face`, as well as attributes and descendents.
-}
type Item msg
    = Item (Toolbar msg) (List (GlobalAttributes {} msg)) (List (Node FlowContent msg))


collect : Item msg -> List (Item msg) -> Item msg
collect initialItem =
    List.foldl
        (\(Item toolbar0 attr0 nodes0) (Item toolbar1 attr1 nodes1) -> Item (mergeToolbars toolbar0 toolbar1) (attr0 ++ attr1) (nodes0 ++ nodes1))
        initialItem



-- create


{-| composes a Document.
-}
nest_expanded : Document { mode | expanded : On } msg -> Item msg
nest_expanded (Document toolbar attributes contents) =
    Item toolbar
        (Aria.document [ expanded (Just True) ] attributes)
        contents


{-| composes a Document behind an `overlay`.
-}
nest_collapsed : { how_to_expand : msg, controls : List (Control msg) } -> Document { mode | collapsed : On } msg -> Item msg
nest_collapsed overlay (Document face attributes contents) =
    Item face
        (Aria.document [ expanded (Just False) ] (ondblclick overlay.how_to_expand :: attributes))
        (List.map view_control overlay.controls ++ contents)


{-| -}
view : State msg -> Item msg -> Untyped.Html msg
view state (Item ((Toolbar f t) as toolbar) attributes contents) =
    let
        hint =
            (\(Face h _) -> title h) f

        ( incipit, explicit ) =
            case state of
                Deselected how_to_reselect how_to_focus ->
                    ( Aria.checkbox
                        [ checked false ]
                        [ hint, onclick how_to_reselect ]
                    , [ onclick how_to_focus ]
                    )

                Selected how_to_deselect how_to_focus ->
                    ( Aria.checkbox
                        [ checked true ]
                        [ hint, onclick how_to_deselect ]
                    , [ onclick how_to_focus
                      , class [ "gui selected pattern" ]
                      ]
                    )

                Current how_to_assert_focus ->
                    ( Aria.checkbox
                        [ checked true ]
                        [ hint, onclick how_to_assert_focus, class [ "gui focused" ] ]
                    , [ onclick how_to_assert_focus
                      , class [ "gui focused pattern" ]
                      ]
                    )
    in
    button incipit [ view_face f ]
        :: viewToolbar toolbar
        :: contents
        |> div (explicit ++ attributes)
        |> toNode


{-| Unit type for extensible parameter records in phantom types.
-}
type On
    = On


{-| -}
type State msg
    = Deselected msg msg
    | Selected msg msg
    | Current msg


{-| -}
type Control msg
    = Toggle (Face msg) { toggle : msg, is_on : Bool }
    | Check { hint : String, toggle : msg, is_checked : Bool }
    | Input (Face msg) { set : String -> msg, is_set : Bool }
    | Compose (Face msg) (List (Control msg))


{-| -}
view_control : Control msg -> Node FlowContent msg
view_control control =
    let
        title_hint (Face hint _) =
            title hint
    in
    case control of
        Toggle face t ->
            button
                (Aria.button
                    [ if t.is_on then
                        pressed true

                      else
                        pressed false
                    ]
                    [ onclick t.toggle, title_hint face ]
                )
                [ view_face face ]

        _ ->
            button (Aria.button [] [ disabled True ]) [ text "(this control's view is not yet implemented)" ]



-- TOOLBAR


{-| -}
type Toolbar msg
    = Toolbar (Face msg) (List (Control msg))


{--}
mergeToolbars : Toolbar msg -> Toolbar msg -> Toolbar msg
mergeToolbars (Toolbar f0 t0) (Toolbar f1 t1) =
    Toolbar f0 (t0 ++ t1)


{--}
viewToolbar : Toolbar msg -> Node FlowContent msg
viewToolbar (Toolbar f t) =
    let
        title_hint (Face hint _) =
            title hint
    in
    List.map view_control t
        |> (::) (label [] [ view_face f ])
        |> List.map (List.singleton >> li [])
        |> menu
            (Aria.toolbar [ orientation horizontal, expanded (Just True) ] [ class [ "gui" ], title_hint f ])



-- create


{-| -}
createToolbar : Face msg -> List (Control msg) -> Toolbar msg
createToolbar =
    Toolbar



-- FACE


{-| -}
type Face msg
    = Face String (Node PhrasingContent msg)



-- create


{-| -}
icon : String -> String -> Face msg
icon hint string =
    span
        [ class [ "icon", "static" ] ]
        [ span [ class [ "static", "material-icons" ] ] [ text string ] ]
        |> Face hint


{-| -}
literal : String -> Face msg
literal string =
    Face "" (text string)


{-| -}
sample : String -> String -> List (Node PhrasingContent msg) -> Face msg
sample hint name samples =
    span [ class [ "preview", "static" ] ]
        [ span [ class [ name, "static" ] ]
            samples
        ]
        |> Face hint



-- map


{-| -}
with_hint : String -> Face msg -> Face msg
with_hint hint (Face _ html) =
    Face hint html



-- view


{-| -}
view_face : Face msg -> Node PhrasingContent msg
view_face (Face description descendant) =
    span [ class [ "face" ], title description ] [ descendant ]


{-| To limit certain functions on subsets of the Document type, `mode` provides a flexible phantom type parameter
(an extensible record with options that are `On`).
-}
type Document mode msg
    = Document (Toolbar msg) (List (GlobalAttributes {} msg)) (List (Node FlowContent msg))



-- create


{-| -}
collapsed_document : Toolbar msg -> List (GlobalAttributes {} msg) -> List (Node FlowContent msg) -> Document { mode | collapsed : On } msg
collapsed_document =
    Document


{-| -}
expanded_document : Toolbar msg -> List (GlobalAttributes {} msg) -> List (Node FlowContent msg) -> Document { mode | expanded : On } msg
expanded_document =
    Document



-- map


{-| -}
with_toolbar : Toolbar msg -> Document { mode | expanded : On } msg -> Document { mode | expanded : On } msg
with_toolbar t1 (Document t0 attributes contents) =
    Document (mergeToolbars t0 t1) attributes contents


{-| -}
with_position : Position -> Document mode msg -> Document mode msg
with_position { x, y } =
    with_attributes
        [ style "left" (String.fromFloat x ++ "px")
        , style "top" (String.fromFloat y ++ "px")
        ]


{-| -}
with_class : String -> Document mode msg -> Document mode msg
with_class str =
    with_attributes [ class [ str ] ]


{-| -}
with_delta : Delta -> Document mode msg -> Document mode msg
with_delta { x, y } =
    with_attributes
        [ style "transform"
            ("translate(" ++ String.fromInt x ++ "px, " ++ String.fromInt y ++ "px)")
        ]


{-| -}
with_info : Face msg -> Document { mode | expanded : On } msg -> Document { mode | expanded : On } msg
with_info info (Document t attributes contents) =
    Document t attributes (span [ class [ "gui", "info" ] ] [ view_face info ] :: contents)


{-| -}
with_attributes : List (GlobalAttributes {} msg) -> Document mode msg -> Document mode msg
with_attributes new_attributes (Document face attributes contents) =
    Document face (new_attributes ++ attributes) contents


{-| -}
with_draggability :
    (DragTrace -> msg)
    -> (DragTrace -> msg)
    -> DragTrace
    -> Document mode msg
    -> Document mode msg
with_draggability how_to_drag how_to_settle trace =
    let
        decode_delta =
            Decode.succeed DragCoordinates
                |> required "pageX" float
                |> required "pageY" float
                |> Decode.map coordinates_to_delta

        send message =
            Decode.map (\updated_trace -> Event (message updated_trace) False False)

        create_zero_trace =
            decode_delta
                |> Decode.map (\delta -> trace_drag delta Zero)
                |> send how_to_drag

        append_if_running =
            decode_delta
                |> Decode.map (\delta -> trace_drag delta trace)
                |> send how_to_drag

        decode_dragend =
            decode_delta
                |> Decode.map (\delta -> trace_drag delta trace)
                |> Decode.map done_drag_trace
                |> send how_to_settle

        decode_dragexit =
            decode_delta
                |> Decode.map (\delta -> trace_drag delta trace)
                |> Decode.map cancel_drag_trace
                |> send how_to_settle
    in
    with_attributes
        [--style "cursor" "move"
         --, class [ "draggable" ]
         --, style "touch-action" "none"
         --, on "pointerdown" create_zero_trace
         --, on "pointermove" append_if_running
         --, on "pointerup" decode_dragend
         --, on "pointerout" decode_dragexit
        ]


{-| -}
type DragTrace
    = Zero
    | Running Delta (List Delta) Delta
    | Canceled Delta (List Delta) Delta
    | Done Delta (List Delta) Delta



--create


{-| -}
new_trace : DragTrace
new_trace =
    Done zero [] zero



-- map


{-| -}
trace_drag : Delta -> DragTrace -> DragTrace
trace_drag delta trace =
    case trace of
        Zero ->
            Running delta [] delta

        Running final list initial ->
            Running delta (final :: list) initial

        _ ->
            trace


{-| -}
done_drag_trace : DragTrace -> DragTrace
done_drag_trace trace =
    case trace of
        Zero ->
            Zero

        Running final list initial ->
            Done final list initial

        _ ->
            trace


{-| -}
cancel_drag_trace : DragTrace -> DragTrace
cancel_drag_trace trace =
    case trace of
        Zero ->
            Zero

        Running final list initial ->
            Canceled final list initial

        _ ->
            trace


{-| -}
type alias Position =
    { x : Float
    , y : Float
    }



-- create


{-| -}
midpoint : Position
midpoint =
    Position 0 0



-- map


{-| -}
add_delta : Delta -> Position -> Position
add_delta delta { x, y } =
    Position (x + toFloat delta.x) (y + toFloat delta.y)


{-| -}
type alias DragCoordinates =
    { pageX : Float
    , pageY : Float
    }



-- create


{-| -}
coordinates_to_delta : DragCoordinates -> Delta
coordinates_to_delta { pageX, pageY } =
    Delta (round pageX) (round pageY)


{-| -}
type alias Delta =
    { x : Int
    , y : Int
    }



-- create


{-| -}
zero : Delta
zero =
    { x = 0, y = 0 }


{-| -}
running_delta : DragTrace -> Delta
running_delta trace =
    case trace of
        Zero ->
            zero

        Running final _ initial ->
            diff final initial

        Canceled final _ initial ->
            diff final initial

        Done _ _ _ ->
            zero


{-| -}
final_delta : DragTrace -> Delta
final_delta trace =
    case trace of
        Zero ->
            zero

        Running _ _ _ ->
            zero

        Canceled _ _ _ ->
            zero

        Done final _ initial ->
            diff final initial



-- map


{-| -}
diff : Delta -> Delta -> Delta
diff final initial =
    Delta (final.x - initial.x) (final.y - initial.y)
