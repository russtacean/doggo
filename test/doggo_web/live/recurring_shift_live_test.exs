defmodule DoggoWeb.RecurringShiftLiveTest do
  use DoggoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Doggo.TestGenerators

  alias Doggo.Shelter

  describe "Index" do
    setup do
      location = generate(location(name: "Recurring Test Shelter"))
      %{location: location}
    end

    test "renders empty state when no recurring shifts exist", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")

      assert has_element?(view, "#empty-state")
      assert has_element?(view, "#empty-state", "No weekly shift patterns yet")

      assert has_element?(
               view,
               "#empty-state",
               "Add the regular shifts volunteers can expect each week."
             )

      assert has_element?(
               view,
               "#empty-state a[href=\"#{~p"/locations/#{location}/recurring_shifts/new"}\"]"
             )
    end

    test "renders recurring shifts for the location", %{conn: conn, location: location} do
      rs =
        generate(
          recurring_shift(
            name: "Weekly Walk",
            day_of_week: 3,
            start_date: ~D[2026-04-01],
            end_date: ~D[2026-05-01],
            location: location.id
          )
        )

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")

      assert has_element?(view, "#recurring_shifts")
      assert has_element?(view, "#weekday-3", "Wednesday")
      assert has_element?(view, "#recurring_shifts-#{rs.id} a", "Weekly Walk")

      assert has_element?(
               view,
               "#recurring_shifts-#{rs.id}",
               "Active 2026-04-01 until 2026-05-01"
             )

      assert has_element?(view, "#recurring_shifts-#{rs.id}", "end date not included")
      refute has_element?(view, "#weekday-1")
      refute render(view) =~ "No weekly patterns for"
    end

    test "groups recurring shifts by weekday and sorts within each day", %{
      conn: conn,
      location: location
    } do
      afternoon =
        generate(
          recurring_shift(
            name: "Afternoon Walk",
            day_of_week: 1,
            start_time: ~T[14:00:00],
            end_time: ~T[16:00:00],
            location: location.id
          )
        )

      morning =
        generate(
          recurring_shift(
            name: "Morning Walk",
            day_of_week: 1,
            start_time: ~T[09:00:00],
            end_time: ~T[11:00:00],
            location: location.id
          )
        )

      generate(
        recurring_shift(
          name: "Tuesday Cleaning",
          day_of_week: 2,
          start_time: ~T[10:00:00],
          end_time: ~T[12:00:00],
          location: location.id
        )
      )

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")
      html = render(view)

      assert has_element?(view, "#weekday-1", "Monday")
      assert has_element?(view, "#weekday-2", "Tuesday")
      assert has_element?(view, "#weekday-1 #recurring_shifts-#{morning.id}", "Morning Walk")
      assert has_element?(view, "#weekday-1 #recurring_shifts-#{afternoon.id}", "Afternoon Walk")
      assert_before(html, "Morning Walk", "Afternoon Walk")
      assert_before(html, "Monday", "Tuesday")
    end

    test "renders direct edit affordance for each weekly pattern", %{
      conn: conn,
      location: location
    } do
      rs = generate(recurring_shift(name: "Edit Me", location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")

      assert has_element?(
               view,
               "#recurring_shifts-#{rs.id} a[href=\"#{~p"/locations/#{location}/recurring_shifts/#{rs}/edit"}\"]"
             )
    end

    test "does not render recurring shifts from another location", %{
      conn: conn,
      location: location
    } do
      other_location = generate(location())
      visible = generate(recurring_shift(name: "Here", location: location.id))
      hidden = generate(recurring_shift(name: "There", location: other_location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")

      assert has_element?(view, "#recurring_shifts-#{visible.id}", "Here")
      refute has_element?(view, "#recurring_shifts-#{hidden.id}")
      refute render(view) =~ "There"
    end

    test "can navigate to new recurring shift form", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")

      view
      |> element("header a[href=\"#{~p"/locations/#{location}/recurring_shifts/new"}\"]")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/recurring_shifts/new")
    end

    test "can navigate to show page", %{conn: conn, location: location} do
      rs = generate(recurring_shift(name: "Show Me", location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")

      view
      |> element(
        "#recurring_shifts-#{rs.id} a[href=\"#{~p"/locations/#{location}/recurring_shifts/#{rs}"}\"]",
        "Show Me"
      )
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/recurring_shifts/#{rs}")
    end

    test "can delete a recurring shift via confirmation modal", %{conn: conn, location: location} do
      rs = generate(recurring_shift(location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")

      assert has_element?(view, "#recurring_shifts-#{rs.id}")

      view
      |> element("#delete-confirm-#{rs.id} button[phx-click*=confirm_delete]")
      |> render_click()

      refute has_element?(view, "#recurring_shifts-#{rs.id}")
      assert has_element?(view, "#flash-info")
      assert {:error, _error} = Shelter.get_recurring_shift(rs.id)
    end

    test "shows error flash when deleting a missing recurring shift", %{
      conn: conn,
      location: location
    } do
      rs = generate(recurring_shift(location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")

      :ok = Shelter.destroy_recurring_shift!(rs)

      view
      |> element("#delete-confirm-#{rs.id} button[phx-click*=confirm_delete]")
      |> render_click()

      assert has_element?(view, "#flash-error")
    end

    test "redirects when location is missing", %{conn: conn} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/locations", flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{missing_id}/recurring_shifts")
    end
  end

  describe "Show" do
    setup do
      location = generate(location(name: "Show Shift Shelter"))

      rs =
        generate(recurring_shift(name: "Display Pattern", day_of_week: 4, location: location.id))

      %{location: location, recurring_shift: rs}
    end

    test "renders recurring shift details", %{
      conn: conn,
      location: location,
      recurring_shift: rs
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts/#{rs}")

      assert has_element?(view, "h2", "Display Pattern")
      assert has_element?(view, "p", "Show Shift Shelter")
    end

    test "can navigate to edit form", %{
      conn: conn,
      location: location,
      recurring_shift: rs
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts/#{rs}")

      view
      |> element(
        "a[href=\"#{~p"/locations/#{location}/recurring_shifts/#{rs}/edit?return_to=show"}\"]"
      )
      |> render_click()

      assert_redirected(
        view,
        ~p"/locations/#{location}/recurring_shifts/#{rs}/edit?return_to=show"
      )
    end

    test "navigates with flash when recurring shift is missing", %{conn: conn, location: location} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{location}/recurring_shifts/#{missing_id}")

      assert to == ~p"/locations/#{location}/recurring_shifts"
    end

    test "navigates with flash when shift belongs to another location", %{
      conn: conn,
      recurring_shift: rs
    } do
      other_location = generate(location())

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{other_location}/recurring_shifts/#{rs}")

      assert to == ~p"/locations/#{other_location}/recurring_shifts"
    end

    test "can delete from show page via confirmation modal", %{
      conn: conn,
      location: location,
      recurring_shift: rs
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts/#{rs}")

      view
      |> element("#delete-confirm button[phx-click*=confirm_delete]")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/recurring_shifts")
      assert {:error, _error} = Shelter.get_recurring_shift(rs.id)
    end
  end

  describe "Form - Create" do
    setup do
      location = generate(location(name: "Form Recurring Shelter"))
      %{location: location}
    end

    test "renders new form", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts/new")

      assert has_element?(view, "form#recurring-shift-form")
      assert has_element?(view, "input[name=\"recurring_shift[name]\"]")
      assert render(view) =~ "This pattern repeats every week on the selected day and time."

      assert render(view) =~
               "Optional dates limit when this pattern is active. The end date is not included."

      assert has_element?(view, "button[type=\"submit\"]", "Save weekly pattern")
    end

    test "creates recurring shift with valid data", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts/new")

      view
      |> form("#recurring-shift-form",
        recurring_shift: %{
          "name" => "New Pattern",
          "day_of_week" => "1",
          "start_time" => "10:00",
          "end_time" => "11:00"
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/locations/#{location}/recurring_shifts")

      {:ok, index_view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts")
      assert has_element?(index_view, "#recurring_shifts a", "New Pattern")
    end

    test "can cancel to index", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts/new")

      view
      |> element("form a", "Cancel")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/recurring_shifts")
    end
  end

  describe "Form - Update" do
    setup do
      location = generate(location())
      rs = generate(recurring_shift(name: "Before", day_of_week: 2, location: location.id))
      %{location: location, recurring_shift: rs}
    end

    test "renders edit form", %{conn: conn, location: location, recurring_shift: rs} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts/#{rs}/edit")

      assert has_element?(view, "form#recurring-shift-form")
      assert has_element?(view, "input[value=\"Before\"]")
    end

    test "updates with valid data", %{
      conn: conn,
      location: location,
      recurring_shift: rs
    } do
      {:ok, view, _html} =
        live(conn, ~p"/locations/#{location}/recurring_shifts/#{rs}/edit?return_to=index")

      view
      |> form("#recurring-shift-form",
        recurring_shift: %{
          "name" => "After",
          "day_of_week" => "2",
          "start_time" => "10:00",
          "end_time" => "12:00"
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/locations/#{location}/recurring_shifts")

      {:ok, show_view, _html} = live(conn, ~p"/locations/#{location}/recurring_shifts/#{rs}")
      assert has_element?(show_view, "h2", "After")
    end

    test "can cancel to show", %{conn: conn, location: location, recurring_shift: rs} do
      {:ok, view, _html} =
        live(conn, ~p"/locations/#{location}/recurring_shifts/#{rs}/edit?return_to=show")

      view
      |> element("form a", "Cancel")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/recurring_shifts/#{rs}")
    end

    test "navigates with flash when edited shift is missing", %{conn: conn, location: location} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{location}/recurring_shifts/#{missing_id}/edit")

      assert to == ~p"/locations/#{location}/recurring_shifts"
    end
  end

  defp assert_before(html, earlier, later) do
    assert :binary.match(html, earlier) < :binary.match(html, later)
  end
end
