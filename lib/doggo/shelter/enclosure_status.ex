defmodule Doggo.Shelter.EnclosureStatus do
  use Ash.Type.Enum, values: [:available, :occupied, :maintenance, :out_of_service]
end
