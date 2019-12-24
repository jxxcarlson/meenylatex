module MiniLatex.Edit exposing (init, get, Data,  update, emptyData, parse)

{-|

Data structures and functions for managing interactive edits.
The parse tree, rendered text, and other information needed
for this is stored in a value of type

```
MiniLatex.Edit.Data
```

That data is initialized using


```
data = init version text
```

where the version is an integer that distinguishes
different edits.

# API

@docs  Data, emptyData, init, update, get, parse


-}

import Html exposing (Html)
import Html.Attributes as HA
import Html.Keyed as Keyed
import Internal.Differ as Differ exposing (EditRecord)
import Internal.LatexDiffer as MiniLatexDiffer
import Internal.Paragraph as Paragraph
import Internal.Parser as MiniLatexParser exposing (LatexExpression)
import Internal.Render2 as Render


{-| Data for differential parsing and rendering -}
type alias Data a = EditRecord a

{-| Create Data from a string of MiniLaTeX text and a version number.
The version number should be different for each call of init.

-}
init : Int -> String -> Data (Html msg)
init version text =
    MiniLatexDiffer.update version Render.renderLatexList Render.renderString Differ.emptyHtmlMsgRecord text


{-| Update Data with modified text, re-parsing and re-rerendering changed elements.
-}
update : Int ->  String -> Data (Html msg) -> Data (Html msg)
update version text editRecord  =
    MiniLatexDiffer.update version Render.renderLatexList Render.renderString editRecord text



{-| Retrieve Html from a Data object.
-}
get : Data (Html msg) -> List (Html msg)
get editRecord =
    let
        paragraphs =
            editRecord.renderedParagraphs

        ids =
            editRecord.idList
    in
        List.map2 (\para id -> Keyed.node "p" [ HA.id id, HA.style "margin-bottom" "10px" ] [ ( id, para ) ]) paragraphs ids



{-| Used for initialization.


-}
emptyData : Data (Html msg)
emptyData =
    Differ.emptyHtmlMsgRecord

{-| Parse the given text and return an AST representing it.
-}
parse : String -> List (List LatexExpression)
parse text =
    text
        |> Paragraph.logicalParagraphify
        |> List.map MiniLatexParser.parse


