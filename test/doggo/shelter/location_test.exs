defmodule Doggo.Shelter.LocationTest do
  use Doggo.DataCase, async: true

  import Doggo.AshAssertions

  alias Doggo.Shelter
  alias Doggo.TestGenerators

  describe "locations" do
    test "create_location/1 creates a location with required attributes" do
      location = Shelter.create_location!(%{name: "Downtown Shelter"})

      assert location.name == "Downtown Shelter"
      assert location.country == "USA"
      assert location.timezone == "America/New_York"
      assert location.archived == false
    end

    test "create_location/1 accepts all address fields" do
      attrs = %{
        name: "Eastside Shelter",
        address: "123 Main St",
        city: "Portland",
        region: "Oregon",
        postal_code: "97201",
        country: "CA",
        timezone: "America/Vancouver"
      }

      location = Shelter.create_location!(attrs)

      assert location.name == "Eastside Shelter"
      assert location.address == "123 Main St"
      assert location.city == "Portland"
      assert location.region == "Oregon"
      assert location.postal_code == "97201"
      assert location.country == "CA"
      assert location.timezone == "America/Vancouver"
      assert location.archived == false
    end

    test "create_location/1 fails without a name" do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_location(%{address: "123 Main St"})

      assert_required_error(errors, :name)
    end

    test "get_location/1 retrieves a location by id" do
      location = Shelter.create_location!(%{name: "Test Shelter"})

      found = Shelter.get_location!(location.id)
      assert found.id == location.id
      assert found.name == "Test Shelter"
    end

    test "update_location/2 updates location attributes" do
      location = Shelter.create_location!(%{name: "Old Name"})

      updated = Shelter.update_location!(location, %{name: "New Name"})
      assert updated.name == "New Name"
    end

    test "update_location/2 can archive a location" do
      location = Shelter.create_location!(%{name: "To Archive"})
      assert location.archived == false

      archived = Shelter.update_location!(location, %{archived: true})
      assert archived.archived == true
    end

    test "destroy_location/1 deletes a location" do
      location = Shelter.create_location!(%{name: "To Delete"})

      :ok = Shelter.destroy_location!(location)
      assert {:error, _} = Shelter.get_location(location.id)
    end

    test "list_locations/0 returns both active and archived" do
      Shelter.create_location!(%{name: "Active Location"})
      archived = Shelter.create_location!(%{name: "Archived Location"})
      Shelter.update_location!(archived, %{archived: true})

      locations = Shelter.list_locations!()
      names = Enum.map(locations, & &1.name)
      assert "Active Location" in names
      assert "Archived Location" in names
    end

    test "list_active_locations/0 returns only non-archived locations sorted by name" do
      Shelter.create_location!(%{name: "Zebra Shelter"})
      Shelter.create_location!(%{name: "Alpha Shelter"})
      archived = Shelter.create_location!(%{name: "Archived Shelter"})
      Shelter.update_location!(archived, %{archived: true})

      locations = Shelter.list_active_locations!()
      names = Enum.map(locations, & &1.name)
      assert names == ["Alpha Shelter", "Zebra Shelter"]
      refute "Archived Shelter" in names
    end
  end

  describe "location aggregates" do
    setup do
      location = TestGenerators.generate(TestGenerators.location())
      %{location: location}
    end

    test "get_location! with load: [:available_enclosure_count] returns counts", %{
      location: location
    } do
      Shelter.create_enclosure_at_location!(%{name: "Run 1", location: location.id})
      Shelter.create_enclosure_at_location!(%{name: "Run 2", location: location.id})

      location_with_counts =
        Shelter.get_location!(location.id, load: [:enclosure_count, :available_enclosure_count])

      assert location_with_counts.enclosure_count == 2
      assert location_with_counts.available_enclosure_count == 2

      occupied = Shelter.create_enclosure_at_location!(%{name: "Run 3", location: location.id})
      Shelter.update_enclosure!(occupied, %{status: :occupied})

      location_with_counts =
        Shelter.get_location!(location.id, load: [:enclosure_count, :available_enclosure_count])

      assert location_with_counts.enclosure_count == 3
      assert location_with_counts.available_enclosure_count == 2
    end
  end
end
