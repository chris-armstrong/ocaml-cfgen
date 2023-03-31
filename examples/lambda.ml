open Cf_aws.Lambda

let main () =
  let f =
    Function.make
      ~runtime:"nodejs12.x"
      ~code:(Function.make_code ~s3_bucket:"bucket" ~s3_key:"my_key/key" ())
      ~role:"role" () in

  let x = Function.yojson_of_t f in

  Format.printf "%s\n" (Yojson.Safe.to_string x)

let () = main ()
