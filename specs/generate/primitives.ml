open Parse.Types

let primitive_to_yojson primitive =
  match primitive with
  | String -> "yojson_of_string"
  | Integer -> "yojson_of_int"
  | Long -> "yojson_of_long"
  | Double -> "yojson_of_float"
  | Boolean -> "yojson_of_bool"
  | Timestamp -> "yojson_of_string"
  | Json -> "yojson_of_string"

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