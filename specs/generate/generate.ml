open Parse.Types

let rec mkdirp ?(base = Sys.getcwd ()) segments =
  match segments with
  | [] -> ()
  | segment :: segments ->
      let path = Filename.concat base segment in
      (match Sys.file_exists path with
      | true -> ()
      | false -> Sys.mkdir path 0o755);
      mkdirp ~base:path segments

(* let generate_properties property_types =
   property_types |> List.map (fun (name, pt) -> "") |> String.concat "" *)

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
    (if not prop_type.required then "[@default None][@yojson_drop_default (=)]" else "");
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
    Fmt.pf o "[@@@@ deriving yojson_of]";
    Fmt.pf o "@\n"
    )
  else
    Fmt.pf o "@,(**@;see@;%s;*)@,%s %s = unit@\n" prop_spec.documentation
      (if first then "type" else "and")
      (to_type_name name);
  Format.pp_force_newline o ()

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
    Fmt.pf o "@]@,}@,";
    Fmt.pf o "[@@@@deriving yojson_of]"
  )
  else Fmt.pf o "@,(** see %s *)@,type t = unit@;" type_.documentation

let write_resource_constructor o _ (type_ : resource_specification) =
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
    Fmt.pf o "@,let make@;@[";
    List.iter (fun arg -> Fmt.pf o "%s@;" arg) args;
    Fmt.pf o "@]()@ =@ {@[@;";
    List.iter (fun record -> Fmt.pf o "%s;@;" record) record;
    Fmt.pf o "@]}@;@\n"

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
  Fmt.pf o "@]@,end@,@\n";
  Format.pp_print_newline o ()
