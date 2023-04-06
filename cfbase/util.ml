let yojson_of_string (x : string) : Yojson.Safe.t =
  let open Token_map in
  if Token_map.has_string_token x then
    let join_parts =
      x |> split_string_tokens
      |> List.map (function
           | Verbatim part -> `String part
           | Unresolved (module Resolve : Resolvable) -> Resolve.resolve ())
    in
      if (List.length join_parts) > 1  then `Assoc [ ("Fn::Join", `List join_parts) ]
      else List.hd join_parts
  else `String x

let yojson_of_int (x : int) =
  x |> Token_map.lookup_int_token
  |> Option.map (fun resolve ->
         let module Resolve = (val resolve : Token_map.Resolvable) in
         Resolve.resolve ())
  |> Option.value ~default:( `Int x)

let yojson_of_bool (x : bool) = `Bool x

let yojson_of_float (x : float) =
  x |> Token_map.lookup_double_token
  |> Option.map (fun resolve ->
         let module Resolve = (val resolve : Token_map.Resolvable) in
         Resolve.resolve ())
  |> Option.value ~default:(`Float x)

let yojson_of_long (x : Int64.t) : Yojson.Safe.t =
  x |> Token_map.lookup_long_token
  |> Option.map (fun resolve ->
         let module Resolve = (val resolve : Token_map.Resolvable) in
         Resolve.resolve ())
  |> Option.value ~default:( `Int (Int64.to_int x))

let yojson_of_list (conv : 'a -> Yojson.Safe.t) l = `List (List.map conv l)

let prepend_option_map (l : (string * Yojson.Safe.t) list) con v (n : string) =
  match v with Some v -> (n, con v) :: l | None -> l
