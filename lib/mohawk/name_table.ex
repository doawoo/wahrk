defmodule Wahrk.Mohawk.NameTable do
  use TypedStruct

  alias Wahrk.Mohawk.NameEntry

  typedstruct do
    field :num_entries, integer(), enforce: true
    field :entries, list(NameEntry.t()), enforce: true
    field :for_type, String.t(), enforce: true
  end
end
