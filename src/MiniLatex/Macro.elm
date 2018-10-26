module MiniLatex.Macro exposing(..)

import MiniLatex.Parser exposing(LatexExpression(..))
import MiniLatex.LatexState exposing(emptyLatexState)
import MiniLatex.Render 
import Parser


expandMacro : LatexExpression -> LatexExpression -> LatexExpression
expandMacro  macro macroDef = 
  case expandMacro_  macro macroDef of 
    NewCommand _ _ latexList -> latexList
    _ -> LXString "error"
    

expandMacro_ :  LatexExpression -> LatexExpression -> LatexExpression
expandMacro_  macro macroDef =
    case macroDef of
        Comment str ->
            Comment str

        Macro name optArgs args ->
            Macro name optArgs (List.map (expandMacro_ macro) args)

        SMacro name optArgs args le ->
             SMacro name optArgs (List.map (expandMacro_ macro) args) (expandMacro_ macro le) 

        Item level latexExpr ->
            Item level (expandMacro_ macro latexExpr)

        InlineMath str ->
            InlineMath str

        DisplayMath str ->
            DisplayMath str

        Environment name args body ->
            Environment name args (expandMacro_ macro body)

        LatexList latexList ->
            LatexList (List.map (expandMacro_ macro) latexList)

        LXString str ->
            LXString (substitute macro str)

        NewCommand commandName numberOfArgs commandBody ->
          NewCommand commandName numberOfArgs (expandMacro_  macro commandBody)

        LXError error ->
            LXError error


substitute : LatexExpression -> String -> String 
substitute macro str = 
  substituteMany (nArgs macro) macro str 


substituteOne : Int -> LatexExpression -> String -> String 
substituteOne k macro str = 
  let 
    arg =  renderArg k macro
    hashK = "#" ++ String.fromInt k
  in
    String.replace hashK arg str

nArgs : LatexExpression -> Int 
nArgs latexExpression =  
  case latexExpression of 
    Macro name optArgs args -> List.length args 
    _ -> 0  

substituteMany : Int -> LatexExpression -> String -> String 
substituteMany k macro str = 
  if k == 0 then
    str 
  else 
    substituteMany (k - 1) macro (substituteOne k macro str)

renderArg : Int -> LatexExpression -> String
renderArg k macro = 
  case macro of 
    Macro name optArgs args ->
          MiniLatex.Render.renderArg (k-1) emptyLatexState args 
    _ -> ""

getStuff : LatexExpression -> LatexExpression
getStuff expr = 
  case expr of 
    NewCommand name nargs args ->
          args
    _ -> LXString "error" 