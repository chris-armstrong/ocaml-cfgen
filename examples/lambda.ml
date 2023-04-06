open Cf_aws.Lambda
open Cf_aws.IAM
open Cf_base

let stack = Stack.make ()

let role =
  Stack.add_resource stack "FunctionRole"
    (module Role)
    (Role.make_properties
       ~assume_role_policy_document:
         {|
    {
      "Statement": {
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    }
  |}
       ~policies:[

        Role.make_policy ~policy_name:"cloudwatch" ~policy_document:"" ()
       ] ())

let resource =
  Stack.add_resource stack "FunctionX"
    (module Function)
    (Function.make_properties ~runtime:"nodejs12.x"
       ~code:(Function.make_code ~s3_bucket:"bucket" ~s3_key:"my_key/key" ())
       ~role:role.attributes.arn ())
;;

Stack.add_string_parameter stack "TestParameter"
  ~description:"This is a test parameter" ~default_value:"Foobar" ()

let serialised_stack = Stack.serialise stack;;

Fmt.pr "Stack:@\n%s@\n" (Yojson.Safe.to_string serialised_stack);;
Fmt.pr "Ref:%s@\n" resource.attributes.ref_
