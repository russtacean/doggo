defmodule DoggoWeb.EnclosureLive.Show do
  use DoggoWeb, :live_view

  alias Doggo.Shelter
  alias Doggo.Shelter.EnclosureStatus

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:enclosures} location={@location}>
      <.header>
        <div class="flex min-w-0 items-center gap-inline">
          <.back_button to={~p"/locations/#{@location}/enclosures"} />
          <span class="min-w-0 truncate text-text-primary dark:text-text-primary-dark">
            {@enclosure.name}
          </span>
        </div>
        <:subtitle>Enclosure details for {@location.name}</:subtitle>
        <:actions>
          <.button
            color="primary"
            to={~p"/locations/#{@location}/enclosures/#{@enclosure}/edit?return_to=show"}
            link_type="live_redirect"
            class="w-full justify-center sm:w-auto"
          >
            <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit
          </.button>
        </:actions>
      </.header>

      <.delete_confirm_modal
        title="Delete Enclosure"
        id="delete-confirm"
        confirm_value={%{id: @enclosure.id}}
      >
        <p class="text-text-secondary dark:text-text-secondary-dark">
          Deleting this enclosure will remove it from {@location.name}. This action cannot be undone.
        </p>
      </.delete_confirm_modal>

      <div class="space-y-stack-section">
        <.surface_card class="p-inset-card-lg">
          <div class="flex items-center gap-inline mb-section-header pb-header-rule border-b border-border-divider dark:border-border-divider-dark">
            <div class="p-inset-icon rounded-lg bg-surface-accent dark:bg-surface-accent-dark">
              <.icon
                name="hero-home-modern"
                class="w-6 h-6 text-text-accent dark:text-text-accent-dark"
              />
            </div>
            <div class="min-w-0">
              <h2 class="wrap-break-word text-lg font-semibold text-text-primary dark:text-text-primary-dark">
                {@enclosure.name}
              </h2>
            </div>
          </div>

          <div class="space-y-stack-tight">
            <div class="flex items-start gap-inline">
              <.icon
                name="hero-sparkles"
                class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
              />
              <div>
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Status</p>
                <.badge
                  color={EnclosureStatus.badge_color(@enclosure.status)}
                  size="sm"
                  variant="soft"
                >
                  {EnclosureStatus.label(@enclosure.status)}
                </.badge>
              </div>
            </div>

            <div class="flex items-start gap-inline pt-separator-comfort border-t border-border-divider dark:border-border-divider-dark">
              <.icon
                name="hero-map-pin"
                class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
              />
              <div>
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Location</p>
                <p class="text-text-primary dark:text-text-primary-dark">{@location.name}</p>
              </div>
            </div>
          </div>
        </.surface_card>

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
  def mount(%{"location_id" => location_id, "id" => id}, _session, socket) do
    {:ok, load_enclosure(socket, location_id, id)}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, delete_enclosure(socket, id)}
  end

  defp load_enclosure(socket, location_id, id) do
    with {:ok, location} <- Shelter.get_location(location_id),
         {:ok, enclosure} <- Shelter.get_enclosure(id),
         true <- enclosure.location_id == location.id do
      socket
      |> assign(:page_title, enclosure.name)
      |> assign(:location, location)
      |> assign(:enclosure, enclosure)
    else
      {:error, _error} -> not_found(socket, ~p"/locations")
      false -> not_found(socket, ~p"/locations/#{location_id}/enclosures")
    end
  end

  defp delete_enclosure(socket, id) do
    with {:ok, enclosure} <- Shelter.get_enclosure(id),
         true <- enclosure.location_id == socket.assigns.location.id do
      destroy_enclosure(socket, enclosure)
    else
      _error -> not_found(socket, ~p"/locations/#{socket.assigns.location}/enclosures")
    end
  end

  defp destroy_enclosure(socket, enclosure) do
    case Shelter.destroy_enclosure(enclosure) do
      :ok ->
        socket
        |> put_flash(:info, "Enclosure deleted successfully")
        |> push_navigate(to: ~p"/locations/#{socket.assigns.location}/enclosures")

      {:error, _error} ->
        put_flash(socket, :error, "Could not delete enclosure")
    end
  end

  defp not_found(socket, path) do
    socket
    |> put_flash(:error, "Enclosure not found")
    |> push_navigate(to: path)
  end
end
