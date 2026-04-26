defmodule Doggo.Shelter.EnclosureStatus do
  use Ash.Type.Enum, values: [:available, :occupied, :maintenance, :out_of_service]

  @order [:available, :occupied, :maintenance, :out_of_service]

  @doc """
  Human-readable label for status (badges, selects).
  """
  @spec label(atom()) :: String.t()
  def label(:available), do: "Available"
  def label(:occupied), do: "Occupied"
  def label(:maintenance), do: "Maintenance"
  def label(:out_of_service), do: "Out of Service"

  @doc """
  Petal `<.badge color={...}>` name for the given status.
  """
  @spec badge_color(atom()) :: String.t()
  def badge_color(:available), do: "success"
  def badge_color(:occupied), do: "primary"
  def badge_color(:maintenance), do: "warning"
  def badge_color(:out_of_service), do: "danger"

  @doc """
  Options for `<.field type="select" options={...} />`.
  """
  @spec form_select_options() :: [{String.t(), atom()}]
  def form_select_options do
    Enum.map(@order, fn value -> {label(value), value} end)
  end
end
