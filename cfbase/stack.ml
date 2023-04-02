module StringMap = Map.Make (String)

module type StackResource = sig
  val type_ : string
  val yojson_of_properties : unit -> Yojson.Safe.t
end

module type StackResourceCreator = sig
  include StackResource

  type attributes

  (* val attributes : attributes *)
end

type parameter_string_constraints = {
  default_value: string option;
  min_length : int option;
  max_length : int option;
  allowed_values : string list option;
  allowed_pattern : string option;
}

type 'a parameter_number_constraints = {
  default_value: 'a option;
  min_value : 'a option;
  max_value : 'a option;
}

type stack_parameter_value =
  | ParameterString of  parameter_string_constraints
  | ParameterInteger of  int parameter_number_constraints
  | ParameterFloat of  float parameter_number_constraints

type stack_parameter = {
  value : stack_parameter_value;
  description : string option;
  no_echo : bool option;
}

type t = {
  parameters : stack_parameter StringMap.t ref;
  resources : (module StackResource) StringMap.t ref;
}

let make () =
  { resources = ref StringMap.empty; parameters = ref StringMap.empty }

(* type 'attributes logical_resource = { attributes : 'attributes } *)
type logical_resource = { type_ : string }

let add_resource (type a) stack logical_id
    (resource : (module StackResourceCreator with type attributes = a)) =
  let module Resource =
    (val resource : StackResourceCreator with type attributes = a)
  in
  let creator_ = (module Resource : StackResource) in
  stack.resources := StringMap.add logical_id creator_ !(stack.resources);
  { type_ = Resource.type_ }


let add_parameter stack name value ?description ?no_echo () =
  let parameter = { value; description ; no_echo } in
  stack.parameters := StringMap.add name parameter !(stack.parameters);
  ()

let add_string_parameter stack name ?description ?no_echo ?min_length ?max_length ?allowed_values ?allowed_pattern ?default_value () =
  let value = ParameterString {
    min_length;
    max_length;
    allowed_pattern;
    allowed_values;
    default_value;
  } in
  let parameter = { value; description ; no_echo } in
  stack.parameters := StringMap.add name parameter !(stack.parameters);
  ()

let yojson_of_stack_parameter resource: Yojson.Safe.t  =
  let open Util in
  let (type_, pairs) = (match resource.value with
    | ParameterString c -> ("String",
      let base = Util.prepend_option_map [] yojson_of_string c.default_value "DefaultValue" in
      let base = Util.prepend_option_map base yojson_of_int c.min_length "MinLength" in
      let base = Util.prepend_option_map base yojson_of_int c.max_length "MaxLength" in
      let base = Util.prepend_option_map base yojson_of_string c.allowed_pattern "AllowedPattern" in
      let base = Util.prepend_option_map base (yojson_of_list yojson_of_string) c.allowed_values "AllowedValues" in
      base)
    | ParameterInteger c -> ("Number",

      let base = Util.prepend_option_map [] yojson_of_int c.default_value "DefaultValue" in
      let base = Util.prepend_option_map base yojson_of_int c.min_value "MinValue" in
      let base = Util.prepend_option_map base yojson_of_int c.max_value "MaxValue" in
      base
    )
    | ParameterFloat c -> ("Number",

      let base = Util.prepend_option_map [] yojson_of_float c.default_value "DefaultValue" in
      let base = Util.prepend_option_map base yojson_of_float c.min_value "MinValue" in
      let base = Util.prepend_option_map base yojson_of_float c.max_value "MaxValue" in
      base
    )

  )
  in
  let base = ["Type", `String type_] in
  let base = Util.prepend_option_map base yojson_of_bool resource.no_echo "NoEcho" in
  let base = Util.prepend_option_map base yojson_of_string resource.description "Description" in
  `Assoc (List.concat [base; pairs])

let yojson_of_stack_parameters parameters : Yojson.Safe.t =
  let l = parameters |> (StringMap.to_seq ) |> Seq.fold_left (fun
  l (name, param) -> (name, yojson_of_stack_parameter param)::l) [] |> List.rev in
  `Assoc l

let yojson_of_stack_resource resource : Yojson.Safe.t =
  let module Resource = (val resource : StackResource) in
  let properties = Resource.yojson_of_properties () in
  `Assoc [
    ("Type", `String Resource.type_);
    ("Properties", properties)
  ]

let yojson_of_stack_resources (resources : (module StackResource) StringMap.t): Yojson.Safe.t =
  let l = resources |> StringMap.to_seq |> (Seq.fold_left (fun
  l (name, resource) -> (name, yojson_of_stack_resource resource)::l) []) |> List.rev in
  `Assoc l

let serialise stack : Yojson.Safe.t =
  `Assoc [("Parameters", yojson_of_stack_parameters !(stack.parameters));
  ("Resources", yojson_of_stack_resources !(stack.resources))]