open Cf_aws.Lambda

let f =
  Function.make
    ~code:(Function.make_code ~s3_bucket:"bucket" ~s3_key:"my_key/key" ())
    ~role:"role" ()

let x = Function.yojson_of_t f
