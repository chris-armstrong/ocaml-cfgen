open Parse.Types
open Symbol_utils

let format_primitive_type = function
  | String -> "string"
  | Long -> "int"
  | Integer -> "int"
  | Boolean -> "bool"
  | Timestamp -> "string"
  | Json -> "string"
  | Double -> "float"

let format_complex_type = function
  | ComplexPrimitive x -> format_primitive_type x
  | ComplexRecord x -> to_type_name x

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
  Fmt.pf o "(* see %s *)@;%s:@,%s%s@ [@key \"%s\"]%s;@;" prop_type.documentation
    (name |> to_snake_case |> to_safe_name)
    (format_property_type prop_type.property_type)
    (if prop_type.required then "" else " option")
    name
    (if not prop_type.required then "[@default None][@yojson_drop_default (=)]"
     else "");
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

[@@@warning "-27"]

let to_property_name x = x |> to_snake_case |> to_safe_name

let primitive_to_yojson primitive =
  match primitive with
  | String -> "`String"
  | Integer | Long -> "`Int"
  | Double -> "`Float"
  | Boolean -> "`Bool"
  | Timestamp -> "`String"
  | Json -> "`String"

let primitive_to_yojson_func primitive =
  match primitive with
  | String | Timestamp | Json -> "yojson_of_string"
  | Integer | Long -> "yojson_of_int"
  | Double -> "yojson_of_float"
  | Boolean -> "yojson_of_bool"

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
      Fmt.pf o "%s %s" (primitive_to_yojson primitive) symbol
  | PropertyList (ComplexPrimitive x) ->
      Fmt.pf o "`List (List.map %s %s)" (primitive_to_yojson_func x) symbol
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

let write_record_to_yojson o name
    properties first =
  let type_name = name |> to_type_name in
  let record_name = if List.length properties > 0 then "v" else "_" in
  let rec_ = if first then "let rec" else "and" in
  Fmt.pf o "%s yojson_of_%s@ (%s@.:@,%s)@ =@,@\n@[<2>@;" rec_ type_name
    record_name type_name;
  let required_props, optional_props =
    properties |> List.partition (fun (_, p) -> p.required)
  in
  Fmt.pf o "@;let base =@ [@[<2>@,";
  required_props
  |> List.iter (fun (name, p) ->
         Fmt.pf o "(@ \"%s\"@ ,@ " name;
         write_property_to_yojson o ("v." ^ to_property_name name) p;
         Fmt.pf o "@ )@;;@;");
  Fmt.pf o "@;@]]@ in@\n";
  optional_props
  |> List.iter (fun (name, p) ->
         Fmt.pf o "let base = prepend_option_map base %s"
           (property_to_yojson_func p.property_type);
         Fmt.pf o " %s \"%s\" @;in@\n" ("v." ^ to_property_name name) name);
  Fmt.pf o "(`Assoc base)";
  Fmt.pf o "@]@;@\n"

let write_property_constructor o name (type_ : property_specification) =
  if List.length type_.properties > 0 then
    let args =
      type_.properties
      |> List.map (fun (name, { required; _ }) ->
             (if required then "~" else "?")
             ^ (name |> to_snake_case |> to_safe_name))
    in
    let record =
      type_.properties
      |> List.map (fun (name, _) -> name |> to_snake_case |> to_safe_name)
    in
    let property_name = name |> to_snake_case |> to_safe_name in
    Fmt.pf o "@\nlet make_%s %a () : %s = {@[<2>@;%a@;@]}@;" property_name
      (Fmt.list ~sep:(Fmt.sps 2) Fmt.string)
      args property_name
      (Fmt.list ~sep:Fmt.semi Fmt.string)
      record

let write_resource_specification o _ (type_ : resource_specification) =
  if List.length type_.properties > 0 then (
    Fmt.pf o "@;(**@;see@;%s;*)@,@[<2>type t = {@," type_.documentation;
    type_.properties
    |> List.iter (fun (name, prop_type) ->
           write_property_definition o name prop_type);
    Fmt.pf o "@]@,}@," (* Fmt.pf o "[@@@@deriving yojson_of]" *))
  else Fmt.pf o "@,(** see %s *)@,type t = unit@;" type_.documentation

let write_resource_constructor o _ (type_ : resource_specification) =
  if List.length type_.properties > 0 then (
    let args =
      type_.properties
      |> List.map (fun (name, { required; _ }) ->
             (if required then "~" else "?")
             ^ (name |> to_snake_case |> to_safe_name))
    in
    let record =
      type_.properties
      |> List.map (fun (name, _) -> name |> to_snake_case |> to_safe_name)
    in
    Fmt.pf o "@,let make@;@[";
    List.iter (fun arg -> Fmt.pf o "%s@;" arg) args;
    Fmt.pf o "@]()@ =@ {@[@;";
    List.iter (fun record -> Fmt.pf o "%s;@;" record) record;
    Fmt.pf o "@]}@;@\n")

let write_resource_interface o name (type_ : resource_specification)
    (property_types : property_specifications) =
  Fmt.pf o "@;(**@;see@;%s@;*)@;module %s = struct@;@[<2>@;" type_.documentation
    name;
  let sorted_property_types = property_types |> sort_by_deps name in
  sorted_property_types
  |> List.iteri (fun i (name, prop_spec) ->
         write_property_specification o name prop_spec (i = 0));
  write_resource_specification o name type_;
  Fmt.pf o "@\n";
  write_resource_constructor o name type_;
  sorted_property_types
  |> List.iter (fun (name, spec) -> write_property_constructor o name spec);
  sorted_property_types
  |> List.iteri (fun i (name, (spec: property_specification)) ->
         write_record_to_yojson o name spec.properties (i = 0));
  write_record_to_yojson o "t" type_.properties true;
  Fmt.pf o "@]@,end@,@\n";
  Format.pp_print_newline o ()
