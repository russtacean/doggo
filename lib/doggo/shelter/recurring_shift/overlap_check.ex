defmodule Doggo.Shelter.RecurringShift.OverlapCheck do
  @moduledoc """
  Prevents recurring shift patterns from overlapping for the same location, day, and name.
  """

  use Ash.Resource.Change

  require Ash.Query

  alias Doggo.Shelter.RecurringShift

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.before_action(changeset, &check_overlap/1)
  end

  defp check_overlap(changeset) do
    attrs = %{
      location_id:
        Ash.Changeset.get_attribute(changeset, :location_id) ||
          Ash.Changeset.get_argument(changeset, :location),
      day_of_week: Ash.Changeset.get_attribute(changeset, :day_of_week),
      name: Ash.Changeset.get_attribute(changeset, :name),
      start_time: Ash.Changeset.get_attribute(changeset, :start_time),
      end_time: Ash.Changeset.get_attribute(changeset, :end_time),
      start_date: Ash.Changeset.get_attribute(changeset, :start_date),
      end_date: Ash.Changeset.get_attribute(changeset, :end_date)
    }

    if required_values_present?(attrs) and overlapping_shift?(changeset, attrs) do
      Ash.Changeset.add_error(
        changeset,
        field: :name,
        message: "overlaps with an existing recurring shift for the same location, day, and name"
      )
    else
      changeset
    end
  end

  defp required_values_present?(attrs) do
    Enum.all?(
      [attrs.location_id, attrs.day_of_week, attrs.name, attrs.start_time, attrs.end_time],
      &(!is_nil(&1))
    )
  end

  defp overlapping_shift?(changeset, attrs) do
    RecurringShift
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(
      location_id == ^attrs.location_id and day_of_week == ^attrs.day_of_week and
        name == ^attrs.name
    )
    |> Ash.read!(authorize?: false)
    |> Enum.any?(&overlaps?(changeset, attrs, &1))
  end

  defp overlaps?(changeset, attrs, other) do
    other.id != changeset.data.id and
      time_overlaps?(attrs.start_time, attrs.end_time, other.start_time, other.end_time) and
      date_overlaps?(
        attrs.start_date,
        attrs.end_date,
        other.start_date,
        other.end_date
      )
  end

  defp time_overlaps?(start_time, end_time, other_start_time, other_end_time) do
    Time.compare(start_time, other_end_time) == :lt and
      Time.compare(end_time, other_start_time) == :gt
  end

  defp date_overlaps?(
         start_date,
         end_date,
         other_start_date,
         other_end_date
       ) do
    not (date_lte?(end_date, other_start_date) or
           date_lte?(other_end_date, start_date))
  end

  defp date_lte?(nil, _date), do: false
  defp date_lte?(_date, nil), do: false
  defp date_lte?(date, other_date), do: Date.compare(date, other_date) in [:lt, :eq]
end
