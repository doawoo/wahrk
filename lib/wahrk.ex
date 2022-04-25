defmodule Wahrk do
  alias Wahrk.Context
  alias Wahrk.Mohawk

  @bytesize_iff_header 8
  @size_byte 8
  @size_short 16
  @size_long 32

  @spec parse_from_file_path(binary(), boolean()) :: Wahrk.Mohawk.t()
  def parse_from_file_path(path, load_data \\ false) when is_binary(path) do
    context = %Context{
      struct: %Mohawk{
        iff_header: nil,
        rsrc_header: nil,
        type_table: nil,
        name_tables: [],
        resource_tables: [],
        file_table: nil,
      },
      raw_bytes: File.read!(path)
    }

    result = parse_iff_header(context)
    |> parse_rsrc_header()
    |> parse_type_table()
    |> parse_name_table()
    |> parse_resource_table()
    |> parse_file_table()

    result = if load_data do
      load_raw_data(result)
    else
      result
    end

    result.struct
  end

  defp parse_iff_header(%Context{} = parser_context) do
    <<header::binary-size(4), file_length::size(@size_long), _rest::binary>> =
      parser_context.raw_bytes

    if header != "MHWK" do
      raise "Header of the archive is invalid, refusing to parse the rest of the file!"
    end

    iff_header = %Mohawk.IFFHeader{
      header: header,
      file_length: file_length
    }

    mohawk = %Mohawk{parser_context.struct | iff_header: iff_header}
    %Context{parser_context | struct: mohawk}
  end

  defp parse_rsrc_header(%Context{} = parser_context) do
    cursor = @bytesize_iff_header

    <<
      _leading::binary-size(cursor),
      sig::binary-size(4),
      version::size(@size_short),
      compaction::size(@size_short),
      total_file_size::size(@size_long),
      offset_res::size(@size_long),
      offset_file_table::size(@size_short),
      file_table_size::size(@size_short),
      _rest::binary
    >> = parser_context.raw_bytes

    rsrc_header = %Mohawk.RSRCHeader{
      signature: sig,
      version: version,
      compaction: compaction,
      total_file_size: total_file_size,
      resource_dir_offset: offset_res,
      file_table_offset: offset_file_table,
      file_table_size: file_table_size
    }

    mohawk = %Mohawk{parser_context.struct | rsrc_header: rsrc_header}
    %Context{parser_context | struct: mohawk}
  end

  defp parse_type_table(%Context{} = parser_context) do
    cursor = parser_context.struct.rsrc_header.resource_dir_offset

    <<
      _leading::binary-size(cursor),
      namelist_offset::size(@size_short),
      num_types::size(@size_short),
      rest::binary
    >> = parser_context.raw_bytes

    type_entries =
      Enum.reduce(0..(num_types - 1), [], fn index, acc ->
        cursor = index * 8

        <<
          _leading::binary-size(cursor),
          res_type::binary-size(4),
          offset_res_table::size(@size_short),
          offset_name_table::size(@size_short),
          _rest::binary
        >> = rest

        entry = %Mohawk.TypeEntry{
          resource_type: res_type,
          offset_res_table: offset_res_table,
          offset_name_table: offset_name_table
        }

        [entry | acc]
      end)

    type_table = %Mohawk.TypeTable{
      offset_name_list: namelist_offset,
      num_resource_types: num_types,
      types: type_entries
    }

    mohawk = %Mohawk{parser_context.struct | type_table: type_table}
    %Context{parser_context | struct: mohawk}
  end

  defp parse_name_table(%Context{} = parser_context) do
    types = parser_context.struct.type_table.types

    name_tables =
      Enum.reduce(types, [], fn %Wahrk.Mohawk.TypeEntry{} = type, acc ->
        # cursor to the name tables inside the resource dir
        cursor = parser_context.struct.rsrc_header.resource_dir_offset + type.offset_name_table

        <<_leading::binary-size(cursor), num_names::size(@size_short), _rest::binary>> =
          parser_context.raw_bytes

        name_entries =
          if num_names == 0 do
            []
          else
            Enum.reduce(0..(num_names - 1), [], fn index, name_acc ->
              # cursor to the name table entry inside the name table
              entry_cursor = cursor + 2 + index * 4

              <<
                _leading::binary-size(entry_cursor),
                namelist_offset::size(@size_short),
                resource_index::size(@size_short),
                _rest::binary
              >> = parser_context.raw_bytes

              string_cursor = parser_context.struct.rsrc_header.resource_dir_offset + parser_context.struct.type_table.offset_name_list + namelist_offset
              <<_leading::binary-size(string_cursor), slice::binary>> = parser_context.raw_bytes
              string_value = null_term_string(slice, "")

              name = %Mohawk.NameEntry{
                namelist_offset: namelist_offset,
                resource_index: resource_index,
                string: string_value
              }

              [name | name_acc]
            end)
          end

        name_table = %Mohawk.NameTable{
          num_entries: num_names,
          entries: name_entries,
          for_type: type.resource_type
        }

        [name_table | acc]
      end)

      mohawk = %Mohawk{parser_context.struct | name_tables: name_tables}
      %Context{parser_context | struct: mohawk}
  end

  defp parse_resource_table(%Context{} = parser_context) do
    types = parser_context.struct.type_table.types

    resource_tables = Enum.reduce(types, [], fn %Wahrk.Mohawk.TypeEntry{} = type, acc ->
      # cursor to the name tables inside the resource dir
      cursor = parser_context.struct.rsrc_header.resource_dir_offset + type.offset_res_table
      <<_leading::binary-size(cursor), num_entries::size(@size_short), _rest::binary>> =
        parser_context.raw_bytes

      entires = if num_entries == 0 do
        []
      else
        Enum.reduce(0..(num_entries - 1), [], fn index, entry_acc ->
          entry_cursor = cursor + 2 + index * 4

          <<
            _leading::binary-size(entry_cursor),
            resource_id::size(@size_short),
            file_table_index::size(@size_short),
            _rest::binary
          >> = parser_context.raw_bytes

          entry = %Wahrk.Mohawk.ResourceEntry{
            id: resource_id,
            file_index: file_table_index
          }

          [entry | entry_acc]
        end)
      end

      table = %Mohawk.ResourceTable{
        num_entries: num_entries,
        entries: entires,
        for_type: type.resource_type
      }

      [table | acc]
    end)

    mohawk = %Mohawk{parser_context.struct | resource_tables: resource_tables}
    %Context{parser_context | struct: mohawk}
  end

  defp parse_file_table(%Context{} = parser_context) do
    cursor = parser_context.struct.rsrc_header.resource_dir_offset + parser_context.struct.rsrc_header.file_table_offset

    <<
      _leading::binary-size(cursor),
      num_entries::size(@size_long),
      _slice::binary
    >> = parser_context.raw_bytes

    record_size = 10 # long(4) + short(2) + byte(1) + byte(1) + short(2)

    entries = Enum.reduce(0..num_entries - 1, [], fn index, acc ->
      cursor_entry = (cursor + 4) + (index * record_size)

      <<
        _leading::binary-size(cursor_entry),
        abs_offset::size(@size_long),
        res_size::size(24), # the file size is 3 bytes
        flags::size(@size_byte),
        unknown::size(@size_short),
        _rest::binary
      >> = parser_context.raw_bytes

      entry = %Mohawk.FileEntry{
        data_offset: abs_offset,
        datasize: res_size,
        flags: flags,
        unknown_flag: unknown,
        raw_bytes: nil,
      }

      [entry | acc]
    end)

    file_table = %Mohawk.FileTable{
      num_entries: num_entries,
      entries: entries |> Enum.reverse(),
    }

    mohawk = %Mohawk{parser_context.struct | file_table: file_table}
    %Context{parser_context | struct: mohawk}
  end

  defp load_raw_data(%Context{} = parser_context) do
    file_table = parser_context.struct.file_table

    new_entries =
    Enum.with_index(file_table.entries)
    |> Enum.map(fn {entry, index} ->
      offset = entry.data_offset
      next = Enum.at(file_table.entries, index + 1, nil)

      size = if next do
        next.data_offset - offset
      else
        nil
      end

      content = if size do
        <<_leading::binary-size(offset), content::binary-size(size), _rest::binary>> = parser_context.raw_bytes
        content
      else
        <<_leading::binary-size(offset), content::binary>> = parser_context.raw_bytes
        content
      end

      %Mohawk.FileEntry{entry | raw_bytes: content}
    end)

    file_table = %Mohawk.FileTable{file_table | entries: new_entries}
    mohawk = %Mohawk{parser_context.struct | file_table: file_table}
    %Context{parser_context | struct: mohawk}
  end

  defp null_term_string(<<0, _rest::binary>>, acc) do
    acc
  end

  defp null_term_string(<<c::binary-size(1), rest::binary>>, acc) do
    null_term_string(rest, acc <> c)
  end
end
