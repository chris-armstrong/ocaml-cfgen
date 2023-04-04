open Token_map

let ref_resolver logical_id =
  let module RefResolvable = struct
    let resolve () = `Assoc [("Ref", `String logical_id)]
  end in
  (module RefResolvable: Resolvable)

let attr_resolver logical_id attribute_name =
  let module AttrResolvable = struct
    let resolve () = `Assoc [("Fn::GetAtt", `String (logical_id ^ "." ^ attribute_name))]
  end in
  (module AttrResolvable: Resolvable)
