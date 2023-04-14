let to_snake_case x =
  let parts = ref [] in
  let si = ref 0 in
  let i = ref 1 in
  let len = String.length x in
  while !i < len do
    let c = String.get x !i in
    let p = if !i - 1 >= 0  then Some (String.get x (!i - 1)) else None in
    let n = if !i + 1 < len  then Some (String.get x (!i + 1)) else None in
    (match p, c, n with
    | (Some 'A' ..'Z'), 'A' .. 'Z', Some ('A'..'Z') -> ()
    | _ , 'A' .. 'Z', Some _ ->
        parts := String.sub x !si (!i - !si) :: !parts;
        si := !i
    | _ -> ());
    i := !i + 1
  done;
  parts := String.sub x !si (len - !si) :: !parts;
  !parts |> List.rev
  |> List.map Containers.String.lowercase_ascii
  |> String.concat "_"

let%expect_test "to_snake_case 'ACM'" =
  Fmt.pr "%s" (to_snake_case "ACM");
  [%expect {|acm|}]

let%expect_test "to_snake_case 'AssumeRole'" =
  Fmt.pr "%s" (to_snake_case "AssumeRole");
  [%expect {|assume_role|}]

let%expect_test "to_snake_case 'AssumeRolePolicyDocument'" =
  Fmt.pr "%s" (to_snake_case "AssumeRolePolicyDocument");
  [%expect {|assume_role_policy_document|}]

let%expect_test "to_snake_case 'ECRImage'" =
  Fmt.pr "%s" (to_snake_case "ECRImage");
  [%expect {|ecr_image|}]

let%expect_test "to_snake_case 'ImageECR'" =
  Fmt.pr "%s" (to_snake_case "ImageECR");
  [%expect {|image_ecr|}]

let%expect_test "to_snake_case 'SystemSSMSystem'" =
  Fmt.pr "%s" (to_snake_case "SystemSSMSystem");
  [%expect {|system_ssm_system|}]

let to_safe_name str =
  match str with
  | "type" | "function" | "match" | "or" | "string" | "long" | "int" | "list"
  | "if" | "else" | "and" | "module" | "then" | "method" | "class" | "object"
  | "include" | "open" | "end" | "struct" | "to" | "begin" | "mutable"
  | "properties" | "attributes" ->
      str ^ "_"
  | _ -> str

let to_type_name name = to_snake_case name |> to_safe_name

let to_property_name x = x |> to_snake_case |> to_safe_name

let to_attribute_name x = x |> (Containers.String.replace ~which:`All ~sub:"." ~by:"_") |> to_snake_case |> to_safe_name

let to_attributes_type_name resource_name = (resource_name |> to_type_name) ^ "_attributes"