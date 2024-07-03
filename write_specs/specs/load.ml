let load_resource filename =
  try
    let tree = Yojson.Safe.from_file ~fname:filename filename in
    Fmt.pr "Loading file: %s\n" filename;
    let property_types = tree |> Parse.read_property_types in
    let resource_name, resource_type = tree |> Parse.read_resource_type in
    (resource_name, resource_type, property_types)
  with e -> Printf.printf "Could not load file %s" filename; raise e

let load_resource_specs input_files =
  let specs =
    input_files
    |> Array.map (fun filename ->
           try load_resource filename
           with e ->
             let msg = Printexc.to_string e in
             let trace = Printexc.get_backtrace () in
             Printf.eprintf "Error processing %s: %s\n\n%s\n" filename msg trace;
             raise e)
    |> Array.to_list
  in
  specs
