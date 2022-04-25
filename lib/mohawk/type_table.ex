defmodule Wahrk.Mohawk.TypeTable do
  use TypedStruct

  alias Wahrk.Mohawk.TypeEntry

  typedstruct do
    field :offset_name_list, integer(), enforce: true
    field :num_resource_types, integer(), enforce: true
    field :types, list(TypeEntry.t()), enforce: true
  end
end
