module MeenyLatex.Image exposing (..)

import MeenyLatex.Html as Html
import MeenyLatex.KeyValueUtilities as KeyValueUtilities


{- IMAGE HELPERS -}


imageCenterStyle imageAttr =
    "class=\"center\" style=\"width: " ++ String.fromInt (imageAttr.width + 20) ++ "px; margin-left:auto, margin-right:auto; text-align: center;\""


imageFloatRightStyle imageAttr =
    "style=\"float: right; width: " ++ String.fromInt (imageAttr.width + 20) ++ "px; margin: 0 0 7.5px 10px; text-align: center;\""


imageFloatLeftStyle imageAttr =
    "style=\"float: left; width: " ++ String.fromInt (imageAttr.width + 20) ++ "px; margin: 0 10px 7.5px 0; text-align: center;\""


handleCenterImage url label imageAttr =
    let
        width =
            imageAttr.width
    in
        Html.div [ imageCenterStyle imageAttr ] [ Html.img url imageAttr, "<br>", label ]


floatImageRightDivLeftPart width =
    "<div style=\"float: right; width: " ++ String.fromInt (width + 20) ++ "px; margin: 0 0 7.5px 10px; text-align: center;\">"


handleFloatedImageRight url label imageAttr =
    let
        width =
            imageAttr.width
    in
        floatImageRightDivLeftPart width ++ "<img src=\"" ++ url ++ "\" width=" ++ String.fromInt width ++ "><br>" ++ label ++ "</div>"


floatImageLeftDivLeftPart width =
    "<div style=\"float: left; width: " ++ String.fromInt (width + 20) ++ "px; margin: 0 10px 7.5px 0; text-align: center;\">"


handleFloatedImageLeft url label imageAttr =
    let
        width =
            imageAttr.width
    in
        floatImageLeftDivLeftPart width ++ "<img src=\"" ++ url ++ "\" width=" ++ String.fromInt width ++ "><br>" ++ label ++ "</div>"


type alias ImageAttributes =
    { width : Int, float : String, align : String }


parseImageAttributes : String -> ImageAttributes
parseImageAttributes attributeString =
    let
        kvList =
            KeyValueUtilities.getKeyValueList attributeString

        widthValue =
            KeyValueUtilities.getValue "width" kvList |> String.toInt |> Maybe.withDefault 200

        floatValue =
            KeyValueUtilities.getValue "float" kvList

        alignValue =
            KeyValueUtilities.getValue "align" kvList
    in
        ImageAttributes widthValue floatValue alignValue


imageAttributes : ImageAttributes -> String -> String
imageAttributes imageAttrs attributeString =
    let
        widthValue =
            imageAttrs.width |> String.fromInt

        widthElement =
            if widthValue /= "" then
                "width=" ++ widthValue
            else
                ""
    in
        widthElement
