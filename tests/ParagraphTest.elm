module ParagraphTest exposing (suite)

-- http://package.elm-lang.org/packages/elm-community/elm-test/latest

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import MiniLatex.Paragraph exposing (logicalParagraphify)
import Test exposing (..)


doTest comment inputExpression outputExpression =
    test comment <|
        \_ ->
            Expect.equal inputExpression outputExpression


example =
    """
To understand quantum mechanics, we need to understand why the classical theories of mechanics and optics cannot explain phenomena such as those listed above.  Despite the fact that they do not work in the quantum domain, they furnish a vocabulary of notions -- force, field, wave, conservation of momentum and energy, symmetry, and minimum principle -- from which one fashions a new language of wave packets and wave functions, operators and observables that form the core of quantum theory and quantum field theory.

We begin with the notion of trajectory in mechanics, then consider optical theories, beginning with Hero of Alexandria (c. AD 30), who explained the law of reflection via a minimum principle for light rays.  Much later came the formulation of Snell's law of refraction and Fermat's explanation of it via a principle of minimum time for rays.  The optical theories motivated physics to find a way of understanding minimum principles.  In 1788, Lagrange formulated his powerful Principle of Least Action. It appears again and again in the history of physics, including its key role in Richard Feynman's path integral approach to quantum field theory. 

There is a second branch of the optics storyline.  It begins with Huygens' wave theory of the propagation of light (1670) and gains momentum as it is able to explain not only reflection and refraction, but also phenomena such as interference and diffraction which the ray and corpuscular theories could not.
"""


suite : Test
suite =
    describe "paragraphify"
        [ doTest
            "normal paragraphs"
            (logicalParagraphify "abc\n\ndef")
            [ "abc\n\n", "def\n\n" ]
        , doTest
            "normal paragraphs, length test"
            (logicalParagraphify "abc\n\ndef" |> List.length)
            2
        , doTest
            "real example"
            (logicalParagraphify example |> List.length)
            3
        ]
