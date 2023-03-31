open Parse.Types
let input_files = Array.sub Sys.argv 1 (Array.length Sys.argv - 1)

let load_resource_specs () =
  let specs =
    input_files
    |> Array.map (fun filename ->
           let tree = Yojson.Safe.from_file filename in
           Fmt.pr "File: %s\n" filename;
           let property_types = tree |> Parse.read_property_types in
           let resource_name, resource_type =
             tree |> Parse.read_resource_type
           in
           (resource_name, resource_type, property_types))
    |> Array.to_list
  in
  specs

module StringMap = Containers.Map.Make (String)

let write_resource f namespace service resource type_ property_types =
  let namespace_dir = [ namespace; service; resource ] in
  let namespace_path = String.concat "." namespace_dir in
  Fmt.pr "- Generating %s\n" namespace_path;
  Generate.write_resource_interface f resource type_ property_types


(** A resource tuple, consisting of:
    * the resource name (namespaced or not)
    * resource specification
    * list associated property specifications (record type definitions)
  *)
type resource_tuple = string * resource_specification * property_specifications

let key_by_namespace =
  List.fold_left
    (fun namespace_map (namespace, service, (res: resource_tuple)) ->
      let open Containers in
      let services_map =
        Hashtbl.get_or_add namespace_map ~k:namespace ~f:(fun _ ->
            Hashtbl.create 0)
      in
      let resources_list =
        Hashtbl.get_or_add services_map ~k:service ~f:(fun _ -> [])
      in
      let resources_list = res :: resources_list in
      Hashtbl.replace services_map service resources_list;
      namespace_map)
    (Containers.Hashtbl.create 2)

let write_resources_by_keyed_namespace =
  Hashtbl.iter (fun namespace services_map ->
      let open Containers in
      let filename = Fmt.str "Cf_%s.ml" (String.lowercase_ascii namespace) in
      Fmt.pr "Writing %s\n" filename;
      let oc = Out_channel.open_text filename in
      let f = Format.formatter_of_out_channel oc in

      services_map |> Hashtbl.to_list |> List.take 200
      |> List.iter (fun (service, (resource_tuples: resource_tuple list)) ->
        Fmt.pf f "module %s = %s@\n" service service;
        let service_filename = Fmt.str "%s.ml" service in
        let soc = Out_channel.open_text service_filename in
        let sf = Format.formatter_of_out_channel soc in
        Fmt.pf sf "open Cfbase@\n";
        Fmt.pf sf "open Ppx_yojson_conv_lib.Yojson_conv.Primitives@\n";
             (* Fmt.pf sf "module@;%s@;=@;struct@;@[<2>@;" service; *)
             resource_tuples
             |> List.iter (fun (resource, type_, prop_types) ->
                    write_resource sf namespace service resource type_ prop_types);
             (* Fmt.pf sf "@]end@,@\n"; *)
             (* Format.pp_print_newline sf (); *)
             Format.pp_print_flush sf ();
             Out_channel.close soc
             );
      Format.pp_print_flush f ();
      Out_channel.close oc)

let write_resource_interfaces (resource_specs: resource_tuple list) =
  let by_namespace =
    resource_specs
    |> List.map (fun (name, type_, property_types) ->
           let parts = Containers.String.split ~by:"::" name in

           match parts with
           | namespace :: service :: [ resource ] ->
               (namespace, service, (resource, type_, property_types))
           | _ ->
               raise
                 (Parse.ParseError
                    ("Resource name \"" ^ name
                   ^ "\" does not split into 3 parts")))
    |> key_by_namespace
  in
  by_namespace |> write_resources_by_keyed_namespace

let () = load_resource_specs () |> write_resource_interfaces
