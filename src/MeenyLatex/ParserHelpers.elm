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
    
word_ : Parser String
word_ =
  getChompedString <|
    succeed ()
      |. chompWhile notSpecialCharacter

      
word : Parser String
word = 
  succeed identity 
    |. spaces 
    |= word_
    |. ws



    
specialWord_ : Parser String
specialWord_ =
  getChompedString <|
    succeed ()
      |. chompWhile notSpecialTableOrMacroCharacter


{-| Like `word`, but after a word is recognized spaces, not spaces + newlines are consumed
-}
specialWord : Parser String
specialWord =
    -- inContext "specialWord" <|
        succeed identity
            |. spaces
            |= specialWord_
            |. spaces


notSpecialTableOrMacroCharacter : Char -> Bool
notSpecialTableOrMacroCharacter c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$' || c == '}' || c == ']' || c == '&')


macroArgWord_ : Parser String
macroArgWord_ =
  getChompedString <|
    succeed ()
      |. chompWhile notMacroArgWordCharacter


macroArgWord : Parser String
macroArgWord =
   --  inContext "specialWord" <|
        succeed identity
            |. spaces
            |= macroArgWord_
            |. spaces


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

