open Parse.Types
open Symbol_utils
open Property_specifications
open Attributes
let properties_type_name type_ = if (type_.properties  |> Containers.List.exists (fun (name, _) -> String.equal name "Properties"))
  then
    "properties_"
  else
    "properties"

let write_record_to_yojson o name properties first =
  let type_name = name |> to_type_name in
  let record_name = if List.length properties > 0 then "v" else "_" in
  let rec_ = if first then "let rec" else "and" in
  Fmt.pf o "%s yojson_of_%s@ (%s@,:@,%s)@ =@,@\n@[<2>@;" rec_ type_name
    record_name type_name;
  let required_props, optional_props =
    properties |> List.partition (fun (_, p) -> p.required)
  in
  Fmt.pf o "@;let base =@ [@[<2>@;";
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
         Fmt.pf o " %s \"%s\" @;in@;" ("v." ^ to_property_name name) name);
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

let write_resource_properties_specification o _ (type_ : resource_specification)
    =
  if List.length type_.properties > 0 then (
    Fmt.pf o "@;(**@;see@;%s;*)@,@[<2>type %s = {@,"  type_.documentation (properties_type_name type_);
    type_.properties
    |> List.iter (fun (name, prop_type) ->
           write_property_definition o name prop_type);
    Fmt.pf o "@]@,}@," (* Fmt.pf o "[@@@@deriving yojson_of]" *))
  else Fmt.pf o "@,(** see %s *)@,type %s = unit@;" type_.documentation (properties_type_name type_)

let write_resource_properties_constructor o _ (type_ : resource_specification) =
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
    Fmt.pf o "@,let make_%s@;@[<2>" (properties_type_name type_);
    List.iter (fun arg -> Fmt.pf o "%s@;" arg) args;
    Fmt.pf o "@]()@ =@ {@[<2>@;";
    List.iter (fun record -> Fmt.pf o "%s;@;" record) record;
    Fmt.pf o "@]}@;@\n")

let write_resource_constructor o fqn resource_name type_ =

  Fmt.pf o "let create (properties: %s) =@;@[<2>@;" (properties_type_name type_);
  Fmt.pf o "let module Resource = struct@;@[<2>@\n";
  Fmt.pf o "type attributes = %s@;" (resource_name |> to_attributes_type_name);
  Fmt.pf o "let type_ = \"%s\"@;" fqn;
  (* Fmt.pf o "let attributes = \"%s\"" fqn; *)
  Fmt.pf o "let yojson_of_properties () = yojson_of_%s properties@;" (properties_type_name type_);
  Fmt.pf o "@]@;end@;in@;";
  Fmt.pf o
    "let resource@;\
     =@;\
     (module Resource: Cf_base.Stack.StackResourceCreator with@;\
     type attributes = %s)@;\
     in@;"
    (resource_name |> to_attributes_type_name);
  Fmt.pf o "resource@;";
  Fmt.pf o "@]@\n"

let write_resource_interface o fqn name (type_ : resource_specification)
    (property_types : property_specifications) =
  Fmt.pf o "@;(**@;see@;%s@;*)@;module %s = struct@;@[<2>@;" type_.documentation
    name;
  let sorted_property_types = property_types |> sort_by_deps name in
  sorted_property_types
  |> List.iteri (fun i (name, prop_spec) ->
         write_property_specification o name prop_spec (i = 0));
  write_resource_properties_specification o name type_;
  Fmt.pf o "@\n";
  write_resource_properties_constructor o name type_;
  sorted_property_types
  |> List.iter (fun (name, spec) -> write_property_constructor o name spec);
  sorted_property_types
  |> List.iteri (fun i (name, (spec : property_specification)) ->
         write_record_to_yojson o name spec.properties (i = 0));
  write_record_to_yojson o (properties_type_name type_)  type_.properties true;
  write_resource_attributes_specification o name type_.attributes;
  write_resource_constructor o fqn name type_;
  Fmt.pf o "@]@,end@,@\n";
  Format.pp_print_newline o ()
