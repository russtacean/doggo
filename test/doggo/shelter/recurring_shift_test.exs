defmodule Doggo.Shelter.RecurringShiftTest do
  use Doggo.DataCase, async: true

  import Doggo.AshAssertions

  alias Doggo.Shelter
  alias Doggo.TestGenerators

  describe "recurring_shifts" do
    setup do
      location = TestGenerators.generate(TestGenerators.location())
      %{location: location}
    end

    test "list_recurring_shifts_for_location!/1 returns only shifts for that location", %{
      location: location
    } do
      other = TestGenerators.generate(TestGenerators.location())

      ours =
        Shelter.create_recurring_shift!(%{
          name: "Isolated",
          day_of_week: 2,
          start_time: ~T[10:00:00],
          end_time: ~T[11:00:00],
          location: location.id
        })

      Shelter.create_recurring_shift!(%{
        name: "Other place",
        day_of_week: 3,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        location: other.id
      })

      for_loc = Shelter.list_recurring_shifts_for_location!(location.id)
      assert length(for_loc) == 1
      assert hd(for_loc).id == ours.id
    end

    test "create_recurring_shift/1 with valid attributes", %{location: location} do
      recurring_shift =
        Shelter.create_recurring_shift!(%{
          name: "Morning Walk",
          day_of_week: 4,
          start_time: ~T[10:00:00],
          end_time: ~T[11:00:00],
          start_date: ~D[2026-04-01],
          end_date: ~D[2026-12-31],
          location: location.id
        })

      assert recurring_shift.name == "Morning Walk"
      assert recurring_shift.day_of_week == 4
      assert recurring_shift.start_time == ~T[10:00:00]
      assert recurring_shift.end_time == ~T[11:00:00]
      assert recurring_shift.start_date == ~D[2026-04-01]
      assert recurring_shift.end_date == ~D[2026-12-31]
      assert recurring_shift.location_id == location.id
    end

    test "create_recurring_shift/1 fails when end_time is not after start_time", %{
      location: location
    } do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_recurring_shift(%{
                 name: "Bad Recurring Shift",
                 day_of_week: 4,
                 start_time: ~T[12:00:00],
                 end_time: ~T[10:00:00],
                 location: location.id
               })

      assert_invalid_attribute_error(errors, :end_time, "must be after the start time")
    end

    test "create_recurring_shift/1 fails when recurring shifts have identical effective ranges",
         %{
           location: location
         } do
      attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        location: location.id
      }

      Shelter.create_recurring_shift!(attrs)

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_recurring_shift(attrs)

      assert_invalid_attribute_error(errors, :name, "overlaps with an existing recurring shift")
    end

    test "create_recurring_shift/1 allows adjacent effective ranges", %{location: location} do
      first_attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-07-01],
        location: location.id
      }

      second_attrs = %{
        first_attrs
        | start_date: ~D[2026-07-01],
          end_date: ~D[2027-01-01]
      }

      Shelter.create_recurring_shift!(first_attrs)

      assert {:ok, _recurring_shift} = Shelter.create_recurring_shift(second_attrs)
    end

    test "create_recurring_shift/1 fails when effective ranges overlap", %{location: location} do
      attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-12-31],
        location: location.id
      }

      Shelter.create_recurring_shift!(attrs)

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_recurring_shift(
                 Map.merge(attrs, %{
                   start_date: ~D[2026-06-01],
                   end_date: ~D[2026-08-01]
                 })
               )

      assert_invalid_attribute_error(errors, :name, "overlaps with an existing recurring shift")
    end

    test "create_recurring_shift/1 fails when open-ended end_date overlaps", %{
      location: location
    } do
      attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-01-01],
        location: location.id
      }

      Shelter.create_recurring_shift!(attrs)

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_recurring_shift(
                 Map.merge(attrs, %{
                   start_date: ~D[2026-06-01],
                   end_date: ~D[2026-08-01]
                 })
               )

      assert_invalid_attribute_error(errors, :name, "overlaps with an existing recurring shift")
    end

    test "create_recurring_shift/1 fails when open-ended start_date overlaps", %{
      location: location
    } do
      first_attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-12-31],
        location: location.id
      }

      Shelter.create_recurring_shift!(first_attrs)

      second_attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        end_date: ~D[2026-06-01],
        location: location.id
      }

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_recurring_shift(second_attrs)

      assert_invalid_attribute_error(errors, :name, "overlaps with an existing recurring shift")
    end

    test "create_recurring_shift/1 allows open-ended start_date that does not overlap", %{
      location: location
    } do
      first_attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-07-01],
        end_date: ~D[2026-12-31],
        location: location.id
      }

      Shelter.create_recurring_shift!(first_attrs)

      second_attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        end_date: ~D[2026-07-01],
        location: location.id
      }

      assert {:ok, _recurring_shift} = Shelter.create_recurring_shift(second_attrs)
    end

    test "create_recurring_shift/1 fails when fully open-ended shift overlaps", %{
      location: location
    } do
      first_attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-12-31],
        location: location.id
      }

      Shelter.create_recurring_shift!(first_attrs)

      second_attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        location: location.id
      }

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_recurring_shift(second_attrs)

      assert_invalid_attribute_error(errors, :name, "overlaps with an existing recurring shift")
    end

    test "create_recurring_shift/1 allows same time on a different name", %{location: location} do
      attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-12-31],
        location: location.id
      }

      Shelter.create_recurring_shift!(attrs)

      assert {:ok, _recurring_shift} = Shelter.create_recurring_shift(%{attrs | name: "Feeding"})
    end

    test "create_recurring_shift/1 allows same time and name on a different day", %{
      location: location
    } do
      attrs = %{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-12-31],
        location: location.id
      }

      Shelter.create_recurring_shift!(attrs)

      assert {:ok, _recurring_shift} = Shelter.create_recurring_shift(%{attrs | day_of_week: 5})
    end

    test "update_recurring_shift/2 fails when causing an overlap", %{location: location} do
      first_recurring_shift =
        Shelter.create_recurring_shift!(%{
          name: "Morning Walk",
          day_of_week: 4,
          start_time: ~T[10:00:00],
          end_time: ~T[11:00:00],
          start_date: ~D[2026-01-01],
          end_date: ~D[2026-07-01],
          location: location.id
        })

      Shelter.create_recurring_shift!(%{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-07-01],
        end_date: ~D[2027-01-01],
        location: location.id
      })

      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.update_recurring_shift(first_recurring_shift, %{
                 end_date: ~D[2026-08-01]
               })

      assert_invalid_attribute_error(errors, :name, "overlaps with an existing recurring shift")
    end

    test "update_recurring_shift/2 succeeds when not causing an overlap", %{location: location} do
      recurring_shift =
        Shelter.create_recurring_shift!(%{
          name: "Morning Walk",
          day_of_week: 4,
          start_time: ~T[10:00:00],
          end_time: ~T[11:00:00],
          start_date: ~D[2026-01-01],
          end_date: ~D[2026-07-01],
          location: location.id
        })

      Shelter.create_recurring_shift!(%{
        name: "Morning Walk",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-07-01],
        end_date: ~D[2027-01-01],
        location: location.id
      })

      assert {:ok, updated} =
               Shelter.update_recurring_shift(recurring_shift, %{end_date: ~D[2026-06-01]})

      assert updated.end_date == ~D[2026-06-01]
    end

    test "list_active_recurring_shifts_for_location_and_day/3 returns patterns within effective range",
         %{location: location} do
      Shelter.create_recurring_shift!(%{
        name: "Active Pattern",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-04-01],
        end_date: ~D[2026-12-31],
        location: location.id
      })

      recurring_shifts =
        Shelter.list_active_recurring_shifts_for_location_and_day!(
          location.id,
          4,
          ~D[2026-06-15]
        )

      assert length(recurring_shifts) == 1
      assert hd(recurring_shifts).name == "Active Pattern"
    end

    test "list_active_recurring_shifts_for_location_and_day/3 excludes patterns outside effective range",
         %{location: location} do
      Shelter.create_recurring_shift!(%{
        name: "Expired Pattern",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-03-31],
        location: location.id
      })

      recurring_shifts =
        Shelter.list_active_recurring_shifts_for_location_and_day!(
          location.id,
          4,
          ~D[2026-06-15]
        )

      assert Enum.empty?(recurring_shifts)
    end

    test "list_active_recurring_shifts_for_location_and_day/3 excludes patterns on the end_date",
         %{location: location} do
      Shelter.create_recurring_shift!(%{
        name: "Ends Today Pattern",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        start_date: ~D[2026-04-01],
        end_date: ~D[2026-06-15],
        location: location.id
      })

      recurring_shifts =
        Shelter.list_active_recurring_shifts_for_location_and_day!(
          location.id,
          4,
          ~D[2026-06-15]
        )

      assert Enum.empty?(recurring_shifts)
    end

    test "list_active_recurring_shifts_for_location_and_day/3 includes patterns with open-ended effective range",
         %{location: location} do
      Shelter.create_recurring_shift!(%{
        name: "Open Pattern",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        location: location.id
      })

      recurring_shifts =
        Shelter.list_active_recurring_shifts_for_location_and_day!(
          location.id,
          4,
          ~D[2026-06-15]
        )

      assert length(recurring_shifts) == 1
      assert hd(recurring_shifts).name == "Open Pattern"
    end

    test "list_active_recurring_shifts_for_location_and_day/3 includes patterns with open-ended start_date",
         %{location: location} do
      Shelter.create_recurring_shift!(%{
        name: "Past Pattern",
        day_of_week: 4,
        start_time: ~T[10:00:00],
        end_time: ~T[11:00:00],
        end_date: ~D[2026-12-31],
        location: location.id
      })

      recurring_shifts =
        Shelter.list_active_recurring_shifts_for_location_and_day!(
          location.id,
          4,
          ~D[2026-06-15]
        )

      assert length(recurring_shifts) == 1
      assert hd(recurring_shifts).name == "Past Pattern"
    end

    test "create_recurring_shift/1 fails when end_date equals start_date", %{
      location: location
    } do
      assert {:error, %Ash.Error.Invalid{errors: errors}} =
               Shelter.create_recurring_shift(%{
                 name: "Zero Day",
                 day_of_week: 4,
                 start_time: ~T[10:00:00],
                 end_time: ~T[11:00:00],
                 start_date: ~D[2026-04-15],
                 end_date: ~D[2026-04-15],
                 location: location.id
               })

      assert_invalid_attribute_error(
        errors,
        :end_date,
        "must be after the start date"
      )
    end
  end
end
