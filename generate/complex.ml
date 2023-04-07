open Parse.Types
open Primitives
open Symbol_utils

let format_complex_type = function
  | ComplexPrimitive x -> format_primitive_type x
  | ComplexRecord x -> to_type_name x