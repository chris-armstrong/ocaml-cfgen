module StringMap : Map.S with type key = string
(* sig
     type key = string
     type 'a t = 'a Map.Make(String).t
     val empty : 'a t
     val is_empty : 'a t -> bool
     val mem : key -> 'a t -> bool
     val add : key -> 'a -> 'a t -> 'a t
     val update : key -> ('a option -> 'a option) -> 'a t -> 'a t
     val singleton : key -> 'a -> 'a t
     val remove : key -> 'a t -> 'a t
     val merge :
       (key -> 'a option -> 'b option -> 'c option) -> 'a t -> 'b t -> 'c t
     val union : (key -> 'a -> 'a -> 'a option) -> 'a t -> 'a t -> 'a t
     val compare : ('a -> 'a -> int) -> 'a t -> 'a t -> int
     val equal : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
     val iter : (key -> 'a -> unit) -> 'a t -> unit
     val fold : (key -> 'a -> 'b -> 'b) -> 'a t -> 'b -> 'b
     val for_all : (key -> 'a -> bool) -> 'a t -> bool
     val exists : (key -> 'a -> bool) -> 'a t -> bool
     val filter : (key -> 'a -> bool) -> 'a t -> 'a t
     val filter_map : (key -> 'a -> 'b option) -> 'a t -> 'b t
     val partition : (key -> 'a -> bool) -> 'a t -> 'a t * 'a t
     val cardinal : 'a t -> int
     val bindings : 'a t -> (key * 'a) list
     val min_binding : 'a t -> key * 'a
     val min_binding_opt : 'a t -> (key * 'a) option
     val max_binding : 'a t -> key * 'a
     val max_binding_opt : 'a t -> (key * 'a) option
     val choose : 'a t -> key * 'a
     val choose_opt : 'a t -> (key * 'a) option
     val split : key -> 'a t -> 'a t * 'a option * 'a t
     val find : key -> 'a t -> 'a
     val find_opt : key -> 'a t -> 'a option
     val find_first : (key -> bool) -> 'a t -> key * 'a
     val find_first_opt : (key -> bool) -> 'a t -> (key * 'a) option
     val find_last : (key -> bool) -> 'a t -> key * 'a
     val find_last_opt : (key -> bool) -> 'a t -> (key * 'a) option
     val map : ('a -> 'b) -> 'a t -> 'b t
     val mapi : (key -> 'a -> 'b) -> 'a t -> 'b t
     val to_seq : 'a t -> (key * 'a) Seq.t
     val to_rev_seq : 'a t -> (key * 'a) Seq.t
     val to_seq_from : key -> 'a t -> (key * 'a) Seq.t
     val add_seq : (key * 'a) Seq.t -> 'a t -> 'a t
     val of_seq : (key * 'a) Seq.t -> 'a t
   end *)

module type StackResourceCreator = sig
  val type_ : string
  val yojson_of_properties : unit -> Yojson.Safe.t

  type attributes
end

type parameter_string_constraints = {
  default_value : string option;
  min_length : int option;
  max_length : int option;
  allowed_values : string list option;
  allowed_pattern : string option;
}

type 'a parameter_number_constraints = {
  default_value : 'a option;
  min_value : 'a option;
  max_value : 'a option;
}

type stack_parameter_value =
  | ParameterString of parameter_string_constraints
  | ParameterInteger of int parameter_number_constraints
  | ParameterFloat of float parameter_number_constraints

type stack_parameter = {
  value : stack_parameter_value;
  description : string option;
  no_echo : bool option;
}

type logical_resource = { type_ : string }
type t

val make : unit -> t

val add_resource :
  t ->
  string ->
  (module StackResourceCreator with type attributes = 'a) ->
  logical_resource

val add_parameter :
  t ->
  string ->
  stack_parameter_value ->
  ?description:string ->
  ?no_echo:bool ->
  unit ->
  unit

val add_string_parameter :
  t ->
  string ->
  ?description:string ->
  ?no_echo:bool ->
  ?min_length:int ->
  ?max_length:int ->
  ?allowed_values:string list ->
  ?allowed_pattern:string ->
  ?default_value:string ->
  unit ->
  unit

val serialise : t -> Yojson.Safe.t
