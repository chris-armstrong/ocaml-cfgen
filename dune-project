(lang dune 3.7)

(generate_opam_files true)
(package
  (name cfgen)
  (allow_empty)
  (synopsis "Generate AWS CloudFormation templates from code")
  (description "AWS CloudFormation can be difficult to manage directly. This project provides the
  ability to generate templates from code, and provide higher-level constructs for their generation")
  (depends yojson ppx_yojson_conv containers ppx_deriving))

(using directory-targets 0.1)