defmodule Doggo.Shelter.RecurringShiftMaterializationTest do
  use Doggo.DataCase, async: true

  alias Doggo.Shelter
  alias Doggo.Shelter.RecurringShift.Materializer
  alias Doggo.TestGenerators

  @as_of ~U[2026-04-01 12:00:00Z]
  @window_start ~D[2026-04-01]
  @window_end ~D[2026-05-01]

  describe "materialize_scheduled_shifts" do
    setup do
      location = TestGenerators.generate(TestGenerators.location(timezone: "Etc/UTC"))
      %{location: location}
    end

    test "creates scheduled shifts for matching weekdays inside the 30-day window", %{
      location: location
    } do
      Shelter.create_recurring_shift!(%{
        name: "Wednesday Walk",
        day_of_week: 3,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        location: location.id
      })

      assert {:ok, 5} = Materializer.materialize(as_of: @as_of, horizon_days: 30)

      scheduled_shifts =
        Shelter.list_scheduled_shifts_for_location_between_dates!(
          location.id,
          @window_start,
          @window_end
        )

      assert Enum.map(scheduled_shifts, & &1.date) == [
               ~D[2026-04-01],
               ~D[2026-04-08],
               ~D[2026-04-15],
               ~D[2026-04-22],
               ~D[2026-04-29]
             ]
    end

    test "honors recurring shift effective date boundaries", %{location: location} do
      Shelter.create_recurring_shift!(%{
        name: "Active Boundary Pattern",
        day_of_week: 3,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        start_date: ~D[2026-04-08],
        end_date: ~D[2026-04-22],
        location: location.id
      })

      Shelter.create_recurring_shift!(%{
        name: "Expired Pattern",
        day_of_week: 3,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        start_date: ~D[2026-03-01],
        end_date: ~D[2026-04-01],
        location: location.id
      })

      Shelter.create_recurring_shift!(%{
        name: "Future Pattern",
        day_of_week: 3,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        start_date: ~D[2026-05-01],
        location: location.id
      })

      assert {:ok, 2} = Materializer.materialize(as_of: @as_of, horizon_days: 30)

      scheduled_shifts =
        Shelter.list_scheduled_shifts_for_location_between_dates!(
          location.id,
          @window_start,
          @window_end
        )

      assert Enum.map(scheduled_shifts, &{&1.name, &1.date}) == [
               {"Active Boundary Pattern", ~D[2026-04-08]},
               {"Active Boundary Pattern", ~D[2026-04-15]}
             ]
    end

    test "does not duplicate an existing scheduled shift or create duplicates on repeat runs", %{
      location: location
    } do
      recurring_shift_attrs = %{
        name: "Idempotent Walk",
        day_of_week: 3,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        location: location.id
      }

      Shelter.create_recurring_shift!(recurring_shift_attrs)

      Shelter.create_scheduled_shift_at_location!(%{
        name: recurring_shift_attrs.name,
        date: @window_start,
        start_time: recurring_shift_attrs.start_time,
        end_time: recurring_shift_attrs.end_time,
        location: location.id
      })

      assert {:ok, 4} = Materializer.materialize(as_of: @as_of, horizon_days: 30)
      assert {:ok, 0} = Materializer.materialize(as_of: @as_of, horizon_days: 30)

      scheduled_shifts =
        Shelter.list_scheduled_shifts_for_location_between_dates!(
          location.id,
          @window_start,
          @window_end
        )

      assert length(scheduled_shifts) == 5
    end

    test "skips archived locations", %{location: location} do
      location = Shelter.update_location!(location, %{archived: true})

      Shelter.create_recurring_shift!(%{
        name: "Archived Walk",
        day_of_week: 3,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        location: location.id
      })

      assert {:ok, 0} = Materializer.materialize(as_of: @as_of, horizon_days: 30)

      assert [] =
               Shelter.list_scheduled_shifts_for_location_between_dates!(
                 location.id,
                 @window_start,
                 @window_end
               )
    end

    test "uses each location's timezone to determine the local window" do
      utc_location =
        TestGenerators.generate(TestGenerators.location(name: "UTC Shelter", timezone: "Etc/UTC"))

      new_york_location =
        TestGenerators.generate(
          TestGenerators.location(name: "New York Shelter", timezone: "America/New_York")
        )

      Shelter.create_recurring_shift!(%{
        name: "UTC Wednesday",
        day_of_week: 3,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        location: utc_location.id
      })

      Shelter.create_recurring_shift!(%{
        name: "New York Tuesday",
        day_of_week: 2,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        location: new_york_location.id
      })

      assert {:ok, 10} =
               Materializer.materialize(as_of: ~U[2026-04-01 03:30:00Z], horizon_days: 30)

      utc_dates =
        utc_location.id
        |> Shelter.list_scheduled_shifts_for_location_between_dates!(
          ~D[2026-04-01],
          ~D[2026-05-01]
        )
        |> Enum.map(& &1.date)

      new_york_dates =
        new_york_location.id
        |> Shelter.list_scheduled_shifts_for_location_between_dates!(
          ~D[2026-03-31],
          ~D[2026-04-30]
        )
        |> Enum.map(& &1.date)

      assert hd(utc_dates) == ~D[2026-04-01]
      assert hd(new_york_dates) == ~D[2026-03-31]
    end
  end
end
