module type Resolvable = sig
  val resolve : unit -> Yojson.Safe.t
end

let lookupTable = Hashtbl.create 100
let tokenCounter = ref Int32.one
let incrementTokenCounter () = tokenCounter := Int32.add !tokenCounter 1l
let magic = 0xFFBF000000000000L
let magic_sys_int = if Sys.int_size = 63 then (Int64.to_int 0x7FBF000000000000L) else 0x7FBF0000
let max_token = 0x01000000l

let encode_double_token value =
  Int64.add magic (value |> Int64.of_int32) |> Int64.float_of_bits

let encode_long_token value = Int64.add magic (value |> Int64.of_int32)

let is_valid_token_int64 value =
  let as_token = Int64.sub value magic in
  Int64.equal (Int64.logand magic value) magic
  && as_token > 0L
  && as_token < Int64.of_int32 max_token

let is_valid_token_sys_int value =
  let as_token = value - magic_sys_int in
  Int.equal (Int.logand magic_sys_int value) magic_sys_int
  && as_token > 0
  && as_token < Int32.to_int max_token

let decode_double_token value =
  let as_bits = value |> Int64.bits_of_float in
  if is_valid_token_int64 as_bits then
    Int64.logxor magic as_bits |> Int64.to_int32 |> Option.some
  else None

let decode_long_token value =
  if is_valid_token_int64 value then
    Int64.logxor magic value |> Int64.to_int32 |> Option.some
  else None

let encode_int_token value = magic_sys_int land Int32.to_int value

let decode_int_token value =
  if is_valid_token_sys_int value then
    value lxor magic_sys_int |> Int32.of_int |> Option.some
  else None

let create_string_token ?(token_type = "TOKEN")
    (resolvable : (module Resolvable)) =
  let tokenString =
    Format.asprintf "${Token[%s.%ld]}" token_type !tokenCounter
  in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter ();
  tokenString

let create_double_token (resolvable : (module Resolvable)) =
  let tokenFloat = encode_double_token !tokenCounter in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter ();
  tokenFloat

let create_long_token (resolvable : (module Resolvable)) =
  let tokenLong = encode_long_token !tokenCounter in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter ();
  tokenLong

let create_string_list_token ?(token_type = "TOKEN")
    (resolvable : (module Resolvable)) =
  let tokenString =
    Format.asprintf "${Token[%s.%ld]}" token_type !tokenCounter
  in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter ();
  [ tokenString ]

let create_int_token (resolvable : (module Resolvable)) =
  let tokenInt = encode_int_token !tokenCounter in
  Hashtbl.add lookupTable !tokenCounter resolvable;
  incrementTokenCounter ();
  tokenInt

exception InvalidToken of Int32.t

let lookup_token token =
  match token with
  | Some token -> (
      match Hashtbl.find_opt lookupTable token with
      | Some resolvable -> Some resolvable
      | None -> raise (InvalidToken token))
  | None -> None


let scan_token s = try Some (Scanf.sscanf s "${Token[%s@.%ld]}" (fun _ token -> token))
with | Scanf.Scan_failure _ -> None

let%expect_test "scan_token" =
  let value = scan_token "${Token[TOKEN.1234]}" |> Option.value ~default:0l in
  Format.printf "%ld" value;
  [%expect {|1234|}]

let lookup_string_token s = lookup_token (scan_token s)

let%expect_test "lookup_string_token" =
  let packed =
    (module struct
      let resolve () = `Assoc [ ("Ref", `String "MyLogicalId") ]
    end : Resolvable)
  in
  let value =
    packed |> create_string_token
    (* in Format.printf "%s" value; *)
    |> lookup_string_token
    |> Option.map (fun (resolvable : (module Resolvable)) ->
           let module Resolve = (val resolvable : Resolvable) in
           Resolve.resolve ())
  in
  Format.printf "%a" (Format.pp_print_option Yojson.Safe.pretty_print) value;
  [%expect {|{ "Ref": "MyLogicalId" }|}]

