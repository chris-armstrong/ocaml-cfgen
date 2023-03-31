module StringMap_ = Map.Make(String)

module StringMap = struct
  include StringMap_

  let yojson_of_t value_conv s = `Assoc (fold (fun (k: string) v l -> (k, value_conv v)::l) s [])

end