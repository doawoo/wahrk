defmodule Wahrk.Mohawk do
  use TypedStruct

  alias Wahrk.Mohawk.IFFHeader
  alias Wahrk.Mohawk.RSRCHeader
  alias Wahrk.Mohawk.TypeTable
  alias Wahrk.Mohawk.NameTable
  alias Wahrk.Mohawk.ResourceTable
  alias Wahrk.Mohawk.FileTable

  typedstruct do
    field :iff_header, IFFHeader.t(), enforce: true
    field :rsrc_header, RSRCHeader.t(), enforce: true
    field :type_table, TypeTable.t(), enforce: true
    field :name_tables, list(NameTable.t()), enforce: true
    field :file_table, FileTable.t(), enforce: true
    field :resource_tables, list(ResourceTable.t()), enforce: true
  end
end
