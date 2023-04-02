let yojson_of_string (x: string) = `String x
let yojson_of_int (x: int) = `Int x
let yojson_of_bool (x: bool) = `Bool x
let yojson_of_float (x: float) = `Float x

let yojson_of_list (conv: 'a -> Yojson.Safe.t) l = `List (List.map conv l)

let prepend_option_map (l: (string * Yojson.Safe.t) list) con v (n: string) = match v with
  | Some v -> (n, con v) :: l
  | None -> l