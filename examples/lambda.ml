open Cf_aws.Lambda
open Cf_base

let main () =
  let stack = Stack.make () in
  let lambda_props =
    Function.make_properties
      ~runtime:"nodejs12.x"
      ~code:(Function.make_code ~s3_bucket:"bucket" ~s3_key:"my_key/key" ())
      ~role:"role" () in

  let _ = Stack.add_resource stack "FunctionX" (Function.create lambda_props) in
  Stack.add_string_parameter stack "TestParameter"
    ~description:"This is a test parameter"
    ~default_value:"Foobar"
    ();

  let serialised_stack = Stack.serialise stack
  in serialised_stack;;

Fmt.pr "Stack:\n%s" (Yojson.Safe.to_string (main ()))
