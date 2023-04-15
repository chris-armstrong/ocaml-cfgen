(lang dune 3.4)

(generate_opam_files true)
(name cfgen)
(package
  (name cfgen)
  (allow_empty)
  (synopsis "Generate AWS CloudFormation templates from code")
  (description "This project provides the
  ability to generate AWS CloudFormation templates from OCaml code, with a support library to ease its use.
  AWS resource definitions have been used to generate constructs for building CloudFormation resources
  in a type-safe way.")
  (authors "Chris Armstrong")
  (maintainers "Chris Armstrong <oss@chrisarmstrong.dev>")
  (homepage https://github.com/chris-armstrong/ocaml-cfgen)
  (bug_reports https://github.com/chris-armstrong/ocaml-cfgen/issues)
  (depends yojson containers fmt ppx_deriving (ppx_expect :with-test) (odoc :with-doc)))

