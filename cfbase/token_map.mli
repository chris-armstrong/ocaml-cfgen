module type Resolvable = sig val resolve : unit -> Yojson.Safe.t end
val create_string_token : ?token_type:string -> (module Resolvable) -> string
val create_long_token : (module Resolvable) -> int64
val create_double_token : (module Resolvable) -> float
val create_int_token : (module Resolvable) -> int
val create_string_list_token : ?token_type:string -> (module Resolvable) -> string list
val lookup_string_token : string -> (module Resolvable) option
val lookup_double_token : float -> (module Resolvable) option
val lookup_int_token : int -> (module Resolvable) option
val lookup_long_token : int64 -> (module Resolvable) option

val has_string_token : string -> bool