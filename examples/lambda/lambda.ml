[@@@warning "-unused-value-declaration"]
[@@@warning "-unused-var-strict"]
[@@@warning "-unused-field"]
[@@@warning "-unused-constructor"]

open Cfgen
open Cfgen.BaseConstructs.AWS.Lambda
open Cfgen.BaseConstructs.AWS.IAM

let template = Template.make ()

let assume_role_policy_document_for_service service =
  Helpers.Iam_policy.(
    yojson_of_policy
      (policy [ assume_role_statement (aws_service_principal service) ]))

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

let template, role =
  Template.add_resource template "FunctionRole"
    (module Role)
    (Role.make_properties
       ~assume_role_policy_document:
         (assume_role_policy_document_for_service "lambda")
       ~policies:
         [
           Role.make_policy ~policy_name:"cloudwatch"
             ~policy_document:lambda_cloudwatch_logs_policy ();
         ]
       ())

type buildTask =
  | DuneTarget of string
  | PackageZip of string
  | CopyToS3 of string

(* module rec Construct : sig *)
(*   module type T = sig *)
(*     val parent : (module Construct.T) option *)
(*     val name : string *)
(*     val build : unit -> buildTask list *)
(**)
(*     val append_template : Template.t -> Template.t *)
(*   end *)
(* end = *)
(*   Construct *)

module type PackedResource = sig
  val type_ : string
  val yojson_of_properties : unit -> Yojson.Safe.t
end

let pack_resource (type a p)
    (resource_type :
      (module Template.ResourceType
         with type attributes = a
          and type properties = p)) props =
  let module ResourceType =
    (val resource_type
        : Template.ResourceType with type properties = p and type attributes = a)
  in
  let module PackedResourceValue = struct
    let type_ = ResourceType.cloudformation_type
    let yojson_of_properties () = ResourceType.yojson_of_properties props
  end in
  (module PackedResourceValue : PackedResource)

type scope = { path : string list }

let root_scope = { path = [] }
let append_scope scope id = { path = id :: scope.path }

type id = { id : string }

let make_id id = { id }

let make_logical_id scope id =
  Digestif.SHA1.(
    let ctx = empty in
    let ctx = feed_string ctx "/" in
    let ctx =
      List.fold_right
        (fun a ctx ->
          let ctx = feed_string ctx a in
          feed_string ctx "/")
        scope.path ctx
    in
    let ctx = feed_string ctx id in
    get ctx |> to_hex)

type synthesized =
  | CfnResource of (module PackedResource)
  | Construct of construct list

and construct = {
  scope : scope;
  id : id;
  build : unit -> buildTask list;
  synthesize : unit -> synthesized;
}

let make_cfn_resource scope id properties resource_type =
  {
    scope;
    id;
    build = (fun () -> []);
    synthesize =
      (fun () -> CfnResource (pack_resource resource_type properties));
  }

let make_cfn_role scope id properties =
  make_cfn_resource scope id properties (module Role)

let make_cfn_function scope id properties =
  make_cfn_resource scope id properties (module Function)

type role = { attributes : Role.attributes }

let make_simple_service_role scope id service_domain ~inline_policies =
  {
    scope;
    id;
    build = (fun () -> []);
    synthesize =
      (fun () ->
        Construct
          [
            make_cfn_role scope (make_id "Role")
              (Role.make_properties
                 ~assume_role_policy_document:
                   (assume_role_policy_document_for_service service_domain)
                 ~policies:inline_policies ());
          ]);
  }

let make_simple_function scope id path role =
  let x =
    {
      scope;
      id;
      build = (fun () -> [ DuneTarget path ]);
      synthesize =
        (fun () ->
          Construct
            [
              make_cfn_function scope (make_id "Function")
                (Function.make_properties ~role:role.attributes.arn
                   ~code:(Function.make_code ~s3_bucket:"" ~s3_key:path ())
                   ());
            ]);
    }
  in
  x

let template, _ =
  Template.add_resource template "FunctionX"
    (module Function)
    Function.(
      make_properties ~runtime:"nodejs18.x"
        ~code:(Function.make_code ~s3_bucket:"bucket" ~s3_key:"my_key/key" ())
        ~role:role.attributes.arn
        ~tags:[ make_tag ~key:"Environment" ~value:"development" () ]
        ())

let template, _ =
  Template.add_string_parameter template "TestParameter"
    ~description:"This is a test parameter" ~default_value:"Foobar" ()

let serialised_template = Template.serialise template;;

Fmt.pr "%s\n" (Yojson.Safe.pretty_to_string serialised_template)
