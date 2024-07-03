let input_files = Array.sub Sys.argv 1 (Array.length Sys.argv - 1)

module StringMap = Containers.Map.Make (String)

let write_resource f namespace service resource type_ property_types =
  let namespace_dir = [ namespace; service; resource ] in
  let namespace_path = String.concat "." namespace_dir in
  let fqn = String.concat "::" namespace_dir in
  Fmt.pr "- Generating %s\n" namespace_path;
  Generate.write_resource_interface f fqn resource type_ property_types

let write_resources_by_keyed_namespace =
  Hashtbl.iter (fun namespace services_map ->
      let open Containers in
      let filename = Fmt.str "Cf_%s.ml" (String.lowercase_ascii namespace) in
      Fmt.pr "Writing %s\n" filename;
      let oc = Out_channel.open_text filename in
      let f = Format.formatter_of_out_channel oc in

      services_map |> Hashtbl.to_list
      |> List.iter
           (fun (service, (resource_tuples : Specs.resource_tuple list)) ->
             Fmt.pf f "module %s = %s@\n" service service;
             let service_filename = Fmt.str "%s.ml" service in
             let soc = Out_channel.open_text service_filename in
             let sf = Format.formatter_of_out_channel soc in
             (* Fmt.pf sf "open @\n@\n"; *)
             Fmt.pf sf "open Util@\n@\n";
             resource_tuples
             |> List.iter (fun (resource, type_, prop_types) ->
                    write_resource sf namespace service resource type_
                      prop_types);
             Format.pp_print_flush sf ();
             Out_channel.close soc);
      Format.pp_print_flush f ();
      Out_channel.close oc)

let write_resource_interfaces (resource_specs : Specs.resource_tuple list) =
  resource_specs |> Specs.organise_resources_by_namespace
  |> write_resources_by_keyed_namespace

let () = input_files |> Specs.load_resource_specs |> write_resource_interfaces
