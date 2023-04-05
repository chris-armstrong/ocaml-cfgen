open Parse.Types
open Primitives
open Symbol_utils
open Complex

let format_property_type = function
  | PropertyPrimitive x -> format_primitive_type x
  | PropertyList x -> Fmt.str "%s list" (format_complex_type x)
  | PropertyRecord x -> to_type_name x
  | PropertyMap x -> Fmt.str "%s StringMap.t" (format_complex_type x)

exception CircularDependencyError of string

type property_specification_with_deps =
  string * property_specification * string list
[@@deriving show]

let sort_by_deps _ prop_specs =
  let open Containers in
  let prop_specs_with_deps =
    prop_specs
    |> List.map (fun (name, (prop_spec : property_specification)) ->
           ( name,
             prop_spec,
             prop_spec.properties
             |> List.filter_map (fun (_, p) ->
                    match p.property_type with
                    | PropertyRecord n -> Some n
                    | PropertyList (ComplexRecord n) -> Some n
                    | PropertyMap (ComplexRecord n) -> Some n
                    | _ -> None) ))
  in
  let sorted_deps : (string * property_specification * string list) list ref =
    ref []
  in
  let remaining_deps = ref prop_specs_with_deps in
  while List.length !remaining_deps > 0 do
    let free, stuck =
      !remaining_deps
      |> List.partition (fun (record_type, _, deps) ->
             deps
             |> List.for_all (fun dep ->
                    !sorted_deps
                    |> List.exists (fun (n, _, _) ->
                           String.equal n dep || String.equal dep record_type)))
    in
    if List.length free = 0 then (
      (* give up trying to order them at this point *)
      sorted_deps := List.concat [ !remaining_deps; !sorted_deps ];
      remaining_deps := [])
    else (
      sorted_deps := List.concat [ free; !sorted_deps ];
      remaining_deps := stuck)
  done;
  !sorted_deps |> List.rev |> List.map (fun (name, spec, _) -> (name, spec))

let write_property_definition o name (prop_type : property_definition) =
  Fmt.pf o "(* see %s *)@;%s:@;%s%s;@;@;" prop_type.documentation
    (name |> to_snake_case |> to_safe_name)
    (format_property_type prop_type.property_type)
    (if prop_type.required then "" else " option")
    ;
  Format.pp_force_newline o ()

let write_property_specification o name (prop_spec : property_specification)
    first =
  if List.length prop_spec.properties > 0 then (
    Fmt.pf o "@,(**@;see@;%s@;*)@,@[<2>%s %s = {@," prop_spec.documentation
      (if first then "type" else "and")
      (to_type_name name);
    prop_spec.properties
    |> List.iter (fun (name, prop_type) ->
           write_property_definition o name prop_type);
    Fmt.pf o "@]}@,";
    (* Fmt.pf o "[@@@@ deriving yojson_of]"; *)
    Fmt.pf o "@\n")
  else
    Fmt.pf o "@,(**@;see@;%s;*)@,%s %s = unit@\n" prop_spec.documentation
      (if first then "type" else "and")
      (to_type_name name);
  Format.pp_force_newline o ()

let property_to_yojson_func = function
  | PropertyPrimitive x -> primitive_to_yojson_func x
  | PropertyRecord x -> Fmt.str "yojson_of_%s" (x |> to_type_name)
  | PropertyList (ComplexPrimitive x) ->
      Fmt.str "(yojson_of_list %s)" (primitive_to_yojson_func x)
  | PropertyList (ComplexRecord x) ->
      Fmt.str "(yojson_of_list yojson_of_%s)" (x |> to_type_name)
  | PropertyMap (ComplexPrimitive x) ->
      Fmt.str "(StringMap.yojson_of_t %s)" (primitive_to_yojson_func x)
  | PropertyMap (ComplexRecord x) ->
      Fmt.str "(StringMap.yojson_of_t yojson_of_%s)" (x |> to_type_name)

let write_property_to_yojson o symbol { property_type; _ } =
  match property_type with
  | PropertyPrimitive primitive ->
      Fmt.pf o "(%s %s)" (primitive_to_yojson primitive) symbol
  | PropertyList (ComplexPrimitive x) ->
      Fmt.pf o "((yojson_of_list %s) %s)" (primitive_to_yojson_func x) symbol
  | PropertyMap (ComplexPrimitive x) ->
      Fmt.pf o "(StringMap.yojson_of_t %s %s)"
        (primitive_to_yojson_func x)
        symbol
  | PropertyRecord name ->
      Fmt.pf o "yojson_of_%s %s" (name |> to_type_name) symbol
  | PropertyList (ComplexRecord x) ->
      Fmt.pf o "`List (List.map yojson_of_%s %s)" (x |> to_type_name) symbol
  | PropertyMap (ComplexRecord x) ->
      Fmt.pf o "(StringMap.yojson_of_t yojson_of_%s %s)" (x |> to_type_name) symbol

let is_prop_type_record_of_name name { property_type ; _} = match property_type with
    | PropertyRecord x
    | PropertyList (ComplexRecord x)
    | PropertyMap (ComplexRecord x)
-> String.equal x name
| _ -> false

