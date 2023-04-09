(**
  CloudFormation intrinsics and pseudo-parameters are for using dynamic values in resource
  properties and stack outputs that are only available at deployment
  time.

  These intrinsics are tokens, so they can be used directly as
  resource property values or concatenated in strings.
*)

(** The [AWS::AccountId] psuedo-parameter for returning the AWS account the stack is deployed in *)
let account =
  let module Resolve = struct
    let resolve () = `Assoc [("Ref", `String "AWS::AccountId")]
  end in
Token_map.create_string_token ~token_type:"Account" (module Resolve: Token_map.Resolvable)

(** The [AWS::Region] psuedo-parameter for returning the AWS account the stack is deployed in *)
let region =
  let module Resolve = struct
    let resolve () = `Assoc [("Ref", `String "AWS::Region")]
  end in
Token_map.create_string_token ~token_type:"Region" (module Resolve: Token_map.Resolvable)

(** The [AWS::StackId] psuedo-parameter for returning the deployed stack ID *)
let stack_id =
  let module Resolve = struct
    let resolve () = `Assoc [("Ref", `String "AWS::StackId")]
  end in
Token_map.create_string_token ~token_type:"StackId" (module Resolve: Token_map.Resolvable)

(** The [AWS::StackName] psuedo-parameter for returning the deployed stack name *)
let stack_name =
  let module Resolve = struct
    let resolve () = `Assoc [("Ref", `String "AWS::StackName")]
  end in
Token_map.create_string_token ~token_type:"StackName" (module Resolve: Token_map.Resolvable)

(** The [AWS::NoValue] psuedo-parameter for returning an empty value from a [Fn::If] intrinsic *)
let no_value =
  let module Resolve = struct
    let resolve () = `Assoc [("Ref", `String "AWS::NoValue")]
  end in
Token_map.create_string_token ~token_type:"NoValue" (module Resolve: Token_map.Resolvable)

(** Split a list of [values] with [delimiter] at runtime.

  Uses the [Fn::Split] intrinsic function.

  {i Note that [delimiter] will not undergo token substitution, but [values] can.}
 *)
let fn_split ~delimiter (values: string) =
  let module Resolve = struct
    let resolve () = `Assoc [("Fn::Split", `List [`String delimiter; Util.yojson_of_string values])]
  end in
Token_map.create_string_token ~token_type:"FnSplit" (module Resolve: Token_map.Resolvable)

(** Import a value exported by another stack (in the same account and region) at deployment time.

  Uses the [Fn::ImportValue] intrinsic.
 *)
let fn_import_value (name: string) =
  let module Resolve = struct
    let resolve () = `Assoc [("Fn::ImportValue", Util.yojson_of_string name)]
  end in
Token_map.create_string_token ~token_type:"FnImportValue" (module Resolve: Token_map.Resolvable)