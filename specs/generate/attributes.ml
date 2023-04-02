open Parse.Types
open Primitives
open Symbol_utils
open Complex

let format_attribute_type = function
  | AttributeRecord r -> r |> to_type_name
  | AttributePrimitive p -> p |> format_primitive_type
  | AttributeList c -> Fmt.str "(%s list)" (format_complex_type c)
  | AttributeMap c -> Fmt.str "(%s StringMap.t)" (format_complex_type c)

let write_resource_attributes_specification o resource_name
    (attributes : (string * attribute_type) list) =
  let name = (resource_name |> to_attributes_type_name) in
  if List.length attributes > 0 then (
    Fmt.pf o "type %s@;=@,{@[<2>@;" name;
    attributes
    |> List.iter (fun (name, spec) ->
           let attr_name = name |> to_attribute_name in
           let type_name = format_attribute_type spec in
           Fmt.pf o "%s: %s;@;" attr_name type_name);
    Fmt.pf o "@;@]}@\n")
  else Fmt.pf o "@;type %s = unit@\n" name
