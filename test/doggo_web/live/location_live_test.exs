defmodule DoggoWeb.LocationLiveTest do
  use DoggoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Doggo.TestGenerators

  alias Doggo.Shelter

  describe "Index" do
    test "renders empty state when no locations exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/locations")

      assert has_element?(view, "#empty-state")
      assert has_element?(view, "#empty-state a[href=\"#{~p"/locations/new"}\"]")
    end

    test "renders locations list", %{conn: conn} do
      location = generate(location(name: "Main Shelter", city: "Portland", region: "OR"))

      {:ok, view, _html} = live(conn, ~p"/locations")

      assert has_element?(view, "#locations")
      assert has_element?(view, "#locations-#{location.id} a", "Main Shelter")
      assert has_element?(view, "span", "Portland, OR")
      assert has_element?(view, ".pc-badge", location.timezone)
    end

    test "does not render archived locations", %{conn: conn} do
      active = generate(location(name: "Active Shelter"))
      archived = generate(location(name: "Archived Shelter"))
      Shelter.update_location!(archived, %{archived: true})

      {:ok, view, _html} = live(conn, ~p"/locations")

      assert has_element?(view, "#locations-#{active.id}", "Active Shelter")
      refute has_element?(view, "#locations-#{archived.id}")
      refute render(view) =~ "Archived Shelter"
    end

    test "can navigate to new location form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/locations")

      view
      |> element("header a[href=\"#{~p"/locations/new"}\"]")
      |> render_click()

      assert_redirected(view, ~p"/locations/new")
    end

    test "can navigate to location details", %{conn: conn} do
      location = generate(location(name: "Detail Test Shelter"))

      {:ok, view, _html} = live(conn, ~p"/locations")

      view
      |> element(
        "#locations-#{location.id} a[href=\"#{~p"/locations/#{location.id}"}\"]",
        "Detail Test Shelter"
      )
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location.id}")
    end

    test "can delete a location via confirmation modal", %{conn: conn} do
      location = generate(location(name: "Delete Test Shelter"))

      {:ok, view, _html} = live(conn, ~p"/locations")

      assert has_element?(view, "#locations-#{location.id}")

      view
      |> element("#delete-confirm-#{location.id} button[phx-click*=confirm_delete]")
      |> render_click()

      refute has_element?(view, "#locations-#{location.id}")
      assert has_element?(view, "#flash-info")
    end

    test "delete modal warns about cascading deletes", %{conn: conn} do
      location = generate(location())

      {:ok, view, _html} = live(conn, ~p"/locations")

      assert has_element?(view, "#delete-confirm-#{location.id}")
      assert has_element?(view, "#delete-confirm-#{location.id}", "enclosures")
      assert has_element?(view, "#delete-confirm-#{location.id}", "scheduled shifts")
      assert has_element?(view, "#delete-confirm-#{location.id}", "recurring shifts")
    end

    test "does not delete a location until confirmed", %{conn: conn} do
      location = generate(location())

      {:ok, view, _html} = live(conn, ~p"/locations")

      assert has_element?(view, "#delete-confirm-#{location.id} button", "Cancel")
      assert has_element?(view, "#locations-#{location.id}")
    end

    test "deleting a location cascades to enclosures", %{conn: conn} do
      location = generate(location())
      enclosure = generate(enclosure(location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations")

      view
      |> element("#delete-confirm-#{location.id} button[phx-click*=confirm_delete]")
      |> render_click()

      assert {:error, _} = Shelter.get_enclosure(enclosure.id)
    end

    test "deleting a location cascades to recurring shifts", %{conn: conn} do
      location = generate(location())
      recurring_shift = generate(recurring_shift(location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations")

      view
      |> element("#delete-confirm-#{location.id} button[phx-click*=confirm_delete]")
      |> render_click()

      assert {:error, _} = Shelter.get_recurring_shift(recurring_shift.id)
    end

    test "shows error flash when deleting a missing location", %{conn: conn} do
      location = generate(location())

      {:ok, view, _html} = live(conn, ~p"/locations")

      :ok = Shelter.destroy_location!(location)

      view
      |> element("#delete-confirm-#{location.id} button[phx-click*=confirm_delete]")
      |> render_click()

      assert has_element?(view, "#flash-error")
    end
  end

  describe "Show" do
    test "renders location details", %{conn: conn} do
      location =
        generate(
          location(
            name: "Show Test Shelter",
            address: "123 Main St",
            city: "Portland",
            region: "OR"
          )
        )

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}")

      assert has_element?(view, "h2", "Show Test Shelter")
      assert has_element?(view, "p", "123 Main St")
      assert has_element?(view, "p", "Portland")
      assert has_element?(view, "p", "OR")
    end

    test "can navigate back to index via back button", %{conn: conn} do
      location = generate(location())

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}")

      view
      |> element("header a[href=\"#{~p"/locations"}\"]")
      |> render_click()

      assert_redirected(view, ~p"/locations")
    end

    test "can navigate to edit form", %{conn: conn} do
      location = generate(location())

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}")

      view
      |> element("a[href=\"#{~p"/locations/#{location.id}/edit?return_to=show"}\"]")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location.id}/edit?return_to=show")
    end

    test "navigates with flash when location is missing", %{conn: conn} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/locations", flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{missing_id}")
    end

    test "can delete location from show page via confirmation modal", %{conn: conn} do
      location = generate(location(name: "Delete From Show"))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}")

      view
      |> element("#delete-confirm button[phx-click*=confirm_delete]")
      |> render_click()

      assert_redirected(view, ~p"/locations")

      {:ok, index_view, _html} = live(conn, ~p"/locations")
      refute has_element?(index_view, "#locations-#{location.id}")
    end

    test "delete modal warns about cascading deletes", %{conn: conn} do
      location = generate(location())

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}")

      assert has_element?(view, "#delete-confirm")
      assert has_element?(view, "#delete-confirm", "enclosures")
      assert has_element?(view, "#delete-confirm", "scheduled shifts")
      assert has_element?(view, "#delete-confirm", "recurring shifts")
    end

    test "deleting a location cascades to scheduled_shifts", %{conn: conn} do
      location = generate(location())
      scheduled_shift = generate(scheduled_shift(location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}")

      view
      |> element("#delete-confirm button[phx-click*=confirm_delete]")
      |> render_click()

      assert_redirected(view, ~p"/locations")
      assert {:error, _} = Shelter.get_scheduled_shift(scheduled_shift.id)
    end

    test "navigates with flash when deleting a missing location from show", %{conn: conn} do
      location = generate(location())

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}")

      :ok = Shelter.destroy_location!(location)

      view
      |> element("#delete-confirm button[phx-click*=confirm_delete]")
      |> render_click()

      flash = assert_redirected(view, ~p"/locations")
      assert %{"error" => _} = flash
    end
  end

  describe "Form - Create" do
    test "renders new location form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/locations/new")

      assert has_element?(view, "form#location-form")
      assert has_element?(view, "input[name=\"location[name]\"]")
      assert has_element?(view, "button[type=\"submit\"]", "Save Location")
    end

    test "shows contextual subtitle for new location", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/locations/new")

      assert html =~ "Add a new shelter location"
    end

    test "creates location with valid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/locations/new")

      attrs = %{
        "name" => "New Test Shelter",
        "address" => "456 Oak Ave",
        "city" => "Seattle",
        "region" => "WA",
        "postal_code" => "98101",
        "country" => "US",
        "timezone" => "America/Los_Angeles"
      }

      view
      |> form("#location-form", location: attrs)
      |> render_submit()

      assert_redirected(view, ~p"/locations")

      {:ok, index_view, _html} = live(conn, ~p"/locations")
      assert has_element?(index_view, "#locations a", "New Test Shelter")
    end

    test "shows validation errors with invalid data", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/locations/new")

      view
      |> form("#location-form", location: %{"name" => ""})
      |> render_submit()

      assert has_element?(view, "form#location-form")
      assert has_element?(view, ".pc-form-field-error")
    end

    test "shows inline errors on validate", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/locations/new")

      view
      |> form("#location-form", location: %{"name" => ""})
      |> render_change()

      assert has_element?(view, "form#location-form")
    end

    test "can cancel and return to index", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/locations/new")

      view
      |> element("form a", "Cancel")
      |> render_click()

      assert_redirected(view, ~p"/locations")
    end
  end

  describe "Form - Update" do
    test "renders edit location form", %{conn: conn} do
      location = generate(location(name: "Edit Test Shelter"))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}/edit")

      assert has_element?(view, "form#location-form")
      assert has_element?(view, "input[value=\"Edit Test Shelter\"]")
    end

    test "shows contextual subtitle for edit location", %{conn: conn} do
      location = generate(location())

      {:ok, _view, html} = live(conn, ~p"/locations/#{location.id}/edit")

      assert html =~ "Edit location details"
    end

    test "navigates with flash when edited location is missing", %{conn: conn} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/locations", flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{missing_id}/edit")
    end

    test "updates location with valid data", %{conn: conn} do
      location = generate(location(name: "Original Name"))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}/edit?return_to=index")

      view
      |> form("#location-form", location: %{"name" => "Updated Name"})
      |> render_submit()

      assert_redirected(view, ~p"/locations")

      {:ok, show_view, _html} = live(conn, ~p"/locations/#{location.id}")
      assert has_element?(show_view, "h2", "Updated Name")
    end

    test "can cancel and return to show page", %{conn: conn} do
      location = generate(location())

      {:ok, view, _html} = live(conn, ~p"/locations/#{location.id}/edit?return_to=show")

      view
      |> element("form a", "Cancel")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location.id}")
    end
  end
end
