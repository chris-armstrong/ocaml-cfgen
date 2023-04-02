open Yojson.Safe
open Containers
open Specification

exception ParseError of string

module Types = Specification

let to_assoc_opt tree = tree |> (Util.to_option Util.to_assoc) |> (Option.value ~default:[])

let convert_primitive p =
  match p with
  | "String" -> String
  | "Long" -> Long
  | "Integer" -> Integer
  | "Double" -> Double
  | "Boolean" -> Boolean
  | "Timestamp" -> Timestamp
  | "Json" -> Json
  | type_ -> raise (ParseError ("Unknown PrimitiveType=" ^ type_))

let read_primitive tree =
  convert_primitive (tree |> Util.member "PrimitiveType" |> Util.to_string)

let read_complex_type tree =
  match tree |> Util.member "ItemType" |> Util.to_string_option with
  | Some x -> ComplexRecord x
  | None ->
      ComplexPrimitive
        (tree
        |> Util.member "PrimitiveItemType"
        |> Util.to_string |> convert_primitive)

let read_property_definition tree =
  let documentation = tree |> Util.member "Documentation" |> Util.to_string in
  let required = tree |> Util.member "Required" |> Util.to_bool in
  let update_type =
    tree |> Util.member "UpdateType" |> Util.to_string |> function
    | "Mutable" -> Mutable
    | "Immutable" -> Immutable
    | "Conditional" -> Conditional
    | x -> raise (ParseError ("Unknown UpdateType=" ^ x))
  in
  let property_type =
    match tree |> Util.member "Type" |> Util.to_string_option with
    | Some "List" -> PropertyList (read_complex_type tree)
    | Some "Map" -> PropertyMap (read_complex_type tree)
    | Some type_ -> PropertyRecord type_
    | None -> PropertyPrimitive (read_primitive tree)
  in
  { documentation; required; update_type; property_type }

let read_property_definitions tree =

    tree |> Util.member "Properties" |> to_assoc_opt
    |> List.map (fun (name, definition) ->
           (name, definition |> read_property_definition))
let read_property_specification tree =
  let documentation = tree |> Util.member "Documentation" |> Util.to_string in
  let properties = tree |> read_property_definitions
  in
  { documentation; properties }

let read_property_specifications tree = tree
  |> to_assoc_opt
  |> List.map (fun (name, spec) ->
         try
           let name_parts = name |> String.split_on_char '.' in
           let name =
             List.nth_opt name_parts 1 |> Containers.Option.value ~default:name
           in
           let property_spec = read_property_specification spec in
           (name, property_spec)
         with Yojson.Json_error x ->
           raise
             (ParseError
                (Printf.sprintf "Could not read property spec %s: %s" name x)))
let read_property_types tree =
  tree
  |> Util.member "PropertyTypes"
  |> read_property_specifications

let read_attribute_type tree =
  match tree |> Util.member "Type" |> Util.to_string_option with
    | Some "List" -> AttributeList (read_complex_type tree)
    | Some "Map" -> AttributeMap (read_complex_type tree)
    | Some x -> AttributeRecord x
    | None -> AttributePrimitive (read_primitive tree)

let read_attribute_specifications tree = tree
  |> to_assoc_opt
  |> List.map (fun (name, spec) ->
      let attr_type = spec |> read_attribute_type in
      (name, attr_type)
    )

let read_resource_type tree =
  tree
  |> Util.member "ResourceType"
  |> Util.to_assoc
  (* There should only be one member of ResourceType *)
  |> List.hd
  |> (fun (name, resource_spec) ->
      let attributes = resource_spec |> Util.member "Attributes" |> read_attribute_specifications in
      let documentation = resource_spec |> Util.member "Documentation" |> Util.to_string in
      let properties = resource_spec |> read_property_definitions in
      (name, { attributes; documentation; properties })
    )