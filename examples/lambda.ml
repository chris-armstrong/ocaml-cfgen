open Cf_aws.Lambda
open Cf_aws.IAM
open Cf_base

let stack = Stack.make ()

let lambda_assume_role_policy_document =
  Iam_policy.yojson_of_policy
    (Iam_policy.policy
       [
         Iam_policy.assume_role_statement
           (Iam_policy.aws_service_principal "lambda");
       ])

let lambda_cloudwatch_logs_policy =
  Iam_policy.(
    yojson_of_policy
      (policy
         [
           statement
             ~action:
               [
                 "logs:CreateLogStream";
                 "logs:CreateLogGroup";
                 "logs:PutLogEvents";
               ]
             ~resource:[ "*" ] ();
         ]))

let role =
  Stack.add_resource stack "FunctionRole"
    (module Role)
    (Role.make_properties
       ~assume_role_policy_document:lambda_assume_role_policy_document
       ~policies:
         [
           Role.make_policy ~policy_name:"cloudwatch"
             ~policy_document:lambda_cloudwatch_logs_policy ();
         ]
       ())

let _ =
  Stack.add_resource stack "FunctionX"
    (module Function)
    (Function.make_properties ~runtime:"nodejs18.x"
       ~code:(Function.make_code ~s3_bucket:"bucket" ~s3_key:"my_key/key" ())
       ~role:role.attributes.arn ())
;;

Stack.add_string_parameter stack "TestParameter"
  ~description:"This is a test parameter" ~default_value:"Foobar" ()

let serialised_stack = Stack.serialise stack;;

Fmt.pr "%s\n" (Yojson.Safe.pretty_to_string serialised_stack);;
