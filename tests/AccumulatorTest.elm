module AccumulatorTest exposing (suite)

-- http://package.elm-lang.org/packages/elm-community/elm-test/latest

import Data
import Dict exposing(Dict)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import MiniLatex.Accumulator as Accumulator
import MiniLatex.Differ as Differ
import MiniLatex.Paragraph as Paragraph
import MiniLatex.LatexDiffer as LatexDiffer
import MiniLatex.LatexState exposing (emptyLatexState)
import MiniLatex.Parser as Parser exposing (LatexExpression(..))
import MiniLatex.Render as Render
import Test exposing (..)


doTest comment inputExpression outputExpression =
    test comment <|
        \_ ->
            Expect.equal inputExpression outputExpression


suite : Test
suite =
    describe "Accumulator"
        [ doTest 
           "(1) length of input"    
            (Data.qftIntroText |> String.length) 
            19321
        , test "(2) parse into a list of Latex elements" <|
            \_ ->
                let
                    parseData1 =
                        Data.qftIntroText
                            |> Paragraph.logicalParagraphify
                            |> List.map Parser.parse
                in
                Expect.equal (List.length parseData1) 27
        , test "(3) parse and render paragraphs, verify final LatexState" <|
            \_ ->
                let
                    output =
                        Data.qftIntroText
                            |> Paragraph.logicalParagraphify
                            |> Accumulator.parse emptyLatexState
                            |> Tuple.first


                    expectedOutput =
                        { counters = Dict.fromList [("eqno",4),("s1",1),("s2",3),("s3",0),("tno",0)]
                        , crossReferences = Dict.fromList []
                        , dictionary = Dict.fromList [("author","James  Carlson"),("date","March  2017"),("title","Notes  on  Quantum  Field  Theory")]
                        , macroDictionary = Dict.fromList []
                        , tableOfContents = [
                            { label = "1", level = 1, name = "Trajectories  and  Uncertainty" }
                            ,{ label = "1.1", level = 2, name = "Classical  mechanics" }
                            ,{ label = "1.2", level = 2, name = "Uncertainty  Principle" }
                            ,{ label = "1.3", level = 2, name = "Thought  experiment:  electron  in  a  small  box" }
                        ] }
                in
                Expect.equal output expectedOutput
        ]