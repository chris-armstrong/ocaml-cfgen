open Cfgen
open Cfgen.BaseConstructs.AWS.Lambda
open Cfgen.BaseConstructs.AWS.IAM

let template = Template.make ()

let lambda_assume_role_policy_document =
  Helpers.Iam_policy.(
    yojson_of_policy
      (policy [ assume_role_statement (aws_service_principal "lambda") ]))

let lambda_cloudwatch_logs_policy =
  Helpers.Iam_policy.(
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
  Template.add_resource template "FunctionRole"
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
  Template.add_resource template "FunctionX"
    (module Function)
    Function.(make_properties ~runtime:"nodejs18.x"
       ~code:(Function.make_code ~s3_bucket:"bucket" ~s3_key:"my_key/key" ())
       ~role:role.attributes.arn 
       ~tags:[make_tag ~key:"Environment" ~value:"development" ()]
       ())
;;

Template.add_string_parameter template "TestParameter"
  ~description:"This is a test parameter" ~default_value:"Foobar" ()

let serialised_template = Template.serialise template;;

Fmt.pr "%s\n" (Yojson.Safe.pretty_to_string serialised_template)
