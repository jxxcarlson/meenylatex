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
  let 
    arg1 =  renderArg 1 macro
  in
    String.replace "#1" arg1 str

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