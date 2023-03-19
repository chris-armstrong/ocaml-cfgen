type update_type = Mutable | Immutable | Conditional [@@deriving show]

type primitive_type =
  | String
  | Long
  | Integer
  | Double
  | Boolean
  | Timestamp
  | Json
[@@deriving show]

type complex_type =
  | ComplexPrimitive of primitive_type
  | ComplexRecord of string
[@@deriving show]

type property_type =
  | PropertyPrimitive of primitive_type
  | PropertyRecord of string
  | PropertyList of complex_type
  | PropertyMap of complex_type
[@@deriving show]

type property_definition = {
  documentation : string;
  required : bool;
  update_type : update_type;
  property_type : property_type;
}
[@@deriving show]

type property_definitions = (string * property_definition) list
[@@deriving show]

type property_specification = {
  documentation : string;
  properties : property_definitions;
}
[@@deriving show]

type property_specifications = (string * property_specification) list
[@@deriving show]

type attribute_type =
  | AttributePrimitive of primitive_type
  | AttributeRecord of string
  | AttributeList of complex_type
[@@deriving show]

type resource_specification = {
  documentation : string;
  attributes : (string * attribute_type) list;
  properties : property_definitions;
}
[@@deriving show]
