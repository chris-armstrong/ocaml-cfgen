open Parse.Types

let primitive_to_yojson primitive =
  match primitive with
  | String -> "`String"
  | Integer | Long -> "`Int"
  | Double -> "`Float"
  | Boolean -> "`Bool"
  | Timestamp -> "`String"
  | Json -> "`String"

let primitive_to_yojson_func primitive =
  match primitive with
  | String | Timestamp | Json -> "yojson_of_string"
  | Integer | Long -> "yojson_of_int"
  | Double -> "yojson_of_float"
  | Boolean -> "yojson_of_bool"

let format_primitive_type = function
  | String -> "string"
  | Long -> "int"
  | Integer -> "int"
  | Boolean -> "bool"
  | Timestamp -> "string"
  | Json -> "string"
  | Double -> "float"