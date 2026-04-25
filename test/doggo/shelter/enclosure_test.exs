defmodule Doggo.Shelter.EnclosureTest do
  use Doggo.DataCase, async: true

  import Doggo.AshAssertions

  alias Doggo.Shelter
  alias Doggo.TestGenerators

  describe "enclosures" do
    setup do
      location = TestGenerators.generate(TestGenerators.location())
      %{location: location}
    end

    test "create_enclosure_at_location/1 creates an enclosure with default status", %{
      location: location
    } do
      enclosure = Shelter.create_enclosure_at_location!(%{name: "Run 1", location: location.id})

      assert enclosure.name == "Run 1"
      assert enclosure.status == :available
      assert enclosure.location_id == location.id
    end

    test "create_enclosure_at_location/1 accepts a custom status", %{location: location} do
      enclosure =
        Shelter.create_enclosure_at_location!(%{
          name: "Run 2",
          location: location.id,
          status: :maintenance
        })

      assert enclosure.status == :maintenance
    end

    test "create_enclosure_at_location/1 fails without a name", %{location: location} do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_enclosure_at_location(%{location: location.id})

      assert_required_error(errors, :name)
    end

    test "create_enclosure_at_location/1 fails without a location" do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_enclosure_at_location(%{name: "Orphan Run"})

      assert_required_error(errors, :location)
    end

    test "create_enclosure_at_location/1 fails when location does not exist" do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_enclosure_at_location(%{
                 name: "Ghost Run",
                 location: Ecto.UUID.generate()
               })

      assert_invalid_relationship_error(errors, :location)
    end

    test "update_enclosure/2 updates enclosure attributes", %{location: location} do
      enclosure = Shelter.create_enclosure_at_location!(%{name: "Run 3", location: location.id})

      updated = Shelter.update_enclosure!(enclosure, %{status: :occupied})
      assert updated.status == :occupied
    end

    test "destroy_enclosure/1 deletes an enclosure", %{location: location} do
      enclosure = Shelter.create_enclosure_at_location!(%{name: "Run 4", location: location.id})

      :ok = Shelter.destroy_enclosure!(enclosure)
      assert {:error, _} = Shelter.get_enclosure(enclosure.id)
    end

    test "enclosure status only accepts valid values", %{location: location} do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_enclosure_at_location(%{
                 name: "Bad Status",
                 location: location.id,
                 status: :nonexistent
               })

      assert_invalid_attribute_error(errors, :status)
    end

    test "list_enclosures_for_location/1 returns enclosures sorted by name", %{
      location: location
    } do
      Shelter.create_enclosure_at_location!(%{name: "Run B", location: location.id})
      Shelter.create_enclosure_at_location!(%{name: "Run A", location: location.id})

      enclosures = Shelter.list_enclosures_for_location!(location.id)
      names = Enum.map(enclosures, & &1.name)
      assert names == ["Run A", "Run B"]
    end
  end
end
