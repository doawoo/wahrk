defmodule Wahrk.Mohawk.TypeEntry do
  use TypedStruct

  typedstruct do
    field :resource_type, String.t(), enforce: true
    field :offset_res_table, integer(), enforce: true
    field :offset_name_table, integer(), enforce: true
  end
end
