defmodule Wahrk.Mohawk.RSRCHeader do
  use TypedStruct

  typedstruct do
    field :signature, String.t(), enforce: true
    field :version, integer(), enforce: true
    field :compaction, integer(), enforce: true
    field :total_file_size, integer(), enforce: true
    field :resource_dir_offset, integer(), enforce: true
    field :file_table_offset, integer(), enforce: true # NOTE: this is the offset INSIDE The resource dir
    field :file_table_size, integer(), enforce: true
  end
end
