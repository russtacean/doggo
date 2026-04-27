defmodule DoggoWeb.Format do
  @moduledoc """
  Shared presentation formatting for web views.
  """

  @doc """
  Formats a time for compact display.
  """
  @spec format_time(Time.t()) :: String.t()
  def format_time(%Time{} = time) do
    time
    |> Time.truncate(:second)
    |> to_string()
    |> String.slice(0, 5)
  end

  @doc """
  Formats a start/end time range.
  """
  @spec format_time_range(Time.t(), Time.t(), String.t()) :: String.t()
  def format_time_range(%Time{} = start_time, %Time{} = end_time, separator \\ "-") do
    "#{format_time(start_time)}#{separator}#{format_time(end_time)}"
  end

  @doc """
  Formats a date for display.
  """
  @spec format_date(Date.t()) :: String.t()
  def format_date(%Date{} = date), do: Date.to_iso8601(date)
end
