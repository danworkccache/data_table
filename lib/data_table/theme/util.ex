defmodule DataTable.Theme.Util do
  @moduledoc """
  Utilities which are useful for building your own theme.
  """

  def generate_pages(page, page_size, results_count) do
    max_page = div(results_count + (page_size - 1), page_size) - 1

    middle_pages =
      (page - 3)..(page + 3)
      |> Enum.filter(&(&1 >= 0))
      |> Enum.filter(&(&1 <= max_page))

    pages = Enum.map(middle_pages, fn i ->
      {:page, i, i == page}
    end)

    pages
  end

end
