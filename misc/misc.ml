let rec mkdirp ?(base = Sys.getcwd ()) segments =
  match segments with
  | [] -> ()
  | segment :: segments ->
      let path = Filename.concat base segment in
      (match Sys.file_exists path with
      | true -> ()
      | false -> Sys.mkdir path 0o755);
      mkdirp ~base:path segments