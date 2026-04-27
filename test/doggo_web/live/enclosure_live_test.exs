defmodule DoggoWeb.EnclosureLiveTest do
  use DoggoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Doggo.TestGenerators

  alias Doggo.Shelter

  describe "Index" do
    setup do
      location = generate(location(name: "Main Shelter"))
      %{location: location}
    end

    test "renders empty state when no enclosures exist", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures")

      assert has_element?(view, "#empty-state")

      assert has_element?(
               view,
               "#empty-state a[href=\"#{~p"/locations/#{location}/enclosures/new"}\"]"
             )
    end

    test "renders enclosures for the location", %{conn: conn, location: location} do
      enclosure = generate(enclosure(name: "Kennel A1", status: :occupied, location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures")

      assert has_element?(view, "#enclosures")
      assert has_element?(view, "#enclosures-#{enclosure.id} a", "Kennel A1")
      assert has_element?(view, "#enclosures-#{enclosure.id}", "Occupied")
      assert has_element?(view, "header", "Main Shelter")
    end

    test "does not render enclosures from another location", %{conn: conn, location: location} do
      other_location = generate(location())
      visible = generate(enclosure(name: "Visible Run", location: location.id))
      hidden = generate(enclosure(name: "Hidden Run", location: other_location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures")

      assert has_element?(view, "#enclosures-#{visible.id}", "Visible Run")
      refute has_element?(view, "#enclosures-#{hidden.id}")
      refute render(view) =~ "Hidden Run"
    end

    test "can navigate to new enclosure form", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures")

      view
      |> element("header a[href=\"#{~p"/locations/#{location}/enclosures/new"}\"]")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/enclosures/new")
    end

    test "can navigate to enclosure details", %{conn: conn, location: location} do
      enclosure = generate(enclosure(name: "Detail Run", location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures")

      view
      |> element(
        "#enclosures-#{enclosure.id} a[href=\"#{~p"/locations/#{location}/enclosures/#{enclosure}"}\"]",
        "Detail Run"
      )
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/enclosures/#{enclosure}")
    end

    test "can delete an enclosure via confirmation modal", %{conn: conn, location: location} do
      enclosure = generate(enclosure(location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures")

      assert has_element?(view, "#enclosures-#{enclosure.id}")

      view
      |> element("#delete-confirm-#{enclosure.id} button[phx-click*=confirm_delete]")
      |> render_click()

      refute has_element?(view, "#enclosures-#{enclosure.id}")
      assert has_element?(view, "#flash-info")
      assert {:error, _error} = Shelter.get_enclosure(enclosure.id)
    end

    test "shows error flash when deleting a missing enclosure", %{conn: conn, location: location} do
      enclosure = generate(enclosure(location: location.id))

      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures")

      :ok = Shelter.destroy_enclosure!(enclosure)

      view
      |> element("#delete-confirm-#{enclosure.id} button[phx-click*=confirm_delete]")
      |> render_click()

      assert has_element?(view, "#flash-error")
    end

    test "redirects when location is missing", %{conn: conn} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/locations", flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{missing_id}/enclosures")
    end
  end

  describe "Show" do
    setup do
      location = generate(location(name: "Show Shelter"))

      enclosure =
        generate(enclosure(name: "Show Run", status: :maintenance, location: location.id))

      %{location: location, enclosure: enclosure}
    end

    test "renders enclosure details", %{conn: conn, location: location, enclosure: enclosure} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/#{enclosure}")

      assert has_element?(view, "h2", "Show Run")
      assert has_element?(view, ".pc-badge", "Maintenance")
      assert has_element?(view, "p", "Show Shelter")
    end

    test "can navigate back to index via back button", %{
      conn: conn,
      location: location,
      enclosure: enclosure
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/#{enclosure}")

      view
      |> element("header a[href=\"#{~p"/locations/#{location}/enclosures"}\"]")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/enclosures")
    end

    test "can navigate to edit form", %{conn: conn, location: location, enclosure: enclosure} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/#{enclosure}")

      view
      |> element(
        "a[href=\"#{~p"/locations/#{location}/enclosures/#{enclosure}/edit?return_to=show"}\"]"
      )
      |> render_click()

      assert_redirected(
        view,
        ~p"/locations/#{location}/enclosures/#{enclosure}/edit?return_to=show"
      )
    end

    test "navigates with flash when enclosure is missing", %{conn: conn, location: location} do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{location}/enclosures/#{missing_id}")

      assert to in ["/locations", ~p"/locations/#{location}/enclosures"]
    end

    test "navigates with flash when enclosure belongs to another location", %{
      conn: conn,
      enclosure: enclosure
    } do
      other_location = generate(location())

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{other_location}/enclosures/#{enclosure}")

      assert to == ~p"/locations/#{other_location}/enclosures"
    end

    test "can delete enclosure from show page via confirmation modal", %{
      conn: conn,
      location: location,
      enclosure: enclosure
    } do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/#{enclosure}")

      view
      |> element("#delete-confirm button[phx-click*=confirm_delete]")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/enclosures")
      assert {:error, _error} = Shelter.get_enclosure(enclosure.id)
    end
  end

  describe "Form - Create" do
    setup do
      location = generate(location(name: "Form Shelter"))
      %{location: location}
    end

    test "renders new enclosure form", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/new")

      assert has_element?(view, "form#enclosure-form")
      assert has_element?(view, "input[name=\"enclosure[name]\"]")
      assert has_element?(view, "select[name=\"enclosure[status]\"]")
      assert has_element?(view, "button[type=\"submit\"]", "Save Enclosure")
    end

    test "creates enclosure with valid data", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/new")

      view
      |> form("#enclosure-form",
        enclosure: %{"name" => "New Run", "status" => "occupied"}
      )
      |> render_submit()

      assert_redirected(view, ~p"/locations/#{location}/enclosures")

      {:ok, index_view, _html} = live(conn, ~p"/locations/#{location}/enclosures")
      assert has_element?(index_view, "#enclosures a", "New Run")
      assert has_element?(index_view, "#enclosures", "Occupied")
    end

    test "shows validation errors with invalid data", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/new")

      view
      |> form("#enclosure-form", enclosure: %{"name" => "", "status" => "available"})
      |> render_submit()

      assert has_element?(view, "form#enclosure-form")
      assert has_element?(view, ".pc-form-field-error")
    end

    test "can cancel and return to index", %{conn: conn, location: location} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/new")

      view
      |> element("form a", "Cancel")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/enclosures")
    end
  end

  describe "Form - Update" do
    setup do
      location = generate(location())
      enclosure = generate(enclosure(name: "Original Run", location: location.id))
      %{location: location, enclosure: enclosure}
    end

    test "renders edit enclosure form", %{conn: conn, location: location, enclosure: enclosure} do
      {:ok, view, _html} = live(conn, ~p"/locations/#{location}/enclosures/#{enclosure}/edit")

      assert has_element?(view, "form#enclosure-form")
      assert has_element?(view, "input[value=\"Original Run\"]")
    end

    test "updates enclosure with valid data", %{
      conn: conn,
      location: location,
      enclosure: enclosure
    } do
      {:ok, view, _html} =
        live(conn, ~p"/locations/#{location}/enclosures/#{enclosure}/edit?return_to=index")

      view
      |> form("#enclosure-form",
        enclosure: %{"name" => "Updated Run", "status" => "out_of_service"}
      )
      |> render_submit()

      assert_redirected(view, ~p"/locations/#{location}/enclosures")

      {:ok, show_view, _html} = live(conn, ~p"/locations/#{location}/enclosures/#{enclosure}")
      assert has_element?(show_view, "h2", "Updated Run")
      assert has_element?(show_view, ".pc-badge", "Out of Service")
    end

    test "can cancel and return to show page", %{
      conn: conn,
      location: location,
      enclosure: enclosure
    } do
      {:ok, view, _html} =
        live(conn, ~p"/locations/#{location}/enclosures/#{enclosure}/edit?return_to=show")

      view
      |> element("form a", "Cancel")
      |> render_click()

      assert_redirected(view, ~p"/locations/#{location}/enclosures/#{enclosure}")
    end

    test "navigates with flash when edited enclosure is missing", %{
      conn: conn,
      location: location
    } do
      missing_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: to, flash: %{"error" => _}}}} =
               live(conn, ~p"/locations/#{location}/enclosures/#{missing_id}/edit")

      assert to in ["/locations", ~p"/locations/#{location}/enclosures"]
    end
  end
end
