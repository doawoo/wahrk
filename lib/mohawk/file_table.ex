defmodule Wahrk.Mohawk.FileTable do
  use TypedStruct

  alias Wahrk.Mohawk.FileEntry

  typedstruct do
    field :num_entries, integer(), enforce: true
    field :entries, list(FileEntry.t()), enforce: true
  end
end
