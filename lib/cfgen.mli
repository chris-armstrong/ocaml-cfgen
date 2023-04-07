(**
    cfgen provides definitions and helpers to construct AWS CloudFormation templates

    *)

(** String Map (including yojson serialiser)*)
module StringMap = Cf_base.StringMap
module Serialisers = Cf_base.Serialisers
module Template = Cf_base.Template
module Token_map = Cf_base.Token_map
module Attributes = Cf_base.Attributes
module Helpers = Cf_base.Helpers

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
module Alexa = Cf_alexa end
