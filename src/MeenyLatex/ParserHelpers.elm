module MeenyLatex.ParserHelpers exposing (..)

import Parser exposing (..)


{- PARSER HELPERS

   These have varaous types, e.g.,

     - Parser ()
     - String -> Parser String
     - Parser a -> Parser a
     - Parser a -> Parser ()

-}


spaces : Parser ()
spaces =
    chompWhile (\c -> c == ' ')


ws : Parser ()
ws =
    chompWhile (\c -> c == ' ' || c == '\n')


parseUntil : String -> Parser String
parseUntil marker =
    -- inContext "parseUntil" <|
        getChompedString <| chompUntil marker
    
word : Parser String
word =
  getChompedString <|
    succeed ()
      |. chompIf (\c -> Char.isAlphaNum c)
      |. chompWhile notSpecialCharacter


s

{-| Like `word`, but after a word is recognized spaces, not spaces + newlines are consumed
-}
specialWord : Parser String
specialWord =
  getChompedString <|
    succeed ()
      |. chompIf (\c -> Char.isAlphaNum c)
      |. chompWhile notSpecialTableOrMacroCharacter




notSpecialTableOrMacroCharacter : Char -> Bool
notSpecialTableOrMacroCharacter c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$' || c == '}' || c == ']' || c == '&')


macroArgWord : Parser String
macroArgWord =
  getChompedString <|
    succeed ()
      |. chompIf (\c -> Char.isAlphaNum c)
      |. chompWhile notMacroArgWordCharacter



notMacroArgWordCharacter : Char -> Bool
notMacroArgWordCharacter c =
    not (c == '}' || c == ' ' || c == '\n')



notSpecialCharacter : Char -> Bool
notSpecialCharacter c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$')


notMacroSpecialCharacter : Char -> Bool
notMacroSpecialCharacter c =
    not (c == '{' || c == '[' || c == ' ' || c == '\n')


{-| Transform special words
-}
transformWords : String -> String
transformWords str =
    if str == "--" then
        "\\ndash"
    else if str == "---" then
        "\\mdash"
    else
        str

