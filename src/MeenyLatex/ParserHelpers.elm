module MeenyLatex.ParserHelpers exposing (spaces, ws, parseUntil, 
  parseFromTo, itemList1, itemList, simpleItemList, simpleItemList1,
  word_ , word, specialWord, macroArgWord, transformWords)

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
        getChompedString <| chompUntil marker

parseFromTo : String -> String -> Parser String 
parseFromTo startString endString =
   succeed identity 
     |. symbol startString
     |. spaces
     |= parseUntil endString 
            

itemList1 : Parser a -> Parser () -> Parser (List a)
itemList1 itemParser separatorParser = 
    itemParser
      |> andThen (\x -> (itemList_ [x] itemParser separatorParser))

itemList:  Parser a -> Parser () -> Parser (List a)
itemList itemParser separatorParser = 
  itemList_ [] itemParser separatorParser

itemList_ : List a -> Parser a -> Parser () -> Parser (List a)
itemList_ initialList itemParser separatorParser = 
   Parser.loop initialList (itemListHelper itemParser separatorParser)
   
   
itemListHelper : Parser a -> Parser () -> List a -> Parser (Step (List a) (List a))
itemListHelper itemParser separatorParser revItems = 
  oneOf [  succeed (\item -> Loop (item :: revItems))
             |= itemParser
             |. separatorParser
         , succeed () 
             |> Parser.map (\_ -> Done (List.reverse revItems))
       ]
       
simpleItemList1 : Parser a -> Parser (List a)
simpleItemList1 itemParser = 
   itemParser 
     |> andThen (\x -> (simpleItemList_ [x] itemParser ))
   

simpleItemList :  Parser a -> Parser (List a)
simpleItemList  itemParser = 
  simpleItemList_ [] itemParser

simpleItemList_ : List a -> Parser a -> Parser (List a)
simpleItemList_ initialList itemParser = 
   Parser.loop initialList (simpleItemListHelper itemParser)

simpleItemListHelper : Parser a -> List a -> Parser (Step (List a) (List a))
simpleItemListHelper itemParser revItems = 
  oneOf [  succeed (\item -> Loop (item :: revItems))
             |= itemParser
         , succeed () 
             |> Parser.map (\_ -> Done (List.reverse revItems))
       ]             
    
   

word_ : (Char -> Bool) -> Parser String
word_ inWord =
  getChompedString <|
    succeed ()
      |. chompIf (\c -> Char.isAlphaNum c)
      |. chompWhile inWord


word : Parser String
word =
  getChompedString <|
    succeed ()
      |. chompIf (\c -> Char.isAlphaNum c)
      |. chompWhile notSpecialCharacter



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

