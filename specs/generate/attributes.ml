open Parse.Types
open Primitives
open Symbol_utils
open Complex

let format_attribute_type = function
  | AttributePrimitive String -> Some "string"
  | AttributePrimitive Double -> Some "float"
  | AttributePrimitive Integer -> Some "int"
  | AttributePrimitive Long -> Some "int64"
  | AttributeList (ComplexPrimitive String) -> Some "string list"
  | _ -> None

let resolve_token_create_fn = function
  | AttributePrimitive String -> Some "create_string_token"
  | AttributePrimitive Double -> Some "create_double_token"
  | AttributePrimitive Integer -> Some "create_int_token"
  | AttributePrimitive Long -> Some "create_int64_token"
  | AttributeList (ComplexPrimitive String) -> Some "create_string_list_token"
  | _ -> None

let write_resource_attributes_specification o resource_name
    (attributes : (string * attribute_type) list) =
  Fmt.pf o "type attributes@;=@,{@[<2>@;";
  Fmt.pf o "ref_: string;@;";
  attributes
  |> List.iter (fun (name, spec) ->
         let attr_name = name |> to_attribute_name in
         let type_name = format_attribute_type spec in
         match type_name with
         | Some type_name -> Fmt.pf o "%s: %s;@;" attr_name type_name
         | None -> ());
  Fmt.pf o "@;@]}@\n"

let write_resource_attributes_generator o type_ =
  Fmt.pf o "let create_attributes logical_id = {@[<2>@\n";
  Fmt.pf o
    "ref_ = Token_map.create_string_token@ (@,\
     Attributes.ref_resolver logical_id@,\
     );@;";
  type_.attributes
  |> List.iter (fun (name, type_) ->
         let token_create_fn = resolve_token_create_fn type_ in
         match token_create_fn with
         | Some token_create_fn ->
             Fmt.pf o
               "%s = Token_map.%s@,\
                (Attributes.attr_resolver logical_id \"%s\");@;"
               (name |> to_attribute_name)
               token_create_fn name
         | None -> ());
  Fmt.pf o "@]}@\n"
