module Internal.Differ
    exposing
        ( EditRecord
        , emptyStringRecord
        , emptyHtmlMsgRecord
        , isEmpty
        , init
        , diff
        , simpleDifferentialRender
        , prefixer
        , update
        )

{-| This module is used to speed up parsing-rendering by
comparing the old and new lists of paragraphs, noting the changes,
then parsing and rendering the changed paragraphs.


# API

@docs EditRecord, emptyStringRecord, emptyHtmlMsgRecord, isEmpty, init, diff, prefixer, update, simpleDifferentialRender

-}

import Html exposing (Html)
import Internal.LatexState exposing (LatexState, emptyLatexState)
import Internal.Paragraph as Paragraph


{- TYPES -}


type alias DiffRecord =
    { commonInitialSegment : List String
    , commonTerminalSegment : List String
    , middleSegmentInSource : List String
    , middleSegmentInTarget : List String
    }


type alias IdListPacket =
    { idList : List String
    , newIdsStart : Maybe Int
    , newIdsEnd : Maybe Int
    }


{-| An EditRecord records a list of (logical) newParagraphs
correspoing to the text to be rendered as well as corresponding
list of rendered parapgraphs. We need to reveiw this strucure.
-}
type alias EditRecord a =
    { paragraphs : List String
    , renderedParagraphs : List a
    , latexState : LatexState
    , idList : List String
    , newIdsStart : Maybe Int
    , newIdsEnd : Maybe Int
    }


{-| An empty EditRecord -- like the integer 0 in another context.
-}
emptyStringRecord : EditRecord String
emptyStringRecord =
    EditRecord [] [] emptyLatexState [] Nothing Nothing


{-| An empty EditRecord -- like the integer 0 in another context. For
renderers with `Html a` as target.
-}
emptyHtmlMsgRecord : EditRecord (Html msg)
emptyHtmlMsgRecord =
    EditRecord [] [] emptyLatexState [] Nothing Nothing


{-| createRecord: Create an edit record by (1)
breaking the text in to pargraphs, (2) applying
the transformer to each string in the resulting
list of strings.
-}
init : (String -> a) -> String -> EditRecord a
init transformer text =
    let
        paragraphs =
            Paragraph.logicalParagraphify text

        n =
            List.length paragraphs

        idList =
            List.range 1 n |> List.map (prefixer 0)

        renderedParagraphs =
            List.map transformer paragraphs
    in
        EditRecord paragraphs renderedParagraphs emptyLatexState idList Nothing Nothing


{-| An EditRecord is considered to be empyt if its list of parapgraphs
and its list of rendered paraagrahs is empty
-}
isEmpty : EditRecord a -> Bool
isEmpty editRecord =
    editRecord.paragraphs == [] && editRecord.renderedParagraphs == []


{-| The update function takes an EditRecord and a string, the "text",
breaks the text into a list of logical paragraphs, diffs it with the list
of paragraphs held by the EditRecord, uses `differentialRender` to
render the changed paragraphs while copying the unchanged rendered paragraphsto
prodduce an updated list of rendered paragraphs. The 'differentialRender'
accomplishes this using the transformer. The seed is used to produces
a differential idList. This last step is perhaps unnecessary. To investigate.
(This was part of an optimization scheme.)
-}
update : Int -> (String -> a) -> EditRecord a -> String -> EditRecord a
update seed transformer editRecord text =
    let
        newParagraphs =
            Paragraph.logicalParagraphify text

        diffRecord =
            diff editRecord.paragraphs newParagraphs

        newRenderedParagraphs =
            differentialRender transformer diffRecord editRecord

        p =
            differentialIdList seed diffRecord editRecord
    in
        EditRecord newParagraphs newRenderedParagraphs editRecord.latexState p.idList p.newIdsStart p.newIdsEnd


{-| Update the renderedList by applying the transformer only to the
changed source elements.
-}
simpleDifferentialRender : (String -> a) -> DiffRecord -> List a -> List a
simpleDifferentialRender transformer diffRecord renderedList =
    let
        prefixLengh =
            List.length diffRecord.commonInitialSegment

        suffixLength =
            List.length diffRecord.commonTerminalSegment

        renderedPrefix =
            List.take prefixLengh renderedList

        renderedSuffix =
            takeLast suffixLength renderedList
    in
        renderedPrefix ++ (List.map transformer diffRecord.middleSegmentInTarget) ++ renderedSuffix


