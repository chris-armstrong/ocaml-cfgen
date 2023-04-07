(**
    Template module for creating CloudFormation templates
    by adding resources, parameters and outputs

    Create a new template with {!val:make}.

    Use {!val:add_resource} in conjuction with a
    construct module in [Cfgen.BaseConstructs] to create
    a logical resource.

    {!val:add_parameter} adds a new parameter,
    and {!val:add_output} creates an output.

    Once you have finished adding resources, parameters
    and outputs to your template, you can serialise it
    to a [Yojson.Safe.t] object, which
    can then be output as JSON with the [Yojson.Safe.pretty_to_string]
    *)

(**
  * The constraints on a string parameter
  *)
type parameter_string_constraints = {
  default_value : string option;
  min_length : int option;
  max_length : int option;
  (** The set of allowed values for this parameter *)
  allowed_values : string list option;
  allowed_pattern : string option;
}

(**
  * The constraints on a number (int or float) parameter *)
type 'a parameter_number_constraints = {
  default_value : 'a option;
  min_value : 'a option;
  max_value : 'a option;
}

(**
  * The constraints on a stack parameter *)
type parameter_constraints =
  | ParameterString of parameter_string_constraints
  | ParameterInteger of int parameter_number_constraints
  | ParameterFloat of float parameter_number_constraints

(**
  * The description of a logical resource*)
type 'attributes logical_resource = {
  (** The CloudFormation type e.g. [AWS::Lambda::Function] *)
  cloudformation_type : string;
  (** The resource attributes. These are
      set to token values which can be
      freely assigned to other resource
      properties or outputs. At stack
      serialisation, they will be replaced
      by cross-resource references (such
      as [Ref] or [Fn::GetAtt]) *)
  attributes : 'attributes;
}

(** A template type - create with {!val:make} *)
type t

(** Create a new template representation *)
val make : unit -> t

(**
  The module interface for a stack resource

  Modules used to create resources with {!val:add_resource}
  must conform to this signature.
*)
module type ResourceType = sig
  (** The resource properties type *)
  type properties
  (** The resource attributes type (can be [unit]) *)
  type attributes

  (** Serialise the properties as a [Yojson.Safe.t] type *)
  val yojson_of_properties : properties -> Yojson.Safe.t
  (** Create the attributes for a template resource given the specified [logical_id] *)
  val create_attributes : string -> attributes
  (** The CloudFormation [Type] field for this resource type e.g. [AWS::Logs::LogGroup] *)
  val cloudformation_type : string
end


(**
  Add a new resource to the template

  {[
    add_resource template logical_id (module Resource) properties
  ]}

  - [template] is the {!type:t} instance of the template
  - [logical_id] is a string uniquely identifying the resource in the context of the template
  - [(module Resource)] is the resource module e.g. [(module AWS.IAM.Role)]
  - [properties] is the resource properties object
  *)
val add_resource :
  t ->
  string ->
  (module ResourceType with type attributes = 'a and type properties = 'p) ->
  'p ->
  'a logical_resource

(**
  Add a new parameter to the template

  Parameters are used to customise the stack
  when the template is deployed. They may be
  referenced in resource properties or outputs.

  {[
    add_parameter template parameter_name constraints ?description ?no_echo ()
  ]}

  - [template] is the {!type:t} instance of the template
  - [parameter_name] is a string uniquely identifying the parameter in the context of the template
  - [parameter_constraints] is the constraints of the property (which also specifies its type)
  - [?description] optionally provides a parameter description
  - [?no_echo] optionally suppresses the parameter value from being shown in the AWS Console
    (not to be used for secrets, as they can still be recovered if exposed as outputs or resource
      properties)
  *)
val add_parameter :
  t ->
  string ->
  parameter_constraints ->
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

val add_output :
  t -> string -> string -> ?export:string -> ?description:string -> unit -> unit

(**
    Serialise the template to Yojson structure
  *)
val serialise : t -> Yojson.Safe.t
