defmodule DoggoWeb.LocationLive.Index do
  use DoggoWeb, :live_view

  alias Doggo.Shelter

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Locations
        <:subtitle>Manage shelter locations and their facilities</:subtitle>
        <:actions>
          <.button color="primary" to={~p"/locations/new"} link_type="live_redirect">
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> New Location
          </.button>
        </:actions>
      </.header>

      <%!-- Empty state --%>
      <div id="locations" phx-update="stream" class="space-y-stack-tight">
        <div id="empty-state" class="hidden only:block text-center py-empty-state">
          <.icon
            name="hero-building-office-2"
            class="w-16 h-16 mx-auto text-text-secondary dark:text-text-secondary-dark mb-empty-cta"
          />
          <h3 class="text-lg font-medium text-text-primary dark:text-text-primary-dark">
            No locations yet
          </h3>
          <p class="text-text-secondary dark:text-text-secondary-dark mt-empty-prose mb-empty-cta">
            Get started by creating your first shelter location
          </p>
          <.button color="primary" to={~p"/locations/new"} link_type="live_redirect">
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Location
          </.button>
        </div>

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
                    class="w-5 h-5 text-primary-600 dark:text-primary-400"
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
            <div class="flex items-center justify-between pt-separator-tight border-t border-border-divider dark:border-border-divider-dark">
              <div class="flex items-center gap-actions text-sm text-text-secondary dark:text-text-secondary-dark">
                <.icon name="hero-map-pin" class="w-4 h-4" />
                <span>{location.city || "No city"}, {location.region || "No region"}</span>
              </div>
              <div class="flex items-center gap-actions">
                <.button
                  color="gray"
                  variant="ghost"
                  size="md"
                  to={~p"/locations/#{location}/edit"}
                  link_type="live_redirect"
                  aria-label={gettext("Edit location")}
                  class="opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200 hover:bg-surface-hover dark:hover:bg-surface-hover-dark"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4" />
                </.button>
                <.button
                  color="danger"
                  variant="ghost"
                  size="md"
                  phx-click={show_modal("delete-confirm-#{location.id}")}
                  aria-label={gettext("Delete location")}
                  class="opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200"
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
              Deleting this location will also delete all associated enclosures, scheduled shifts, and recurring shifts. This action cannot be undone.
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
