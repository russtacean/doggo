defmodule Doggo.Shelter.RecurringShiftMaterializationObanTest do
  use Doggo.DataCase, async: false

  alias Doggo.Shelter
  alias Doggo.Shelter.RecurringShift
  alias Doggo.TestGenerators

  test "AshOban scheduled action materializes recurring shifts" do
    today = Date.utc_today()
    location = TestGenerators.generate(TestGenerators.location(timezone: "Etc/UTC"))

    Shelter.create_recurring_shift!(%{
      name: "Oban Materialized Walk",
      day_of_week: Date.day_of_week(today),
      start_time: ~T[09:00:00],
      end_time: ~T[10:00:00],
      location: location.id
    })

    assert %{success: 1, failure: 0} =
             AshOban.Test.schedule_and_run_triggers(
               {RecurringShift, :materialize_scheduled_shifts},
               scheduled_actions?: true
             )

    scheduled_shifts =
      Shelter.list_scheduled_shifts_for_location_between_dates!(
        location.id,
        today,
        Date.add(today, 30)
      )

    assert Enum.any?(scheduled_shifts, &(&1.date == today))
  end
end
