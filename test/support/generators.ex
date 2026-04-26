defmodule Doggo.TestGenerators do
  @moduledoc """
  Reusable test generators for Ash resources.
  Uses globally unique values for identity attributes to prevent
  deadlocks in concurrent tests.
  """

  use Ash.Generator

  def location(opts \\ []) do
    changeset_generator(
      Doggo.Shelter.Location,
      :create,
      defaults: [
        name: "Test Shelter #{System.unique_integer([:positive])}"
      ],
      overrides: opts
    )
  end

  def enclosure(opts \\ []) do
    changeset_generator(
      Doggo.Shelter.Enclosure,
      :create,
      defaults: [
        name: "Test Enclosure #{System.unique_integer([:positive])}"
      ],
      overrides: opts
    )
  end

  def scheduled_shift(opts \\ []) do
    unique_int = System.unique_integer([:positive])
    date = Date.add(~D[2026-04-15], unique_int)
    start_time = Time.add(~T[08:00:00], rem(unique_int, 720) * 60, :second)
    end_time = Time.add(start_time, 4 * 60 * 60, :second)

    changeset_generator(
      Doggo.Shelter.ScheduledShift,
      :create,
      defaults: [
        name: "Test Scheduled Shift #{unique_int}",
        date: date,
        start_time: start_time,
        end_time: end_time
      ],
      overrides: opts
    )
  end

  def recurring_shift(opts \\ []) do
    unique_int = System.unique_integer([:positive])
    day_of_week = rem(unique_int, 7) + 1
    start_time = Time.add(~T[08:00:00], rem(unique_int, 720) * 60, :second)
    end_time = Time.add(start_time, 4 * 60 * 60, :second)

    changeset_generator(
      Doggo.Shelter.RecurringShift,
      :create,
      defaults: [
        name: "Test Recurring Shift #{unique_int}",
        day_of_week: day_of_week,
        start_time: start_time,
        end_time: end_time
      ],
      overrides: opts
    )
  end
end
