module StringMap : Map.S with type key = string

type parameter_string_constraints = {
  default_value : string option;
  min_length : int option;
  max_length : int option;
  allowed_values : string list option;
  allowed_pattern : string option;
}

type 'a parameter_number_constraints = {
  default_value : 'a option;
  min_value : 'a option;
  max_value : 'a option;
}

type stack_parameter_value =
  | ParameterString of parameter_string_constraints
  | ParameterInteger of int parameter_number_constraints
  | ParameterFloat of float parameter_number_constraints

type stack_parameter = {
  value : stack_parameter_value;
  description : string option;
  no_echo : bool option;
}

type 'attributes logical_resource = { cloudformation_type : string; attributes : 'attributes }
type t

val make : unit -> t

module type ResourceType = sig
  type properties
  type attributes
  val yojson_of_properties: properties -> Yojson.Safe.t
  val create_attributes: string -> attributes
  val cloudformation_type : string
end

val add_resource :
  t ->
  string ->
  (module ResourceType with type attributes = 'a and type properties = 'p) ->
  'p ->
  'a logical_resource

val add_parameter :
  t ->
  string ->
  stack_parameter_value ->
  ?description:string ->
  ?no_echo:bool ->
  unit ->
  unit

val add_string_parameter :
  t ->
  string ->
  ?description:string ->
  ?no_echo:bool ->
  ?min_length:int ->
  ?max_length:int ->
  ?allowed_values:string list ->
  ?allowed_pattern:string ->
  ?default_value:string ->
  unit ->
  unit

val serialise : t -> Yojson.Safe.t
