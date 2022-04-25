defmodule Wahrk.Mohawk.ResourceEntry do
  use TypedStruct

  typedstruct do
    field :id, integer(), enforce: true
    field :file_index, integer(), enforce: true
  end
end
