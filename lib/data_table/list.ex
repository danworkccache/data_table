defmodule DataTable.List do
  @moduledoc """
  DataTable source for a native Elixir list.
  """

  @behaviour DataTable.Source

  alias DataTable.Source.Result

  @impl true
  def query({list, config}, query) do
    results =
      list
      |> Stream.with_index()
      |> Stream.map(fn {item, idx} -> config.mapper.(item, idx) end)
      |> filter_results(query.filters, config.filters)
      |> maybe_apply(query.sort, &sort_results/2)
      |> maybe_apply(query.offset, &Stream.drop/2)
      |> maybe_apply(query.limit, &Stream.take/2)

    %Result{
      results: results,
      total_results: Enum.count(list)
    }
  end

  @impl true
  def filterable_fields({_list, config}) do
    config.filters
    |> Enum.map(fn {col_id, type} ->
      %{
        col_id: col_id,
        type: type
      }
    end)
  end

  @impl true
  def filter_types(arg), do: DataTable.Ecto.filter_types(arg)

  defp sort_results(list, {field, order}) do
    Enum.sort_by(list, &(Map.get(&1, field)), order)
  end

  def filter_results(list, [], _config_filters) do
    list
  end

  def filter_results(list, query_filters, config_filters) do
    list
    |> Stream.filter(fn row ->
      query_filters
      |> Stream.map(fn filter ->
        filter_type = Map.fetch!(config_filters, filter.field)
        filter_value = case filter_type do
          :integer ->
            {value, ""} = Integer.parse(filter.value)
            value
          :string ->
            String.downcase(filter.value || "")
          :boolean ->
            filter.value == "true"
        end

        row_value =
          case {filter_type, Map.get(row, filter.field)} do
            {:string, value} -> String.downcase(value)
            {_, value} -> value
          end

        case {filter_type, filter.op} do
            {:string, :contains} -> String.contains?(row_value, filter_value)
            {_, :eq} -> row_value == filter_value
            {_, :lt} -> row_value < filter_value
            {_, :gt} -> row_value > filter_value
        end
      end)
      |> Enum.all?()
    end)
  end

  @impl true
  def key({_list, config}), do: config.key_field

  defp maybe_apply(list, nil, _fun) do
    list
  end

  defp maybe_apply(list, val, fun) do
    fun.(list, val)
  end

end
