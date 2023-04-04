module type Resolvable = sig
  val resolve : unit -> Yojson.Safe.t
end

let lookupTable = Hashtbl.create 100
let tokenCounter = ref Int32.one

let incrementTokenCounter () = tokenCounter := Int32.add !tokenCounter 1l

let magic = 0xFFBF000000000000L
let magic_sys_int = if Sys.int_size = 63 then 0x7FBF000000000000 else 0x7FBF0000
let max_token = 0x01000000l

let encode_double_token value =
  Int64.add magic (value |> Int64.of_int32) |> Int64.float_of_bits

let encode_long_token value = Int64.add magic (value |> Int64.of_int32)

let is_valid_token_int64 value =
  let as_token = Int64.sub value magic in
  (Int64.equal (Int64.logand magic value) magic) && (as_token > 0L) && (as_token < (Int64.of_int32 max_token))
let is_valid_token_sys_int value =
  let as_token = value - magic_sys_int in
  (Int.equal (Int.logand magic_sys_int value) magic_sys_int) && (as_token > 0) && (as_token < (Int32.to_int max_token))

let decode_double_token value =
  let as_bits = value |> Int64.bits_of_float in
  if is_valid_token_int64 as_bits then
    Int64.logxor magic as_bits |> Int64.to_int32 |> Option.some
  else
    None

let decode_long_token value =
  if is_valid_token_int64 value then
    Int64.logxor magic value |> Int64.to_int32 |> Option.some
  else
    None

let encode_int_token value =
  magic_sys_int land (Int32.to_int value)

let decode_int_token value =
  if is_valid_token_sys_int value then
    value lxor magic_sys_int |> Int32.of_int |> Option.some
  else
    None

let create_string_token ?(token_type="TOKEN") (resolvable: (module Resolvable)) =
  let tokenString = Format.asprintf "${Token[%s.%ld]}" token_type !tokenCounter in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter ();
  tokenString

let create_double_token (resolvable: (module Resolvable)) =
  let tokenFloat = encode_double_token !tokenCounter in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter ();
  tokenFloat

let create_long_token (resolvable: (module Resolvable)) =
  let tokenLong = encode_long_token !tokenCounter in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter();
  tokenLong

let create_string_list_token ?(token_type="TOKEN") (resolvable: (module Resolvable)) =
  let tokenString = Format.asprintf "${Token[%s.%ld]}" token_type !tokenCounter in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter();
  [tokenString]

let create_int_token (resolvable: (module Resolvable)) =
  let tokenInt = encode_int_token !tokenCounter in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter();
  tokenInt

exception InvalidToken of Int32.t

let lookup_token token =
  match token with
    | Some token -> (match Hashtbl.find_opt lookupTable token with
      | Some resolvable -> Some resolvable
      | None -> raise (InvalidToken token)
    )
    | None -> None

let lookup_string_token s =
  let token = Scanf.sscanf_opt s "${Token[%s.%ld]}" (fun _  token -> token) in
  lookup_token token

let lookup_double_token d =
  let token = decode_double_token d in
  lookup_token token

let lookup_long_token d =
  let token = decode_long_token d in lookup_token token

let lookup_int_token d =
  let token = decode_int_token d in lookup_token token