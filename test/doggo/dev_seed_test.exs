defmodule Doggo.DevSeedTest do
  use Doggo.DataCase, async: true

  alias Doggo.{DevSeed, Shelter}

  test "seeds on first run, skips on second, uses relative scheduled dates" do
    today = ~D[2030-05-20]

    assert {:ok, :seeded} = DevSeed.run(today: today)
    assert {:ok, :skipped} = DevSeed.run(today: today)

    locations = Shelter.list_active_locations!()
    assert length(locations) == 2

    primary =
      Enum.find(locations, &(&1.name == DevSeed.primary_location_name())) ||
        flunk("expected primary dev location")

    secondary = Enum.find(locations, &(&1.name == "Doggo Uptown Annex"))
    assert secondary

    assert length(Shelter.list_enclosures_for_location!(primary.id)) == 4
    assert length(Shelter.list_enclosures_for_location!(secondary.id)) == 3

    scheduled = Shelter.list_scheduled_shifts!()
    assert length(scheduled) == 6

    by_location = Enum.group_by(scheduled, & &1.location_id)
    assert length(by_location[primary.id]) == 5
    assert length(by_location[secondary.id]) == 1

    assert Enum.all?(scheduled, fn s ->
             Date.compare(s.date, Date.add(today, -1)) != :lt and
               Date.compare(s.date, Date.add(today, 2)) != :gt
           end)

    recurring = Shelter.list_recurring_shifts!()
    assert length(recurring) == 4
  end

  test "force removes prior dev seed and re-seeds without duplicating locations" do
    today = ~D[2030-06-01]
    later = ~D[2030-12-15]

    assert {:ok, :seeded} = DevSeed.run(today: today)
    assert {:ok, :seeded} = DevSeed.run(today: later, force: true)

    locations = Shelter.list_active_locations!()
    assert length(locations) == 2
    assert DevSeed.primary_location_name() in Enum.map(locations, & &1.name)

    scheduled = Shelter.list_scheduled_shifts!()
    assert Enum.all?(scheduled, fn s -> s.date != today end)
    assert Enum.any?(scheduled, &(&1.date == later))
  end
end
