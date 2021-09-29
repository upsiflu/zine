module Page.Index exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import List.Zipper as Zipper exposing (Zipper)
import Page exposing (PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import Shared.Tile as Tile exposing (Tile)
import View exposing (View)
import View.Gui as Gui
import W3.Html exposing (Event, div, node, on, text)
import W3.Html.Attributes exposing (attribute, class)


type alias Model =
    { mosaic : Zipper Tile
    , isEditing : Bool
    }


type Msg
    = NoOp
    | Edit
    | Ok
    | TileMsg Tile.Msg


type alias RouteParams =
    {}


page : PageWithState RouteParams Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithLocalState
            { init = init
            , subscriptions = \maybePageUrl routeParams path templateModel -> Sub.none
            , update = update
            , view = view
            }


init : Maybe PageUrl -> Shared.Model -> StaticPayload templateData routeParams -> ( Model, Cmd templateMsg )
init maybePageUrl sharedModel staticPayload =
    let
        tile =
            Tile.singleton "<p>Edit this! You can also paste Html here.</p>"

        model =
            { mosaic = Zipper.singleton tile
            , isEditing = False
            }
    in
    ( model, Cmd.none )


update : a -> b -> c -> d -> Msg -> Model -> ( Model, Cmd msg )
update pageUrl maybeBrowserNavigationKey sharedModel staticPayload msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TileMsg t ->
            ( { model | mosaic = Zipper.mapCurrent (Tile.update t) model.mosaic }, Cmd.none )

        Edit ->
            ( { model | isEditing = True }, Cmd.none )

        Ok ->
            ( { model | isEditing = False }, Cmd.none )


data : DataSource Data
data =
    DataSource.succeed ()


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Zine"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "Zine (Logo)"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Research on Hypertext Collage as an embodied queering practice"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    ()


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel { isEditing, mosaic } static =
    let
        viewFocused =
            if isEditing then
                Tile.view (Tile.Editor { onBlur = NoOp, howToMessage = TileMsg })

            else
                Tile.view (Tile.Selected { onDeselect = NoOp })

        viewNormal =
            Tile.view (Tile.Normal { onSelect = Focus })
    in
    mosaic
        |> zipper_mapDifferently { focus = viewFocused, periphery = viewNormal }
        |> Zipper.map Gui.nest_expanded
        |> zipper_toCons
        |> (\( t, ts ) -> Gui.collect t ts)
        |> (\html -> { title = "Zine", body = [ Gui.view (Gui.Current NoOp) html ] })


zipper_toCons : Zipper a -> ( a, List a )
zipper_toCons z =
    case Zipper.toList z of
        x :: xs ->
            ( x, xs )

        [] ->
            ( Zipper.current z, [] )



-- Helper for the mapping of zippers


type Focable a
    = F a
    | Focused a
    | Peripheral a


zipper_mapDifferently : { focus : a -> b, periphery : a -> b } -> Zipper a -> Zipper b
zipper_mapDifferently { focus, periphery } =
    let
        makePeripheral =
            List.map
                (\x ->
                    case x of
                        F a ->
                            Peripheral a

                        other ->
                            other
                )

        makeFocal =
            \x ->
                case x of
                    F a ->
                        Current a

                    other ->
                        other
    in
    Zipper.map F
        >> Zipper.mapCurrent makeFocal
        >> Zipper.mapBefore makePeripheral
        >> Zipper.mapAfter makePeripheral
        >> Zipper.map
            (\f ->
                case f of
                    Current a ->
                        focus a

                    Peripheral a ->
                        periphery a

                    F a ->
                        focus a
            )



{-
   node "custom-editor"
       [ attribute "state" "editing"
       , attribute "release" "<p>Edit this! You can also paste Html here.</p>"
       , attribute "format" ""
       ]
       []
       |> W3.Html.toNode
       |> (\html -> { title = "Zine", body = [ html ] })

-}
