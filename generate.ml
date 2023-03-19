open Yojson.Safe;;

let dir = Array.get Sys.argv 1 in

let files = Sys.readdir dir in
let trees =
  files |> Array.to_list
  |> List.map (fun filename ->
         let tree = from_file (Filename.concat dir filename) in
         Fmt.pr "File: %s\n" filename;
         let property_types = tree |> Parse.read_property_types in
         let (resource_name, resource_type) = tree |> Parse.read_resource_type in
         let resource_specification_version =
           tree |> Util.member "ResourceSpecificationVersion" |> Util.to_string
         in
         Fmt.pr "\n\n%s: version=%s\n" filename resource_specification_version;
        Fmt.pr "\n%s specification: %a" resource_name Parse.Types.pp_resource_specification resource_type;
         Fmt.pr "\nProperty specifications: %a\n\n\n"
           Parse.Types.pp_property_specifications property_types)
in
()
