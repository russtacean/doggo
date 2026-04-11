defmodule Doggo.Shelter.ScheduledShiftTest do
  use Doggo.DataCase, async: true

  import Doggo.AshAssertions

  alias Doggo.Shelter
  alias Doggo.TestGenerators

  describe "scheduled_shifts" do
    setup do
      location = TestGenerators.generate(TestGenerators.location())
      %{location: location}
    end

    test "create_scheduled_shift_at_location/1 fails without required fields", %{
      location: location
    } do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_scheduled_shift_at_location(%{
                 name: "Incomplete",
                 location: location.id
               })

      assert_required_error(errors, :date)
      assert_required_error(errors, :start_time)
      assert_required_error(errors, :end_time)
    end

    test "create_scheduled_shift_at_location/1 fails without a location" do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_scheduled_shift_at_location(%{
                 name: "Orphan Scheduled Shift",
                 date: ~D[2026-04-15],
                 start_time: ~T[08:00:00],
                 end_time: ~T[12:00:00]
               })

      assert_required_error(errors, :location)
    end

    test "create_scheduled_shift_at_location/1 fails when location does not exist" do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_scheduled_shift_at_location(%{
                 name: "Ghost Scheduled Shift",
                 date: ~D[2026-04-15],
                 start_time: ~T[08:00:00],
                 end_time: ~T[12:00:00],
                 location: Ecto.UUID.generate()
               })

      assert_invalid_relationship_error(errors, :location)
    end

    test "create_scheduled_shift_at_location/1 fails when end_time is not after start_time", %{
      location: location
    } do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_scheduled_shift_at_location(%{
                 name: "Bad Scheduled Shift",
                 date: ~D[2026-04-15],
                 start_time: ~T[12:00:00],
                 end_time: ~T[08:00:00],
                 location: location.id
               })

      assert_invalid_attribute_error(errors, :end_time, "must be after the start time")
    end

    test "create_scheduled_shift_at_location/1 fails when duplicate location/date/time/name", %{
      location: location
    } do
      scheduled_shift_attrs = %{
        name: "Morning Scheduled Shift",
        date: ~D[2026-04-20],
        start_time: ~T[08:00:00],
        end_time: ~T[12:00:00],
        location: location.id
      }

      Shelter.create_scheduled_shift_at_location!(scheduled_shift_attrs)

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_scheduled_shift_at_location(scheduled_shift_attrs)

      assert_invalid_attribute_error(errors, :location_id, "has already been taken")
    end

    test "update_scheduled_shift/2 updates scheduled shift attributes", %{location: location} do
      scheduled_shift =
        TestGenerators.generate(TestGenerators.scheduled_shift(location: location.id))

      updated = Shelter.update_scheduled_shift!(scheduled_shift, %{name: "Late Scheduled Shift"})
      assert updated.name == "Late Scheduled Shift"
    end

    test "destroy_scheduled_shift/1 deletes a scheduled shift", %{location: location} do
      scheduled_shift =
        TestGenerators.generate(TestGenerators.scheduled_shift(location: location.id))

      :ok = Shelter.destroy_scheduled_shift!(scheduled_shift)
      assert {:error, _} = Shelter.get_scheduled_shift(scheduled_shift.id)
    end

    test "list_scheduled_shifts_for_location_and_date/2 returns scheduled shifts sorted by start_time",
         %{
           location: location
         } do
      Shelter.create_scheduled_shift_at_location!(%{
        name: "Evening",
        date: ~D[2026-04-20],
        start_time: ~T[14:00:00],
        end_time: ~T[18:00:00],
        location: location.id
      })

      Shelter.create_scheduled_shift_at_location!(%{
        name: "Morning",
        date: ~D[2026-04-20],
        start_time: ~T[08:00:00],
        end_time: ~T[12:00:00],
        location: location.id
      })

      scheduled_shifts =
        Shelter.list_scheduled_shifts_for_location_and_date!(location.id, ~D[2026-04-20])

      names = Enum.map(scheduled_shifts, & &1.name)
      assert names == ["Morning", "Evening"]
    end

    test "list_upcoming_scheduled_shifts/2 returns scheduled shifts on or after a date", %{
      location: location
    } do
      TestGenerators.generate(
        TestGenerators.scheduled_shift(location: location.id, date: ~D[2026-04-15], name: "Past")
      )

      TestGenerators.generate(
        TestGenerators.scheduled_shift(
          location: location.id,
          date: ~D[2026-04-20],
          name: "Upcoming"
        )
      )

      scheduled_shifts = Shelter.list_upcoming_scheduled_shifts!(location.id, ~D[2026-04-18])
      names = Enum.map(scheduled_shifts, & &1.name)
      assert "Upcoming" in names
      refute "Past" in names
    end
  end
end
