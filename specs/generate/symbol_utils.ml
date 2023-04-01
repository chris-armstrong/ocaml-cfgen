let to_snake_case x =
  let parts = ref [] in
  let si = ref 0 in
  let i = ref 1 in
  let len = String.length x in
  while !i < len do
    let c = String.get x !i in
    (match c with
    | 'A' .. 'Z' ->
        parts := String.sub x !si (!i - !si) :: !parts;
        si := !i
    | _ -> ());
    i := !i + 1
  done;
  parts := String.sub x !si (len - !si) :: !parts;
  !parts |> List.rev
  |> List.map Containers.String.lowercase_ascii
  |> String.concat "_"

let to_safe_name str =
  match str with
  | "type" | "function" | "match" | "or" | "string" | "long" | "int" | "list"
  | "if" | "else" | "and" | "module" | "then" | "method" | "class" | "object"
  | "include" | "open" | "end" | "struct" | "to" | "begin" | "mutable" ->
      str ^ "_"
  | _ -> str

let to_type_name name = to_snake_case name |> to_safe_name