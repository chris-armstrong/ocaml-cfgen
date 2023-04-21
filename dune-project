(lang dune 3.4)

(generate_opam_files true)

(name cfgen)

(package
 (name cfgen)
 (allow_empty)
 (synopsis "Generate AWS CloudFormation templates from code")
 (description
  "This project provides the\n  ability to generate AWS CloudFormation templates from OCaml code, with a support library to ease its use.\n  AWS resource definitions have been used to generate constructs for building CloudFormation resources\n  in a type-safe way.")
 (authors "Chris Armstrong")
 (maintainers "Chris Armstrong <oss@chrisarmstrong.dev>")
 (homepage https://github.com/chris-armstrong/ocaml-cfgen)
 (bug_reports https://github.com/chris-armstrong/ocaml-cfgen/issues)
 (source (github chris-armstrong/ocaml-cfgen))
 (license MIT)
 (depends
  (dune (>= "3.4"))
  (ocaml (>= "4.14"))
  (yojson (>= "2.0.0"))
  containers
  (fmt (>= "0.9.0"))
  ppx_deriving
  ppx_expect
  (odoc :with-doc)))
