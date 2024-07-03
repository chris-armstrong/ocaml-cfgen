[@@@warning "-unused-value-declaration"]
[@@@warning "-unused-var-strict"]
[@@@warning "-unused-field"]
[@@@warning "-unused-constructor"]

open Cfgen
open Cfgen.BaseConstructs.AWS.Lambda
open Cfgen.BaseConstructs.AWS.IAM

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

type buildTask =
  | DuneTarget of string
  | PackageZip of string
  | CopyToS3 of string

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

module Id = struct
  type t = { id : string }

  let make id = { id }
  let get { id } = id
end

module Scope = struct
  type t = { path : string list }

  let root = { path = [] }
  let append scope id = { path = id :: scope.path }
  let path scope = scope.path
end

let make_logical_id scope id =
  Digestif.SHA1.(
    let ctx = empty in
    let ctx = feed_string ctx "/" in
    let ctx =
      List.fold_right
        (fun a ctx ->
          let ctx = feed_string ctx a in
          feed_string ctx "/")
        (Scope.path scope) ctx
    in
    let ctx = feed_string ctx (Id.get id) in
    get ctx |> to_hex)

type synthesized =
  | CfnResource of (module PackedResource)
  | Construct of construct list

and construct = {
  scope : Scope.t;
  id : Id.t;
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

module CfnRole = struct
  let make scope id properties =
    make_cfn_resource scope id properties (module Role)
end

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
            make_cfn_role scope (Id.make "Role")
              (Role.make_properties
                 ~assume_role_policy_document:
                   (assume_role_policy_document_for_service service_domain)
                 ~policies:inline_policies ());
          ]);
  }

let make_simple_function scope id ~path ~role =
  let x =
    {
      scope;
      id;
      build = (fun () -> [ DuneTarget path ]);
      synthesize =
        (fun () ->
          Construct
            [
              make_cfn_function scope (Id.make "Function")
                (Function.make_properties ~role:role.attributes.arn
                   ~code:(Function.make_code ~s3_bucket:"" ~s3_key:path ())
                   ());
            ]);
    }
  in
  x

let make_stack id ~resources =
  let stack =
    {
      scope = Scope.root;
      id;
      build = (fun () -> []);
      synthesize = (fun () -> Construct resources);
    }
  in
  stack

let synthesize_stack stack =
  let rec gather_resources construct =
    construct.synthesize () |> function
    | Construct x -> x |> List.map gather_resources |> List.flatten
    | CfnResource resource ->
        let module Unpacked = (val resource : PackedResource) in
        [
          ( make_logical_id construct.scope construct.id,
            Unpacked.type_,
            Unpacked.yojson_of_properties () );
        ]
  in
  let resources = gather_resources stack in
  resources

(* Fmt.pr "%s\n" (Yojson.Safe.pretty_to_string serialised_template) *)
