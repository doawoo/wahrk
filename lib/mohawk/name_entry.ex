defmodule Wahrk.Mohawk.NameEntry do
  use TypedStruct

  typedstruct do
    field :namelist_offset, integer(), enforce: true
    field :resource_index, integer(), enforce: true
    field :string, String.t(), default: nil
  end
end
