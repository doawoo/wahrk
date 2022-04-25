defmodule Wahrk.Mohawk.ResourceTable do
  use TypedStruct

  alias Wahrk.Mohawk.ResourceEntry

  typedstruct do
    field :num_entries, integer(), enforce: true
    field :entries, list(ResourceEntry.t()), enforce: true
    field :for_type, String.t(), enforce: true
  end
end
