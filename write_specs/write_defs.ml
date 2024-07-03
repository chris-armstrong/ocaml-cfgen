let main () =
  Fmt.pr "Generating defs.inc for %a\n" (Fmt.list Fmt.string)
    (Array.to_list Sys.argv);
  let defs_filename = Array.get Sys.argv 1 in
  let input_files = Array.sub Sys.argv 2 (Array.length Sys.argv - 2) in
  let resources = Specs.load_resource_specs input_files in
  let by_namespace = resources |> Specs.organise_resources_by_namespace in
  let open Containers in
  let oc = Out_channel.open_text defs_filename in
  let f = Format.formatter_of_out_channel oc in

  Fmt.pf f "(rule@\n";
  Fmt.pf f "@;(alias generate_sources)@\n";
  Fmt.pf f "@;(target ";
  Hashtbl.iter
    (fun namespace services_map ->
      let filename = Fmt.str "Cf_%s.ml" (String.lowercase_ascii namespace) in
      Fmt.pr "Source %s\n" filename;
      Fmt.pf f "@;%s@\n" filename;
      services_map |> Hashtbl.to_list
      |> List.iter (fun (service, _) ->
             let service_filename = Fmt.str "%s.ml" service in
             Fmt.pf f "@;%s@\n" service_filename))
    by_namespace;
  Fmt.pf f
    {|@;)

  (deps
    (sandbox always)
    (:jsonfiles
    (glob_files "../definitions/*.json")))
  (action
    (run ../write_specs/write_specs.exe %%{jsonfiles}))

  )|};
  Format.pp_print_flush f ();
  Out_channel.close oc

let () = main ()
