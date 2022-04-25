defmodule Wahrk.Mohawk.IFFHeader do
  use TypedStruct

  typedstruct do
    field :header, String.t(), enforce: true
    field :file_length, integer(), enforce: true
  end
end
