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
    to a [Yojson.Safe.t] object, which in turn
    can then be output as a JSON string with
    the [Yojson.Safe.pretty_to_string] function.
    *)

type parameter_string_constraints = {
  default_value : string option;
  min_length : int option;
  max_length : int option;  (** The set of allowed values for this parameter *)
  allowed_values : string list option;
  allowed_pattern : string option;
}
(**
  * The constraints on a string parameter
  *)

type 'a parameter_number_constraints = {
  default_value : 'a option;
  min_value : 'a option;
  max_value : 'a option;
}
(**
  * The constraints on a number (int or float) parameter *)

(**
  * The constraints on a stack parameter *)
type parameter_constraints =
  | ParameterString of parameter_string_constraints
  | ParameterInteger of int parameter_number_constraints
  | ParameterFloat of float parameter_number_constraints

type 'attributes logical_resource = {
  cloudformation_type : string;
      (** The CloudFormation type e.g. [AWS::Lambda::Function] *)
  attributes : 'attributes;
      (** The resource attributes. These are
      set to token values which can be
      freely assigned to other resource
      properties or outputs. At stack
      serialisation, they will be replaced
      by cross-resource references (such
      as [Ref] or [Fn::GetAtt]) *)
}
(**
  * The description of a logical resource*)

type parameter = {
  ref_ : string;
      (** A token that resolves to a parameter's value at deployment time. Equivalent of [Ref: "ParameterName"]*)
}
(**
  A reference to a created parameter *)

type t
(** A template type - create with {!val:make} *)

val make : unit -> t
(** Create a new template representation *)

(**
  The module interface for a stack resource

  Modules used to create resources with {!val:add_resource}
  must conform to this signature.
*)
module type ResourceType = sig
  type properties
  (** The resource properties type *)

  type attributes
  (** The resource attributes type (can be [unit]) *)

  val yojson_of_properties : properties -> Yojson.Safe.t
  (** Serialise the properties as a [Yojson.Safe.t] type *)

  val create_attributes : string -> attributes
  (** Create the attributes for a template resource given the specified [logical_id] *)

  val cloudformation_type : string
  (** The CloudFormation [Type] field for this resource type e.g. [AWS::Logs::LogGroup] *)
end

val add_resource :
  t ->
  string ->
  (module ResourceType with type attributes = 'a and type properties = 'p) ->
  'p ->
  t * 'a logical_resource
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

val add_parameter :
  t ->
  string ->
  parameter_constraints ->
  ?description:string ->
  ?no_echo:bool ->
  unit ->
  t * parameter
(**
  Add a new parameter to the template

  Parameters are used to customise the stack
  when the template is deployed. The returned [ref_]
  is one of the serialised {!page-background.tokens}, which can be
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
  t * parameter
(**
  Add a new string parameter to the template.

  Parameters are used to customise the stack
  when the template is deployed. The returned [ref_]
  is one of the serialised {!page-background.tokens}, which can be
  referenced in resource properties or outputs.

  {[
    add_string_parameter
      template
      parameter_name
      ?description
      ?no_echo
      ?min_length
      ?max_length
      ?allowed_values
      ?allowed_pattern
      ?default_value
      ()
  ]}

  - [template] is the {!type:t} instance of the template
  - [parameter_name] is a string uniquely identifying the parameter in the context of the template
  - [?description] optionally provides a parameter description
  - [?no_echo] optionally suppresses the parameter value from being shown in the AWS Console
    (not to be used for secrets, as they can still be recovered if exposed as outputs or resource
      properties)
  - [?min_length] minimum parameter value length
  - [?max_length] minimum parameter value length
  - [?allowed_values] constrain the allowed values to the specified list
  - [?allowed_pattern] constrain the allowed values to the pattern (see {{:https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-regexes.html}AWS documentation} on regexes in CloudFormation)
  - [?default_value] is the default value used if the parameter is not specified when first deploying the template
  *)

val add_output :
  t ->
  string ->
  string ->
  ?export:string ->
  ?description:string ->
  unit ->
  t * unit
(**
    Add an output to the stack.

    Stack outputs can be used to make attributes of
    resources available to parent stacks or exported
    for use in other stacks in the same account/region.

    {[
      add_ouput template output_name ?export ?description ()
    ]}

    - [template] is the template to add to
    - [output_name] is a unique identifier for the output in the context of the template
    - [export] is an optional name that makes the parameter available to other stacks via [Fn::ImportValue].
      {b It must be globally unique among all stacks in the same account and region}, so it is recommended you
      substitute another value (like the environment or stack name) into the export value so the stack
      can be deployed multiple times.
    - [description] is an optional description for the output
  *)

val serialise : t -> Yojson.Safe.t
(**
    Serialise the template to Yojson structure for JSON serialisation
  *)
