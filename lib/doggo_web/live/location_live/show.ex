defmodule DoggoWeb.LocationLive.Show do
  use DoggoWeb, :live_view

  alias Doggo.Shelter

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        <div class="flex min-w-0 items-center gap-inline">
          <.back_button to={~p"/locations"} />
          <span class="min-w-0 truncate text-text-primary dark:text-text-primary-dark">
            {@location.name}
          </span>
        </div>
        <:subtitle>Location details and information</:subtitle>
        <:actions>
          <div class="grid grid-cols-1 gap-actions sm:flex sm:flex-wrap sm:items-center sm:justify-end">
            <.button
              color="white"
              variant="outline"
              to={~p"/locations/#{@location}/enclosures"}
              link_type="live_redirect"
              class="w-full justify-center sm:w-auto"
            >
              <.icon name="hero-home-modern" class="w-4 h-4 mr-1" /> Enclosures
            </.button>
            <.button
              color="white"
              variant="outline"
              to={~p"/locations/#{@location}/recurring_shifts"}
              link_type="live_redirect"
              class="w-full justify-center sm:w-auto"
            >
              <.icon name="hero-arrow-path" class="w-4 h-4 mr-1" /> Weekly patterns
            </.button>
            <.button
              color="primary"
              to={~p"/locations/#{@location}/edit?return_to=show"}
              link_type="live_redirect"
              class="w-full justify-center sm:w-auto"
            >
              <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit
            </.button>
          </div>
        </:actions>
      </.header>

      <%!-- Delete confirmation modal --%>
      <.delete_confirm_modal
        title="Delete Location"
        id="delete-confirm"
        confirm_value={%{id: @location.id}}
      >
        <p class="text-text-secondary dark:text-text-secondary-dark">
          Deleting this location will also delete all associated enclosures, scheduled shifts, and weekly patterns. This action cannot be undone.
        </p>
      </.delete_confirm_modal>

      <div class="space-y-stack-section">
        <%!-- Main info card --%>
        <.surface_card class="p-inset-card-lg">
          <%!-- Card header --%>
          <div class="flex items-center gap-inline mb-section-header pb-header-rule border-b border-border-divider dark:border-border-divider-dark">
            <div class="p-inset-icon rounded-lg bg-surface-accent dark:bg-surface-accent-dark">
              <.icon
                name="hero-building-office-2"
                class="w-6 h-6 text-text-accent dark:text-text-accent-dark"
              />
            </div>
            <div class="min-w-0">
              <h2 class="wrap-break-word text-lg font-semibold text-text-primary dark:text-text-primary-dark">
                {@location.name}
              </h2>
            </div>
          </div>

          <div class="space-y-stack-tight">
            <div :if={@location.address} class="flex items-start gap-inline">
              <.icon
                name="hero-map-pin"
                class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
              />
              <div>
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Address</p>
                <p class="text-text-primary dark:text-text-primary-dark">{@location.address}</p>
              </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-field">
              <div :if={@location.city} class="flex items-start gap-inline">
                <.icon
                  name="hero-building-library"
                  class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
                />
                <div>
                  <p class="text-sm text-text-secondary dark:text-text-secondary-dark">City</p>
                  <p class="text-text-primary dark:text-text-primary-dark">{@location.city}</p>
                </div>
              </div>

              <div :if={@location.region} class="flex items-start gap-inline">
                <.icon
                  name="hero-map"
                  class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
                />
                <div>
                  <p class="text-sm text-text-secondary dark:text-text-secondary-dark">
                    Region/State
                  </p>
                  <p class="text-text-primary dark:text-text-primary-dark">{@location.region}</p>
                </div>
              </div>

              <div :if={@location.postal_code} class="flex items-start gap-inline">
                <.icon
                  name="hero-envelope"
                  class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
                />
                <div>
                  <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Postal Code</p>
                  <p class="text-text-primary dark:text-text-primary-dark">{@location.postal_code}</p>
                </div>
              </div>

              <div :if={@location.country} class="flex items-start gap-inline">
                <.icon
                  name="hero-flag"
                  class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
                />
                <div>
                  <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Country</p>
                  <p class="text-text-primary dark:text-text-primary-dark">{@location.country}</p>
                </div>
              </div>
            </div>

            <div class="flex items-start gap-inline pt-separator-comfort border-t border-border-divider dark:border-border-divider-dark">
              <.icon
                name="hero-clock"
                class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
              />
              <div>
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Timezone</p>
                <.badge color="gray" size="sm" variant="soft">
                  <.icon name="hero-globe-alt" class="w-3 h-3 mr-1" />
                  {@location.timezone}
                </.badge>
              </div>
            </div>
          </div>
        </.surface_card>

        <%!-- Quick actions footer --%>
        <div class="flex items-center justify-end pt-block-actions">
          <.button
            color="danger"
            variant="outline"
            size="sm"
            phx-click={PetalComponents.Modal.show_modal("delete-confirm")}
            class="w-full justify-center sm:w-auto"
          >
            <.icon name="hero-trash" class="w-4 h-4 mr-1" /> Delete
          </.button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, load_location(socket, id)}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, delete_location(socket, id)}
  end

  defp load_location(socket, id) do
    case Shelter.get_location(id) do
      {:ok, location} ->
        socket
        |> assign(:page_title, "Show Location")
        |> assign(:location, location)

      {:error, _error} ->
        location_not_found(socket)
    end
  end

  defp delete_location(socket, id) do
    case Shelter.get_location(id) do
      {:ok, location} -> destroy_location(socket, location)
      {:error, _error} -> location_not_found(socket)
    end
  end

  defp destroy_location(socket, location) do
    case Shelter.destroy_location(location) do
      :ok ->
        socket
        |> put_flash(:info, "Location deleted successfully")
        |> push_navigate(to: ~p"/locations")

      {:error, _error} ->
        put_flash(socket, :error, "Could not delete location")
    end
  end

  defp location_not_found(socket) do
    socket
    |> put_flash(:error, "Location not found")
    |> push_navigate(to: ~p"/locations")
  end
end
