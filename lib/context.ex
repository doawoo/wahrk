defmodule Wahrk.Context do
  use TypedStruct

  alias Wahrk.Mohawk

  typedstruct do
    field :struct, Mohawk.t(), default: nil
    field :raw_bytes, binary(), enforce: true
  end
end
