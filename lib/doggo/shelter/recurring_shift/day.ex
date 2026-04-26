defmodule Doggo.Shelter.RecurringShift.Day do
  @moduledoc """
  Labels for `day_of_week` (ISO: 1 = Monday … 7 = Sunday), matching `Date.day_of_week/1`.
  """

  @ordered [
    {1, "Monday"},
    {2, "Tuesday"},
    {3, "Wednesday"},
    {4, "Thursday"},
    {5, "Friday"},
    {6, "Saturday"},
    {7, "Sunday"}
  ]

  @type day :: 1..7

  @doc """
  Human-readable name for a stored day (1..7).
  """
  @spec label(day()) :: String.t()
  def label(n) when n in 1..7 do
    @ordered |> List.keyfind(n, 0) |> elem(1)
  end

  @doc """
  Options for `<.field type="select" field={@form[:day_of_week]} ... />`.
  """
  @spec form_select_options() :: [{String.t(), pos_integer()}]
  def form_select_options do
    Enum.map(@ordered, fn {n, name} -> {name, n} end)
  end

  @doc """
  Ordered weekdays as `{day_number, label}` tuples.
  """
  @spec ordered() :: [{day(), String.t()}]
  def ordered, do: @ordered
end
