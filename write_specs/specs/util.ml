open Parse.Types

type resource_tuple = string * resource_specification * property_specifications
(** A resource tuple, consisting of:
    * the resource name (namespaced or not)
    * resource specification
    * list associated property specifications (record type definitions)
  *)

let key_by_namespace =
  List.fold_left
    (fun namespace_map (namespace, service, (res : resource_tuple)) ->
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

let organise_resources_by_namespace resource_specs =
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
  by_namespace
