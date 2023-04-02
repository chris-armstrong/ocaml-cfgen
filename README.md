# cfgen

Generate CloudFormation stacks with OCaml

## Background

This is a work in progress.

The intention behind this project is to make it easier
to generate CloudFormation stacks in OCaml code, taking
advantage of the type system and fast compiler to aid
development.

This work was inspired by (and built in frustration with)
the AWS CDK.

## Implementation

[Cloudformation definitions provided by AWS](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html) have been
used to generate OCaml types for the `Properties` clauses
of each CloudFormation Type.

A basic support library, which allows constructing a stack
with parameters, is provided as `Cf_base` (not exported).

## Status

This isn't particularly useful in its current form as
it is a in-progress prototype.

Cloudformation definitions can be generated in OCaml, and
a basic stack output in JSON format. (see `examples/lambda.ml`).

No support for Cloudformation intrinsic functions, like `Fn::Ref` or `Fn::GetAtt`, is provided yet, and is needed
to be useful. Support of these will probably be implemented
similar to CDK, where token substitutions are used at runtime
and then mapped at generation time, as this does not require
intrinsics to be baked into the type system of each attribute.

## What can I do with this now?

* Install dependencies in an opam switch and run `dune build` to view the output specifications (see `_build/default/spec` directory).
* Experiment with the generated API in `examples/`