{-| Let u and v be two lists of strings. Write them as
u = axb, v = ayb, where a is the greatest common prefix
and b is the greatest common suffix. Return DiffRecord a b x y
-}
diff : List String -> List String -> DiffRecord
diff u v =
    let
        a =
            commonInitialSegment u v

        b_ =
            commonTerminalSegmentAux a u v

        la =
            List.length a

        lb =
            List.length b_

        x =
            u |> List.drop la |> dropLast lb

        y =
            v |> List.drop la |> dropLast lb

        b =
            if la == List.length u then
                []
            else
                b_
    in
        DiffRecord a b x y


commonInitialSegment : List String -> List String -> List String
commonInitialSegment x y =
    if x == [] then
        []
    else if y == [] then
        []
    else
        let
            a =
                List.take 1 x

            b =
                List.take 1 y
        in
            if a == b then
                a ++ commonInitialSegment (List.drop 1 x) (List.drop 1 y)
            else
                []



-- commonTerminalSegment1 : List String -> List String -> List String
-- commonTerminalSegment1 x y =
--     commonInitialSegment (List.reverse x) (List.reverse y) |> List.reverse


commonTerminalSegment : List String -> List String -> List String
commonTerminalSegment x y =
    let
        cis =
            commonInitialSegment x y
    in
        commonTerminalSegmentAux cis x y


commonTerminalSegmentAux : List String -> List String -> List String -> List String
commonTerminalSegmentAux cis x y =
    let
        n =
            List.length cis

        xx =
            List.drop n x |> List.reverse

        yy =
            List.drop n y |> List.reverse
    in
        commonInitialSegment xx yy |> List.reverse


dropLast : Int -> List a -> List a
dropLast k x =
    x |> List.reverse |> List.drop k |> List.reverse


takeLast : Int -> List a -> List a
takeLast k x =
    x |> List.reverse |> List.take k |> List.reverse


{-| The prefixer is used to generate unique id's "p.1", "p.2", etc.
for each paragraph.
-}
prefixer : Int -> Int -> String
prefixer b k =
    "p." ++ String.fromInt b ++ "." ++ String.fromInt k


{-| Given:

  - a seed : Int

  - a `renderer` which maps strings to strings

  - a `diffRecord`, which identifies the locaton of changed strings in a list of strings

  - an `editRecord`, which gives existing state as follows:
    -- paragraphs : List String
    -- renderedParagraphs : List String
    -- latexState : LatexState

    The renderer is applied to the source text of the paragraphs
    that have changed an updated renderedParagraphs list is returned
    as part of a diffPacket. That packet also contains information
    on paragrah ids. (This may be unnecessary).

Among other things, generate a fresh id list for the changed elements.

-}
differentialRender : (String -> a) -> DiffRecord -> EditRecord a -> List a
differentialRender renderer diffRecord editRecord =
    let
        ii =
            List.length diffRecord.commonInitialSegment

        it =
            List.length diffRecord.commonTerminalSegment

        initialSegmentRendered =
            List.take ii editRecord.renderedParagraphs

        terminalSegmentRendered =
            takeLast it editRecord.renderedParagraphs

        middleSegmentRendered =
            List.map renderer diffRecord.middleSegmentInTarget
    in
        initialSegmentRendered ++ middleSegmentRendered ++ terminalSegmentRendered


differentialIdList : Int -> DiffRecord -> EditRecord a -> IdListPacket
differentialIdList seed diffRecord editRecord =
    let
        ii =
            List.length diffRecord.commonInitialSegment

        it =
            List.length diffRecord.commonTerminalSegment

        ns =
            List.length diffRecord.middleSegmentInSource

        nt =
            List.length diffRecord.middleSegmentInTarget

        idListInitial =
            List.take ii editRecord.idList

        idListMiddle =
            List.range (ii + 1) (ii + nt) |> List.map (prefixer seed)

        idListTerminal =
            List.drop (ii + ns) editRecord.idList

        idList =
            idListInitial ++ idListMiddle ++ idListTerminal

        ( newIdsStart, newIdsEnd ) =
            if nt == 0 then
                ( Nothing, Nothing )
            else
                ( Just ii, Just (ii + nt - 1) )
    in
        { idList = idList
        , newIdsStart = newIdsStart
        , newIdsEnd = newIdsEnd
        }


freshIdList : Int -> EditRecord a -> IdListPacket
freshIdList seed editRecord =
    let
        newIdsStart =
            0

        newIdsEnd =
            (List.length editRecord.paragraphs) - 1

        idList =
            List.range newIdsStart newIdsEnd |> List.map (prefixer seed)
    in
        { idList = idList
        , newIdsStart = Just newIdsStart
        , newIdsEnd = Just newIdsEnd
        }
