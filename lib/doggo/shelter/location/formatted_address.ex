defmodule Doggo.Shelter.Location.FormattedAddress do
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context) do
    [:address, :city, :region, :postal_code]
  end

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn location ->
      parts = [location.address, location.city, location.region, location.postal_code]
      parts |> Enum.reject(&is_nil/1) |> Enum.reject(&(&1 == "")) |> Enum.join(", ")
    end)
  end
end
