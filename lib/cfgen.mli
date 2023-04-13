(**
    cfgen provides definitions and helpers to construct AWS CloudFormation templates

    *)

(** Serialisation helpers*)
module Serialisers = Util
(** Template generation *)
module Template = Template
(** Token generation and mapping *)
module Token_map = Token_map
(** Resource attribute token helpers *)
module Attributes = Attributes
(** Helpers for AWS domain-specific/embedded languages*)
module Helpers : sig
  module Iam_policy = Iam_policy
  (** IAM Policy generation*)
end

(** BaseConstructs contains the generated definitions for CloudFormation resources
    from the {{:https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html}AWS CloudFormation Resource Specification} *)
module BaseConstructs : sig
(**
  {1 Organisation}

  {2 Hierarchy}

  The modules are organised into three tiers, corresponding to the three-level naming for CloudFormation resources:

  - Namespace
  - Service
  - Resource

  {i (which is the same as the [Namespace::Service::Resource] breakdown in CloudFormation)}

  - {b Namespace} is the top-level namespace for the resources ([AWS] or [Alexa] - most resources are in [AWS])
  - {b Service} is the AWS service that provides the resources, e.g. [IAM], [CloudWatch], [Lambda], [EC2], etc
  - {b Resource} is the specific resource type in that service, e.g. [Function], [EventSourceMapping], [Permission] (in [AWS::Lambda])

  {1 Resource Modules}

  In each resource module, you will find (in order):
  - {b Property Specifications} - record types corresponding to some of the {{!page-background.cloudformation_definitions}properties} of the resource
  - {b Resource Specification} - a record type describing the top-level {{!page-background.cloudformation_definitions}properties} of the resource
  - {b Attribute Specification} - a record type describing the {{!page-background.cloudformation_definitions}attributes} of a resource
  - {b Creation Functions} - helper functions, beginning with [make_*] to create the property and resource types
  - {b Serialisation Functions} - [yojson_of_*] functions used to serialise the resource properties to JSON

  {1 Usage}

  The {{!page-usage.howto}reference guide} provides more details on how to use these modules to
  construct CloudFormation resources in your stack.
*)

  (** AWS constructs *)
  module AWS = Cf_aws

  (** Alex constructs *)
  module Alexa = Cf_alexa
end

(** Intrinsic references generated at deployment time, like stack name or AWS Account ID/Region,
    made available as tokens. *)
module Intrinsics = Intrinsics