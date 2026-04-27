defmodule DoggoWeb.ScheduledShiftLiveTest do
  use DoggoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Doggo.TestGenerators

  alias Doggo.Shelter

  defp current_week_start, do: Date.beginning_of_week(Date.utc_today(), :monday)
  defp current_week_date(offset), do: Date.add(current_week_start(), offset)
  defp next_week_date(offset), do: Date.add(current_week_start(), 7 + offset)

  describe "Index" do
    setup do
      location = generate(location(name: "Scheduled Test Shelter"))
      %{location: location}
    end

    test "renders empty state when no scheduled shifts exist in the selected week", %{
      conn: conn,
      location: location
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      assert has_element?(view, "#empty-state")
      assert has_element?(view, "#empty-state", "No scheduled shifts yet")
      assert has_element?(view, "input[type=\"date\"][name=\"week[date]\"]")

      assert has_element?(
               view,
               "#empty-state",
               "Add one-off shifts for volunteers at this location."
             )

      assert has_element?(
               view,
               "#empty-state a[href=\"#{~p"/locations/#{location}/scheduled_shifts/new"}\"]"
             )

      assert has_element?(
               view,
               "#desktop-main-nav a[href=\"#{~p"/locations/#{location}/scheduled_shifts"}\"]",
               "Scheduled shifts"
             )
    end

    test "defaults date picker to the current calendar week", %{conn: conn, location: location} do
      today = Date.utc_today()
      week_start = current_week_start()
      week_last = Date.add(week_start, 6)

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      assert has_element?(
               view,
               "input[type=\"date\"][name=\"week[date]\"][value=\"#{Date.to_iso8601(today)}\"]"
             )

      assert render(view) =~
               "Showing #{Date.to_iso8601(week_start)} through #{Date.to_iso8601(week_last)}"
    end

    test "renders scheduled shifts for the current calendar week", %{
      conn: conn,
      location: location
    } do
      shift =
        generate(
          scheduled_shift(
            name: "Morning Walk",
            date: current_week_date(1),
            start_time: ~T[09:00:00],
            end_time: ~T[11:00:00],
            location: location.id
          )
        )

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      assert has_element?(view, "#scheduled_shifts")
      assert has_element?(view, "#scheduled_shifts-#{shift.id} a", "Morning Walk")
      assert has_element?(view, "#scheduled_shifts-#{shift.id}", "09:00-11:00")
      assert has_element?(view, "#scheduled_shifts-#{shift.id}", Date.to_iso8601(shift.date))
    end

    test "sorts scheduled shifts by date and time", %{conn: conn, location: location} do
      later =
        generate(
          scheduled_shift(
            name: "Later Walk",
            date: current_week_date(2),
            start_time: ~T[13:00:00],
            end_time: ~T[14:00:00],
            location: location.id
          )
        )

      earlier =
        generate(
          scheduled_shift(
            name: "Earlier Walk",
            date: current_week_date(1),
            start_time: ~T[09:00:00],
            end_time: ~T[10:00:00],
            location: location.id
          )
        )

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")
      html = render(view)

      assert has_element?(view, "#scheduled_shifts-#{earlier.id}", "Earlier Walk")
      assert has_element?(view, "#scheduled_shifts-#{later.id}", "Later Walk")
      assert_before(html, "Earlier Walk", "Later Walk")
    end

    test "does not render shifts outside the selected week or from another location", %{
      conn: conn,
      location: location
    } do
      other_location = generate(location())

      visible =
        generate(scheduled_shift(name: "Here", date: current_week_date(0), location: location.id))

      other_location_shift =
        generate(
          scheduled_shift(
            name: "There",
            date: current_week_date(0),
            location: other_location.id
          )
        )

      next_week =
        generate(
          scheduled_shift(
            name: "Next Week",
            date: next_week_date(0),
            location: location.id
          )
        )

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      assert has_element?(view, "#scheduled_shifts-#{visible.id}", "Here")
      refute has_element?(view, "#scheduled_shifts-#{other_location_shift.id}")
      refute has_element?(view, "#scheduled_shifts-#{next_week.id}")
      refute render(view) =~ "There"
      refute render(view) =~ "Next Week"
    end

    test "renders scheduled shifts for the week containing the date query param", %{
      conn: conn,
      location: location
    } do
      selected_date = next_week_date(2)

      current_week_shift =
        generate(
          scheduled_shift(
            name: "This Week",
            date: current_week_date(2),
            location: location.id
          )
        )

      selected_week_shift =
        generate(
          scheduled_shift(
            name: "Selected Week",
            date: next_week_date(3),
            location: location.id
          )
        )

      {:ok, view, _html} =
        live(
          conn,
          ~p"/locations/#{location}/scheduled_shifts?date=#{Date.to_iso8601(selected_date)}"
        )

      assert has_element?(view, "#scheduled_shifts-#{selected_week_shift.id}", "Selected Week")
      refute has_element?(view, "#scheduled_shifts-#{current_week_shift.id}")
      refute render(view) =~ "This Week"
    end

    test "date picker changes the selected week", %{conn: conn, location: location} do
      current_week_shift =
        generate(
          scheduled_shift(
            name: "Current Week",
            date: current_week_date(2),
            location: location.id
          )
        )

      selected_week_shift =
        generate(
          scheduled_shift(
            name: "Picked Week",
            date: next_week_date(3),
            location: location.id
          )
        )

      selected_date = next_week_date(2)
      selected_date_iso = Date.to_iso8601(selected_date)

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      assert has_element?(view, "#scheduled_shifts-#{current_week_shift.id}", "Current Week")

      view
      |> element("#scheduled-shift-week-form")
      |> render_change(%{"week" => %{"date" => selected_date_iso}})

      assert_patch(view, ~p"/locations/#{location}/scheduled_shifts?date=#{selected_date_iso}")
      assert has_element?(view, "#scheduled_shifts-#{selected_week_shift.id}", "Picked Week")
      refute has_element?(view, "#scheduled_shifts-#{current_week_shift.id}")
    end

    test "can navigate to new scheduled shift form", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      view
      |> element("header a[href=\"#{~p"/locations/#{location}/scheduled_shifts/new"}\"]")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/scheduled_shifts/new")
    end

    test "can navigate to show page", %{conn: conn, location: location} do
      shift =
        generate(
          scheduled_shift(name: "Show Me", date: current_week_date(1), location: location.id)
        )

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      view
      |> element(
        "#scheduled_shifts-#{shift.id} a[href=\"#{~p"/locations/#{location}/scheduled_shifts/#{shift}"}\"]",
        "Show Me"
      )
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/scheduled_shifts/#{shift}")
    end

    test "can delete a scheduled shift via confirmation modal", %{conn: conn, location: location} do
      shift = generate(scheduled_shift(date: current_week_date(1), location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      assert has_element?(view, "#scheduled_shifts-#{shift.id}")

      view
      |> element("#delete-confirm-#{shift.id} button[phx-click*=confirm_delete]")
      |> render_click()

      refute has_element?(view, "#scheduled_shifts-#{shift.id}")
      assert has_element?(view, "#flash-info")
      assert {:error, _error} = Shelter.get_scheduled_shift(shift.id)
    end

    test "shows error flash when deleting a missing scheduled shift", %{
      conn: conn,
      location: location
    } do
      shift = generate(scheduled_shift(date: current_week_date(1), location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")

      :ok = Shelter.destroy_scheduled_shift!(shift)

      view
      |> element("#delete-confirm-#{shift.id} button[phx-click*=confirm_delete]")
      |> render_click()

      assert has_element?(view, "#flash-error")
    end

    test "redirects when location is missing", %{conn: conn} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/locations", flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{missing_id}/scheduled_shifts")
    end
  end

  describe "Show" do
    setup do
      location = generate(location(name: "Show Shift Shelter"))

      shift =
        generate(
          scheduled_shift(
            name: "Display Shift",
            date: ~D[2026-05-01],
            start_time: ~T[10:00:00],
            end_time: ~T[12:00:00],
            location: location.id
          )
        )

      %{location: location, scheduled_shift: shift}
    end

    test "renders scheduled shift details", %{
      conn: conn,
      location: location,
      scheduled_shift: shift
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/#{shift}")

      assert has_element?(view, "h2", "Display Shift")
      assert has_element?(view, "p", "Show Shift Shelter")
      assert has_element?(view, "p", "2026-05-01")
      assert has_element?(view, "p", "10:00-12:00")
    end

    test "can navigate to edit form", %{
      conn: conn,
      location: location,
      scheduled_shift: shift
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/#{shift}")

      view
      |> element(
        "a[href=\"#{~p"/locations/#{location}/scheduled_shifts/#{shift}/edit?return_to=show"}\"]"
      )
      |> render_click()

      assert_redirected(
        view,
        ~p"/locations/#{location}/scheduled_shifts/#{shift}/edit?return_to=show"
      )
    end

    test "navigates with flash when scheduled shift is missing", %{
      conn: conn,
      location: location
    } do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{location}/scheduled_shifts/#{missing_id}")

      assert to == ~p"/locations/#{location}/scheduled_shifts"
    end

    test "navigates with flash when shift belongs to another location", %{
      conn: conn,
      scheduled_shift: shift
    } do
      other_location = generate(location())

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{other_location}/scheduled_shifts/#{shift}")

      assert to == ~p"/locations/#{other_location}/scheduled_shifts"
    end

    test "can delete from show page via confirmation modal", %{
      conn: conn,
      location: location,
      scheduled_shift: shift
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/#{shift}")

      view
      |> element("#delete-confirm button[phx-click*=confirm_delete]")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/scheduled_shifts")
      assert {:error, _error} = Shelter.get_scheduled_shift(shift.id)
    end
  end

  describe "Form - Create" do
    setup do
      location = generate(location(name: "Form Scheduled Shelter"))
      %{location: location}
    end

    test "renders new form", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/new")

      assert has_element?(view, "form#scheduled-shift-form")
      assert has_element?(view, "input[name=\"scheduled_shift[name]\"]")
      assert has_element?(view, "input[name=\"scheduled_shift[date]\"]")
      assert has_element?(view, "button[type=\"submit\"]", "Save scheduled shift")
    end

    test "creates scheduled shift with valid data", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/new")

      view
      |> form("#scheduled-shift-form",
        scheduled_shift: %{
          "name" => "New Shift",
          "date" => Date.to_iso8601(Date.add(Date.utc_today(), 1)),
          "start_time" => "10:00",
          "end_time" => "11:00"
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/locations/#{location}/scheduled_shifts")

      {:ok, index_view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts")
      assert has_element?(index_view, "#scheduled_shifts a", "New Shift")
    end

    test "shows validation errors with invalid data", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/new")

      view
      |> form("#scheduled-shift-form",
        scheduled_shift: %{
          "name" => "",
          "date" => "",
          "start_time" => "11:00",
          "end_time" => "10:00"
        }
      )
      |> render_submit()

      assert has_element?(view, "form#scheduled-shift-form")
      assert has_element?(view, ".pc-form-field-error")
    end

    test "can cancel to index", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/new")

      view
      |> element("form a", "Cancel")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/scheduled_shifts")
    end
  end

  describe "Form - Update" do
    setup do
      location = generate(location())

      shift =
        generate(
          scheduled_shift(
            name: "Before",
            date: Date.add(Date.utc_today(), 1),
            location: location.id
          )
        )

      %{location: location, scheduled_shift: shift}
    end

    test "renders edit form", %{conn: conn, location: location, scheduled_shift: shift} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/#{shift}/edit")

      assert has_element?(view, "form#scheduled-shift-form")
      assert has_element?(view, "input[value=\"Before\"]")
    end

    test "updates with valid data", %{
      conn: conn,
      location: location,
      scheduled_shift: shift
    } do
      {:ok, view, _html} =
        live(conn, ~p"/locations/#{location}/scheduled_shifts/#{shift}/edit?return_to=index")

      view
      |> form("#scheduled-shift-form",
        scheduled_shift: %{
          "name" => "After",
          "date" => Date.to_iso8601(Date.add(Date.utc_today(), 2)),
          "start_time" => "10:00",
          "end_time" => "12:00"
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/locations/#{location}/scheduled_shifts")

      {:ok, show_view, _html} = live(conn, ~p"/locations/#{location}/scheduled_shifts/#{shift}")
      assert has_element?(show_view, "h2", "After")
    end

    test "can cancel to show", %{conn: conn, location: location, scheduled_shift: shift} do
      {:ok, view, _html} =
        live(conn, ~p"/locations/#{location}/scheduled_shifts/#{shift}/edit?return_to=show")

      view
      |> element("form a", "Cancel")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/scheduled_shifts/#{shift}")
    end

    test "navigates with flash when edited shift is missing", %{conn: conn, location: location} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{location}/scheduled_shifts/#{missing_id}/edit")

      assert to == ~p"/locations/#{location}/scheduled_shifts"
    end
  end

  defp assert_before(html, earlier, later) do
    assert :binary.match(html, earlier) < :binary.match(html, later)
  end
end
