(lang dune 3.4)

(generate_opam_files true)
(name cfgen)
(package
  (name cfgen)
  (allow_empty)
  (synopsis "Generate AWS CloudFormation templates from code")
  (description "AWS CloudFormation can be difficult to manage directly. This project provides the
  ability to generate templates from code, and provide higher-level constructs for their generation.")
  (authors "Chris Armstrong")
  (maintainers "Chris Armstrong <info@chrisarmstrong.dev>")
  (homepage https://github.com/chris-armstrong/ocaml-cfgen)
  (bug_reports https://github.com/chris-armstrong/ocaml-cfgen/issues)
  (depends yojson containers fmt ppx_deriving (ppx_expect :with-test) (odoc :with-doc)))

