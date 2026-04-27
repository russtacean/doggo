defmodule DoggoWeb.LocationLive.Index do
  use DoggoWeb, :live_view

  alias Doggo.Shelter

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:locations}>
      <.header>
        Locations
        <:subtitle>Manage shelter locations and their facilities</:subtitle>
        <:actions>
          <.button
            color="primary"
            to={~p"/locations/new"}
            link_type="live_redirect"
            class="w-full justify-center sm:w-auto"
          >
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> New Location
          </.button>
        </:actions>
      </.header>

      <div id="locations" phx-update="stream" class="space-y-stack-tight">
        <.empty_state
          id="empty-state"
          icon="hero-building-office-2"
          title="No locations yet"
          subtitle="Get started by creating your first shelter location"
        >
          <:cta>
            <.button color="primary" to={~p"/locations/new"} link_type="live_redirect">
              <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Location
            </.button>
          </:cta>
        </.empty_state>

        <%!-- Location cards --%>
        <div
          :for={{id, location} <- @streams.locations}
          id={id}
          class="group"
        >
          <.surface_card class="p-inset-card">
            <%!-- Card header --%>
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-actions mb-card-block-end">
              <div class="flex items-center gap-inline min-w-0">
                <div class="p-inset-icon rounded-lg bg-surface-accent dark:bg-surface-accent-dark shrink-0">
                  <.icon
                    name="hero-building-office-2"
                    class="w-5 h-5 text-text-accent dark:text-text-accent-dark"
                  />
                </div>
                <div class="min-w-0">
                  <.link
                    navigate={~p"/locations/#{location}"}
                    class="font-semibold text-text-primary dark:text-text-primary-dark hover:underline block truncate"
                  >
                    {location.name}
                  </.link>
                  <p
                    :if={location.formatted_address != ""}
                    class="text-sm text-text-secondary dark:text-text-secondary-dark truncate"
                  >
                    {location.formatted_address}
                  </p>
                </div>
              </div>
              <div class="self-start sm:self-center shrink-0">
                <.badge color="gray" size="sm" variant="soft">
                  <.icon name="hero-globe-alt" class="w-3 h-3 mr-1" />
                  {location.timezone}
                </.badge>
              </div>
            </div>

            <%!-- Card footer --%>
            <div class="flex flex-col gap-actions pt-separator-tight border-t border-border-divider dark:border-border-divider-dark sm:flex-row sm:items-center sm:justify-between">
              <div class="flex min-w-0 items-center gap-actions text-sm text-text-secondary dark:text-text-secondary-dark">
                <.icon name="hero-map-pin" class="w-4 h-4 shrink-0" />
                <span class="truncate">
                  {location.city || "No city"}, {location.region || "No region"}
                </span>
              </div>
              <div class="flex items-center gap-actions self-end sm:self-auto">
                <.button
                  color="gray"
                  variant="ghost"
                  size="md"
                  to={~p"/locations/#{location}/edit"}
                  link_type="live_redirect"
                  aria-label={gettext("Edit location")}
                  class="min-h-11 min-w-11 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200 hover:bg-surface-hover dark:hover:bg-surface-hover-dark"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4" />
                </.button>
                <.button
                  color="danger"
                  variant="ghost"
                  size="md"
                  phx-click={PetalComponents.Modal.show_modal("delete-confirm-#{location.id}")}
                  aria-label={gettext("Delete location")}
                  class="min-h-11 min-w-11 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </.button>
              </div>
            </div>
          </.surface_card>

          <.delete_confirm_modal
            title="Delete Location"
            id={"delete-confirm-#{location.id}"}
            confirm_value={%{id: location.id}}
          >
            <p class="text-text-secondary dark:text-text-secondary-dark">
              Deleting this location will also delete all associated enclosures, scheduled shifts, and weekly patterns. This action cannot be undone.
            </p>
          </.delete_confirm_modal>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Locations")
      |> stream(:locations, Shelter.list_active_locations!(load: [:formatted_address]))

    {:ok, socket}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, delete_location(socket, id)}
  end

  defp delete_location(socket, id) do
    case Shelter.get_location(id) do
      {:ok, location} -> destroy_location(socket, location)
      {:error, _error} -> put_flash(socket, :error, "Location not found")
    end
  end

  defp destroy_location(socket, location) do
    case Shelter.destroy_location(location) do
      :ok ->
        socket
        |> put_flash(:info, "Location deleted successfully")
        |> stream_delete(:locations, location)

      {:error, _error} ->
        put_flash(socket, :error, "Could not delete location")
    end
  end
end
