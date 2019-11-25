module AccumulatorTest exposing (suite)

-- http://package.elm-lang.org/packages/elm-community/elm-test/latest

import Data
import Dict exposing(Dict)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Internal.Accumulator as Accumulator
import Internal.Differ as Differ
import Internal.Paragraph as Paragraph
import Internal.LatexDiffer as LatexDiffer
import Internal.LatexState exposing (emptyLatexState)
import Internal.Parser as Parser exposing (LatexExpression(..))
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
                            { counters = Dict.fromList
                              [("eqno",21),("s1",1),("s2",12),("s3",0),("tno",0)]
                              , crossReferences = Dict.fromList [("debroglie","1.7"),("debroglie2","1.6")]
                              , dictionary = Dict.fromList [
                                 ("author","James  Carlson")
                                 ,("title","Notes  on  Quantum  Field  Theory")
                               ], macroDictionary = Dict.fromList []
                               , tableOfContents = [{ label = "1", level = 1, name = "Trajectories  and  Uncertainty" }
                               ,{ label = "1.1", level = 2, name = "Classical  mechanics" }
                               ,{ label = "1.2", level = 2, name = "Uncertainty  Principle" }
                               ,{ label = "1.3", level = 2, name = "Thought  experiment:  electron  in  a  small  box" }
                               ,{ label = "1.4", level = 2, name = "Quantum  Mechanics" }
                               ,{ label = "1.5", level = 2, name = "Huygen's  Principle" }
                               ,{ label = "1.6", level = 2, name = "Fermat's  principle" }
                               ,{ label = "1.7", level = 2, name = "Snell's  Law  of  Refraction" }
                               ,{ label = "1.8", level = 2, name = "Hero's  Law  of  Reflection" }
                               ,{ label = "1.9", level = 2, name = "Optical  Theories" }
                               ,{ label = "1.10", level = 2, name = "Creation  and  annihllation" }
                               ,{ label = "1.11", level = 2, name = "Relativistic  computations" }
                               ,{ label = "1.12", level = 2, name = "A  smaller  box" }] }


                in
                Expect.equal output expectedOutput
        ]