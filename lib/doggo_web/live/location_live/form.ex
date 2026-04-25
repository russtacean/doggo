defmodule DoggoWeb.LocationLive.Form do
  use DoggoWeb, :live_view

  alias Doggo.Shelter

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        <div class="flex items-center gap-inline">
          <.back_button to={return_path(@return_to, @location)} />
          <span class="text-text-primary dark:text-text-primary-dark">{@page_title}</span>
        </div>
        <:subtitle>
          {if is_nil(@location), do: "Add a new shelter location", else: "Edit location details"}
        </:subtitle>
      </.header>

      <div class="bg-surface dark:bg-surface-dark border border-border-default dark:border-border-default-dark rounded-lg shadow-sm p-inset-card-lg max-w-2xl">
        <.form
          for={@form}
          id="location-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-stack-form"
        >
          <.field
            type="text"
            label="Name"
            field={@form[:name]}
            required
            placeholder="e.g., Main Street Shelter"
          />

          <.field
            type="text"
            label="Street Address"
            field={@form[:address]}
            placeholder="e.g., 123 Main Street"
          />

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-field">
            <.field
              type="text"
              label="City"
              field={@form[:city]}
              placeholder="e.g., Portland"
            />

            <.field
              type="text"
              label="Region/State"
              field={@form[:region]}
              placeholder="e.g., Oregon"
            />
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-field">
            <.field
              type="text"
              label="Postal Code"
              field={@form[:postal_code]}
              placeholder="e.g., 97201"
            />

            <.field
              type="text"
              label="Country"
              field={@form[:country]}
              placeholder="e.g., US"
            />
          </div>

          <.field
            type="text"
            label="Timezone"
            field={@form[:timezone]}
            placeholder="e.g., America/New_York"
          />

          <div class="flex items-center justify-between pt-separator-comfort border-t border-border-divider dark:border-border-divider-dark">
            <.button
              color="gray"
              variant="ghost"
              to={return_path(@return_to, @location)}
              link_type="live_redirect"
            >
              Cancel
            </.button>
            <.button type="submit" color="primary" phx-disable-with="Saving...">
              <.icon name="hero-check" class="w-4 h-4 mr-1" /> Save Location
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    return_to = return_to(params["return_to"])

    case fetch_location(params) do
      {:ok, location} -> {:ok, assign_location_form(socket, location, return_to)}
      {:error, _error} -> {:ok, location_not_found(socket)}
    end
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"location" => location_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, location_params))}
  end

  def handle_event("save", %{"location" => location_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: location_params) do
      {:ok, location} ->
        action = if is_nil(socket.assigns.location), do: "created", else: "updated"

        socket =
          socket
          |> put_flash(:info, "Location #{action} successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, location))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(%{assigns: %{location: location}} = socket) do
    form =
      if location do
        Shelter.form_to_update_location(location, as: "location")
      else
        Shelter.form_to_create_location(as: "location")
      end

    assign(socket, form: to_form(form))
  end

  defp assign_location_form(socket, location, return_to) do
    page_title = if is_nil(location), do: "New Location", else: "Edit Location"

    socket
    |> assign(:return_to, return_to)
    |> assign(location: location)
    |> assign(:page_title, page_title)
    |> assign_form()
  end

  defp location_not_found(socket) do
    socket
    |> put_flash(:error, "Location not found")
    |> push_navigate(to: ~p"/locations")
  end

  defp return_path("index", _location), do: ~p"/locations"
  defp return_path("show", nil), do: ~p"/locations"
  defp return_path("show", location), do: ~p"/locations/#{location.id}"
  defp return_path(_, _location), do: ~p"/locations"

  defp fetch_location(%{"id" => id}), do: Shelter.get_location(id)
  defp fetch_location(_params), do: {:ok, nil}
end
