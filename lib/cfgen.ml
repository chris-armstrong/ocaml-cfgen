(** Base (L1) constructs for adding resources to stacks *)
module BaseConstructs = struct
  module AWS = Cf_aws
  module Alexa = Cf_alexa
end


(** Serialisation helpers*)
module Serialisers = Util
(** Template generation *)
module Template = Template
(** Token generation and mapping *)
module Token_map = Token_map
(** Resource attribute token helpers *)
module Attributes = Attributes
(** Helpers for AWS domain-specific/embedded languages*)
module Helpers = struct
  module Iam_policy = Iam_policy
  (** IAM Policy generation*)
end