defmodule Wahrk.Mohawk.FileEntry do
  use TypedStruct

  typedstruct do
    field :data_offset, integer(), enforce: true
    field :datasize, integer(), enforce: true
    field :flags, binary(), enforce: true
    field :raw_bytes, binary(), enforce: true
    field :unknown_flag, integer(), enforce: true
  end
end
