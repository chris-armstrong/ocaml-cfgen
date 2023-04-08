# cfgen

Generate CloudFormation stacks with OCaml

## Getting Started

* [Tutorial](https://chris-armstrong.github.io/ocaml-cfgen/cfgen/tutorial): learn about features and how to use it
* [Library Documentation](https://chris-armstrong.github.io/ocaml-cfgen/cfgen/): reference manual, concepts and API documentation

## Status

This is a work in progress.

You can already use it to define CloudFormation stacks for all the resource
types provided in the AWS CloudFormation Resource Specification, but not all
CloudFormation features may be supported.

## Implementation

[Cloudformation definitions provided by AWS](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html) have been
used to generate OCaml types for the `Properties` clauses
of each CloudFormation Type.

## What can I do with this now?

* Install dependencies in an opam switch and run `dune build` to view the output specifications (see `_build/default/spec` directory).
* Experiment with the generated API in `examples/`