defmodule Doggo.DevSeed do
  @moduledoc false

  @primary_location_name "Doggo Dev Shelter"
  @secondary_location_name "Doggo Uptown Annex"

  alias Doggo.Shelter

  @doc "Canonical name of the main seeded location (idempotency + tests)."
  def primary_location_name, do: @primary_location_name

  @doc """
  Inserts dev/demo rows if not already present. Call with `[]` for real runs;
  in tests, pass `today:` to assert predictable scheduled-shift dates.

  ## Options

    * `:force` — when `true`, removes existing dev locations (by canonical names) and
      inserts a fresh seed set. Child records cascade on delete. Use this to refresh
      dates and data without `ecto.reset`.

  Returns `{:ok, :seeded}` when data is written, `{:ok, :skipped}` when already present
  and `force` is not set.
  """
  def run(opts \\ []) do
    today = Keyword.get(opts, :today, Date.utc_today())
    force? = Keyword.get(opts, :force, false)

    cond do
      force? ->
        clear_dev_seed!()
        seed!(today)
        IO.puts("Dev seed data reloaded (force).")
        {:ok, :seeded}

      already_seeded?() ->
        IO.puts("Dev seed already present (" <> @primary_location_name <> "). Skipping.")
        {:ok, :skipped}

      true ->
        seed!(today)
        IO.puts("Dev seed data loaded.")
        {:ok, :seeded}
    end
  end

  defp already_seeded?() do
    @primary_location_name in Enum.map(Shelter.list_active_locations!(), & &1.name)
  end

  defp clear_dev_seed!() do
    names = MapSet.new([@primary_location_name, @secondary_location_name])

    Shelter.list_locations!()
    |> Enum.filter(&MapSet.member?(names, &1.name))
    |> Enum.each(fn location -> :ok = Shelter.destroy_location!(location) end)
  end

  defp seed!(today) do
    primary =
      Shelter.create_location!(%{
        name: @primary_location_name,
        address: "100 Bark Street",
        city: "Portland",
        region: "OR",
        postal_code: "97201",
        country: "USA",
        timezone: "America/Los_Angeles"
      })

    secondary =
      Shelter.create_location!(%{
        name: @secondary_location_name,
        address: "22 Foster Lane",
        city: "Brooklyn",
        region: "NY",
        postal_code: "11201",
        country: "USA",
        timezone: "America/New_York"
      })

    for {name, status} <- [
          {"Run A", :available},
          {"Run B", :occupied},
          {"Whelping 1", :maintenance},
          {"Intake hold", :out_of_service}
        ] do
      Shelter.create_enclosure_at_location!(%{name: name, status: status, location: primary.id})
    end

    for {name, status} <- [
          {"Yard 1", :available},
          {"Quarantine", :available},
          {"Surgery prep", :maintenance}
        ] do
      Shelter.create_enclosure_at_location!(%{
        name: name,
        status: status,
        location: secondary.id
      })
    end

    for attrs <- [
          %{
            name: "Opening shift",
            date: today,
            start_time: ~T[08:00:00],
            end_time: ~T[12:00:00]
          },
          %{
            name: "Afternoon play",
            date: today,
            start_time: ~T[13:00:00],
            end_time: ~T[17:00:00]
          },
          %{
            name: "Focus shift +1d",
            date: Date.add(today, 1),
            start_time: ~T[09:00:00],
            end_time: ~T[13:00:00]
          },
          %{
            name: "Outreach +2d",
            date: Date.add(today, 2),
            start_time: ~T[10:00:00],
            end_time: ~T[14:00:00]
          },
          %{
            name: "Close-out −1d",
            date: Date.add(today, -1),
            start_time: ~T[16:00:00],
            end_time: ~T[19:00:00]
          }
        ] do
      Shelter.create_scheduled_shift_at_location!(Map.put(attrs, :location, primary.id))
    end

    Shelter.create_scheduled_shift_at_location!(%{
      name: "Annex block",
      date: today,
      start_time: ~T[10:00:00],
      end_time: ~T[14:00:00],
      location: secondary.id
    })

    for attrs <- [
          %{
            name: "Monday intake block",
            day_of_week: 1,
            start_time: ~T[09:00:00],
            end_time: ~T[11:00:00]
          },
          %{
            name: "Wednesday socialization",
            day_of_week: 3,
            start_time: ~T[15:00:00],
            end_time: ~T[17:00:00]
          },
          %{
            name: "Saturday public hours",
            day_of_week: 6,
            start_time: ~T[10:00:00],
            end_time: ~T[16:00:00]
          }
        ] do
      Shelter.create_recurring_shift!(Map.put(attrs, :location, primary.id))
    end

    Shelter.create_recurring_shift!(%{
      name: "Friday deep clean",
      day_of_week: 5,
      start_time: ~T[08:00:00],
      end_time: ~T[10:00:00],
      location: secondary.id
    })

    :ok
  end
end
