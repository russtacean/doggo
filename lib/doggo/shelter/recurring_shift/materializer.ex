defmodule Doggo.Shelter.RecurringShift.Materializer do
  @moduledoc """
  Materializes active recurring shift patterns into dated scheduled shifts.
  """

  alias Doggo.Shelter

  @default_horizon_days 30

  @doc """
  Creates missing scheduled shifts for active recurring shifts.

  The materialization window is inclusive of each location's local today and
  exclusive of `horizon_days` after that date.
  """
  def materialize(opts \\ []) do
    with {:ok, as_of} <- normalize_as_of(Keyword.get(opts, :as_of)),
         {:ok, horizon_days} <- normalize_horizon_days(Keyword.get(opts, :horizon_days)) do
      Shelter.list_active_locations!()
      |> Enum.reduce_while({:ok, 0}, fn location, {:ok, created_count} ->
        case materialize_location(location, as_of, horizon_days) do
          {:ok, location_count} -> {:cont, {:ok, created_count + location_count}}
          {:error, error} -> {:halt, {:error, error}}
        end
      end)
    end
  end

  defp normalize_as_of(nil), do: {:ok, DateTime.utc_now()}
  defp normalize_as_of(%DateTime{} = as_of), do: {:ok, as_of}
  defp normalize_as_of(_as_of), do: {:error, "as_of must be a DateTime"}

  defp normalize_horizon_days(nil), do: {:ok, @default_horizon_days}
  defp normalize_horizon_days(days) when is_integer(days) and days > 0, do: {:ok, days}
  defp normalize_horizon_days(_days), do: {:error, "horizon_days must be a positive integer"}

  defp materialize_location(location, as_of, horizon_days) do
    with {:ok, local_as_of} <- DateTime.shift_zone(as_of, location.timezone) do
      start_date = DateTime.to_date(local_as_of)
      end_date = Date.add(start_date, horizon_days)
      existing_keys = existing_scheduled_shift_keys(location.id, start_date, end_date)

      start_date
      |> dates_until(end_date)
      |> Enum.reduce_while({:ok, {0, existing_keys}}, fn date, {:ok, {created_count, keys}} ->
        case materialize_date(location.id, date, keys) do
          {:ok, date_count, updated_keys} ->
            {:cont, {:ok, {created_count + date_count, updated_keys}}}

          {:error, error} ->
            {:halt, {:error, error}}
        end
      end)
      |> case do
        {:ok, {created_count, _keys}} -> {:ok, created_count}
        {:error, error} -> {:error, error}
      end
    end
  end

  defp dates_until(start_date, end_date) do
    Date.range(start_date, Date.add(end_date, -1))
  end

  defp existing_scheduled_shift_keys(location_id, start_date, end_date) do
    location_id
    |> Shelter.list_scheduled_shifts_for_location_between_dates!(start_date, end_date)
    |> MapSet.new(&scheduled_shift_key/1)
  end

  defp materialize_date(location_id, date, existing_keys) do
    location_id
    |> Shelter.list_active_recurring_shifts_for_location_and_day!(Date.day_of_week(date), date)
    |> Enum.reduce_while({:ok, 0, existing_keys}, fn recurring_shift,
                                                     {:ok, created_count, keys} ->
      key = recurring_shift_key(recurring_shift, date)

      if MapSet.member?(keys, key) do
        {:cont, {:ok, created_count, keys}}
      else
        recurring_shift
        |> create_scheduled_shift(location_id, date)
        |> case do
          {:ok, _scheduled_shift} ->
            {:cont, {:ok, created_count + 1, MapSet.put(keys, key)}}

          {:error, error} ->
            {:halt, {:error, error}}
        end
      end
    end)
  end

  defp create_scheduled_shift(recurring_shift, location_id, date) do
    Shelter.create_scheduled_shift_at_location(%{
      name: recurring_shift.name,
      date: date,
      start_time: recurring_shift.start_time,
      end_time: recurring_shift.end_time,
      location: location_id
    })
  end

  defp scheduled_shift_key(scheduled_shift) do
    {scheduled_shift.date, scheduled_shift.start_time, scheduled_shift.end_time,
     scheduled_shift.name}
  end

  defp recurring_shift_key(recurring_shift, date) do
    {date, recurring_shift.start_time, recurring_shift.end_time, recurring_shift.name}
  end
end