let lookup_double_token d =
  let token = decode_double_token d in
  lookup_token token

let lookup_long_token d =
  let token = decode_long_token d in
  lookup_token token

let lookup_int_token d =
  let token = decode_int_token d in
  lookup_token token

let token_regexp = Str.regexp {|\${Token\[\([^]]+\)\]}|}

let has_string_token x =
  try
    let _ = Str.search_forward token_regexp x 0 in
    true
  with Not_found -> false

let%expect_test "has_string_token no match" =
  Format.printf "%B" (has_string_token "");
  [%expect {|false|}]

let%expect_test "has_string_token Fn::Sub style token" =
  Format.printf "%B" (has_string_token "${AWS::AccountId}");
  [%expect {|false|}]

let%expect_test "has_string_token Fn::Sub style token embedded" =
  Format.printf "%B"
    (has_string_token
       "arn:aws:iam:${AWS::Region}:${AWS::AccountId}:role/TestRole");
  [%expect {|false|}]

let%expect_test "has_string_token nominal token" =
  Format.printf "%B" (has_string_token "${Token[TOKEN.333]}");
  [%expect {|true|}]

let%expect_test "has_string_token embedded token" =
  Format.printf "%B" (has_string_token "arn:aws:s3:::${Token[TOKEN.333]}/*");
  [%expect {|true|}]

let%expect_test "has_string_token multiple embedded token" =
  Format.printf "%B"
    (has_string_token
       "arn:aws:iam:${Token[TOKEN.444]}:12345:${Token[TOKEN.333]}/*");
  [%expect {|true|}]

type split_token = Verbatim of string | Unresolved of (module Resolvable)

let pp_split_token fmt = function
  | Verbatim x -> Format.fprintf fmt "Verbatim \"%s\"" x
  | Unresolved _ -> Format.fprintf fmt "Unresolved (module)"

let split_string_tokens x =
  let rec split ?(tokens = []) ?(pos = 0) () =
    try
      let next_pos = Str.search_forward token_regexp x pos in
      let str_part = String.sub x pos (next_pos - pos) in
      let token_string = Str.matched_group 0 x in
      let token_part =
        token_string |> lookup_string_token
        |> Option.map (fun x -> Unresolved x)
      in
      let str_part =
        (if String.length str_part > 0 then Some str_part else None)
        |> Option.map (fun x -> Verbatim x)
      in
      let new_tokens =
        [ token_part; str_part ] |> List.filter_map (fun x -> x)
      in
      split
        ~tokens:(List.concat [ new_tokens; tokens ])
        ~pos:(next_pos + String.length token_string)
        ()
    with Not_found ->
      let remaining = String.sub x pos (String.length x - pos) in
      if String.length remaining > 0 then Verbatim remaining :: tokens
      else tokens
  in
  split () |> List.rev

let%expect_test "split_string_tokens single no token" =
  Format.printf "%a"
    (Format.pp_print_list pp_split_token)
    (split_string_tokens "a string");
  [%expect {|Verbatim "a string"|}]

let%expect_test "split_string_tokens single token" =
  Format.printf "%a"
    (Format.pp_print_list pp_split_token)
    (split_string_tokens "${Token[TOKEN.1]}");
  [%expect {|Unresolved (module)|}]

let%expect_test "split_string_tokens embedded token" =
  let token1 = create_string_token (module struct let resolve () = `String "12345" end : Resolvable) in
  let token2 = create_string_token (module struct let resolve () = `String "TestRole" end : Resolvable) in
  let str = Format.asprintf  "arn:aws:iam:ap-southeast-2:%s:role/%s" token1 token2 in
  Format.printf "%a"
    (Format.pp_print_list ~pp_sep:Format.pp_print_space pp_split_token)
    (split_string_tokens str);
  [%expect {|
  Verbatim "arn:aws:iam:ap-southeast-2:" Unresolved (module) Verbatim ":role/"
  Unresolved (module)|}]
