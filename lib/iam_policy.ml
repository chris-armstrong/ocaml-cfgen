open Util

type iam_policy_version = PolicyVersion2008_10_17 | PolicyVersion2012_10_17

let yojson_of_iam_policy_version = function
  | PolicyVersion2008_10_17 -> `String "2008-10-17"
  | PolicyVersion2012_10_17 -> `String "2012-10-17"

type principal_map =
  | AWS of string list
  | CanonicalUser of string list
  | Federated of string list
  | Service of string list

let yojson_of_principal_map : principal_map -> Yojson.Safe.t = function
  | AWS x -> `Assoc [ ("AWS", (yojson_of_list yojson_of_string) x) ]
  | Service x -> `Assoc [ ("Service", (yojson_of_list yojson_of_string) x) ]
  | CanonicalUser x ->
      `Assoc [ ("CanonicalUser", (yojson_of_list yojson_of_string) x) ]
  | Federated x -> `Assoc [ ("Federated", (yojson_of_list yojson_of_string) x) ]

type principal =
  | Principal of principal_map
  | NotPrincipal of principal_map
  | PrincipalAll
  | NotPrincipalAll

let yojson_of_principal : principal -> Yojson.Safe.t = function
  | Principal x -> `Assoc [ ("Principal", yojson_of_principal_map x) ]
  | NotPrincipal x -> `Assoc [ ("NotPrincipal", yojson_of_principal_map x) ]
  | PrincipalAll -> `Assoc [ ("Principal", `String "*") ]
  | NotPrincipalAll -> `Assoc [ ("NotPrincipal", `String "*") ]

type effect = Allow | Deny

let yojson_of_effect = function
  | Allow -> `String "Allow"
  | Deny -> `String "Deny"

type action = string list

let yojson_of_action = yojson_of_list yojson_of_string

type resource = string list

let yojson_of_resource (l : string list) : Yojson.Safe.t =
  yojson_of_list yojson_of_string l

type condition_operator =
  | StringEquals
  | StringNotEquals
  | StringEqualsIgnoreCase
  | StringNotEqualsIgnoreCase
  | StringLike
  | NumericEquals
  | NumericNotEquals
  | NumericLessThan
  | NumericGreaterThan
  | NumericLessThanEquals
  | NumericGreaterThanEquals
  | DateEquals
  | DateNotEquals
  | DateLessThan
  | DateGreaterThan
  | DateLessThanEquals
  | DateGreaterThanEquals
  | Bool
  | BinaryEquals
  | IPAddress
  | NotIPAddress

let string_of_condition_operator = function
  | StringEquals -> "StringEquals"
  | StringNotEquals -> "StringNotEquals"
  | StringEqualsIgnoreCase -> "StringEqualsIgnoreCase"
  | StringNotEqualsIgnoreCase -> "StringNotEqualsIgnoreCase"
  | StringLike -> "StringLike"
  | NumericEquals -> "NumericEquals"
  | NumericNotEquals -> "NumericNotEquals"
  | NumericLessThan -> "NumericLessThan"
  | NumericGreaterThan -> "NumericGreaterThan"
  | NumericLessThanEquals -> "NumericLessThanEquals"
  | NumericGreaterThanEquals -> "NumericGreaterThanEquals"
  | DateEquals -> "DateEquals"
  | DateNotEquals -> "DateNotEquals"
  | DateLessThan -> "DateLessThan"
  | DateGreaterThan -> "DateGreaterThan"
  | DateLessThanEquals -> "DateLessThanEquals"
  | DateGreaterThanEquals -> "DateGreaterThanEquals"
  | Bool -> "Bool"
  | BinaryEquals -> "BinaryEquals"
  | IPAddress -> "IPAddress"
  | NotIPAddress -> "NotIPAddress"

let yojson_of_condition_value = yojson_of_string

type condition_term = string * string list

type condition_operator_spec =
  | ForValue of condition_operator
  | ForAnyValue of condition_operator
  | ForAllValues of condition_operator
(* | ForValue of conditionKey * conditionValue (* ForValue is a convenience - a single element list with ForValues should be equivalent *)
   | ForValues of conditionKey * conditionValue list
   | ForAnyValue of conditionKey * conditionValue list
   | ForAllValues of conditionKey * conditionValue list *)

let yojson_of_condition_term ((key, values) : condition_term) : Yojson.Safe.t =
  `Assoc [ (key, yojson_of_list yojson_of_string values) ]

let yojson_of_condition_operator_spec : condition_operator_spec -> string =
  function
  | ForValue op -> string_of_condition_operator op
  | ForAnyValue op -> "ForAnyValue:" ^ string_of_condition_operator op
  | ForAllValues op -> "ForAllValues:" ^ string_of_condition_operator op

type condition = (condition_operator_spec * condition_term) list

let yojson_of_condition (condition : condition) : Yojson.Safe.t =
  `Assoc
    (List.map
       (fun (op, term) ->
         (yojson_of_condition_operator_spec op, yojson_of_condition_term term))
       condition)

type statement = {
  sid : string option;
  principal : principal option;
  effect : effect;
  action : action;
  resource : resource option;
  condition : condition option;
}

let yojson_of_statement (statement: statement) : Yojson.Safe.t =
  let base = prepend_option_map [] yojson_of_string statement.sid "Sid" in
  let base =
    prepend_option_map base yojson_of_principal statement.principal "Principal"
  in
  let base =
    prepend_option_map base yojson_of_condition statement.condition "Condition"
  in
  let base = prepend_option_map base yojson_of_resource statement.resource "Resource" in
  let required =
    [
      ("Effect", yojson_of_effect statement.effect);
      ("Action", yojson_of_action statement.action);
    ]
  in
  `Assoc (List.concat [ required; base ])

type policy = {
  version : iam_policy_version;
  id : string option;
  statement : statement list;
}

let yojson_of_policy policy =
  let base = prepend_option_map [] yojson_of_string policy.id "Id" in
  let required = ["Version", yojson_of_iam_policy_version policy.version; "Statement", yojson_of_list yojson_of_statement policy.statement] in
  `Assoc (List.concat [required; base])

let statement ?(effect=Allow) ?sid ?principal ?condition ?resource ~action () = { effect; sid; principal; condition; action; resource }
let aws_service_principal service = Principal (Service [service ^ ".amazonaws.com"])
let assume_role_statement ?(effect=Allow) principal = statement ~effect ~action:["sts:AssumeRole"] ~principal ()
let policy ?(version=PolicyVersion2012_10_17) ?id statements = { version; id; statement= statements }