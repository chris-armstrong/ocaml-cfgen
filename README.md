# cfgen

Define AWS CloudFormation templates with OCaml code.

## Documentation

- [Tutorial](https://chris-armstrong.github.io/ocaml-cfgen/cfgen/tutorial): learn about features and how to use it
- [Library Documentation](https://chris-armstrong.github.io/ocaml-cfgen/cfgen/): reference manual, concepts and API documentation

## Status

This is a work in progress, but usable in its current state.

You can already use it to define CloudFormation stacks for all the resource
types provided in the AWS CloudFormation Resource Specification, but not all
CloudFormation features may be supported.

### What can I do with this now?

- Install dependencies in an opam switch and run `dune build` to view the output specifications (see `_build/default/spec` directory).
- Experiment with the generated API in `examples/`

## Installation

While cfgen is in prerelease, use `opam pin` to install directly from git:

```sh
opam pin cfgen https://github.com/chris-armstrong/ocaml-cfgen.git#v1.0.0-alpha.0
```
