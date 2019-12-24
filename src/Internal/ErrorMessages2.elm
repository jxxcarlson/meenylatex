module Internal.ErrorMessages2 exposing (renderError,renderErrors )

import Parser.Advanced exposing(DeadEnd)
import Internal.Parser exposing(Problem, Context)



type alias ErrorDatum = DeadEnd Context Problem

-- { col : Int, problem : Problem, row : Int }


renderError : DeadEnd Context Problem -> String
renderError errorDatum = "error"

renderErrors : List (DeadEnd Context Problem) -> String
renderErrors errorData =
    errorData
      |> List.map renderError
      |> String.join ", "
