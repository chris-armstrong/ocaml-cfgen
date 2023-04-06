open Parse.Types

let primitive_to_yojson primitive =
  match primitive with
  | String -> "yojson_of_string"
  | Integer -> "yojson_of_int"
  | Long -> "yojson_of_long"
  | Double -> "yojson_of_float"
  | Boolean -> "yojson_of_bool"
  | Timestamp -> "yojson_of_string"
  | Json -> "yojson_of_json"

let format_primitive_type = function
  | String -> "string"
  | Long -> "int64"
  | Integer -> "int"
  | Boolean -> "bool"
  | Timestamp -> "string"
  | Json -> "Yojson.Safe.t"
  | Double -> "float"