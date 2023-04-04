open Cf_aws.Lambda
open Cf_base

let stack = Stack.make ()

let lambda_props =
  Function.make_properties ~runtime:"nodejs12.x"
    ~code:(Function.make_code ~s3_bucket:"bucket" ~s3_key:"my_key/key" ())
    ~role:"role" ()

let resource = Stack.add_resource stack "FunctionX" (module Function) lambda_props;;

Stack.add_string_parameter stack "TestParameter"
  ~description:"This is a test parameter" ~default_value:"Foobar" ()

let serialised_stack = Stack.serialise stack;;

Fmt.pr "Stack:@\n%s@\n" (Yojson.Safe.to_string serialised_stack);;
Fmt.pr "Ref:%s@\n" resource.attributes.ref_
