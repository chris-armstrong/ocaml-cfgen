open Token_map

(** Create a [Ref] resolver token string for the specified [logical_id] *)
let ref_resolver logical_id =
  let module RefResolvable = struct
    let resolve () = `Assoc [ ("Ref", `String logical_id) ]
  end in
  (module RefResolvable : Resolvable)

(** 
    @param logical_id
    @param attribute_name

    Create a [Fn::GetAtt] resolver token string for the specified [logical_id] and [attribute_name] 
*)

let attr_resolver logical_id attribute_name =
  let module AttrResolvable = struct
    let resolve () =
      `Assoc [ ("Fn::GetAtt", `String (logical_id ^ "." ^ attribute_name)) ]
  end in
  (module AttrResolvable : Resolvable)
