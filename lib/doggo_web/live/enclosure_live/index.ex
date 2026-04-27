defmodule DoggoWeb.EnclosureLive.Index do
  use DoggoWeb, :live_view

  alias Doggo.Shelter
  alias Doggo.Shelter.EnclosureStatus

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:enclosures} location={@location}>
      <.header>
        <div class="flex min-w-0 items-center gap-inline">
          <.back_button to={~p"/locations/#{@location}"} />
          <span class="min-w-0 truncate text-text-primary dark:text-text-primary-dark">
            Enclosures
          </span>
        </div>
        <:subtitle>Manage enclosure availability for {@location.name}</:subtitle>
        <:actions>
          <.button
            color="primary"
            to={~p"/locations/#{@location}/enclosures/new"}
            link_type="live_redirect"
            class="w-full justify-center sm:w-auto"
          >
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> New Enclosure
          </.button>
        </:actions>
      </.header>

      <div id="enclosures" phx-update="stream" class="space-y-stack-tight">
        <.empty_state
          id="empty-state"
          icon="hero-home-modern"
          title="No enclosures yet"
          subtitle="Add the first enclosure for this location"
        >
          <:cta>
            <.button
              color="primary"
              to={~p"/locations/#{@location}/enclosures/new"}
              link_type="live_redirect"
            >
              <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Enclosure
            </.button>
          </:cta>
        </.empty_state>

        <div :for={{id, enclosure} <- @streams.enclosures} id={id} class="group">
          <.surface_card class="p-inset-card">
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-actions mb-card-block-end">
              <div class="flex items-center gap-inline min-w-0">
                <div class="p-inset-icon rounded-lg bg-surface-accent dark:bg-surface-accent-dark shrink-0">
                  <.icon
                    name="hero-home-modern"
                    class="w-5 h-5 text-text-accent dark:text-text-accent-dark"
                  />
                </div>
                <div class="min-w-0">
                  <.link
                    navigate={~p"/locations/#{@location}/enclosures/#{enclosure}"}
                    class="font-semibold text-text-primary dark:text-text-primary-dark hover:underline block truncate"
                  >
                    {enclosure.name}
                  </.link>
                </div>
              </div>
              <div class="self-start sm:self-center shrink-0">
                <.badge color={EnclosureStatus.badge_color(enclosure.status)} size="sm" variant="soft">
                  {EnclosureStatus.label(enclosure.status)}
                </.badge>
              </div>
            </div>

            <div class="flex justify-end pt-separator-tight border-t border-border-divider dark:border-border-divider-dark">
              <div class="flex items-center gap-actions">
                <.button
                  color="gray"
                  variant="ghost"
                  size="md"
                  to={~p"/locations/#{@location}/enclosures/#{enclosure}/edit"}
                  link_type="live_redirect"
                  aria-label={gettext("Edit enclosure")}
                  class="opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200 hover:bg-surface-hover dark:hover:bg-surface-hover-dark"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4" />
                </.button>
                <.button
                  color="danger"
                  variant="ghost"
                  size="md"
                  phx-click={PetalComponents.Modal.show_modal("delete-confirm-#{enclosure.id}")}
                  aria-label={gettext("Delete enclosure")}
                  class="opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </.button>
              </div>
            </div>
          </.surface_card>

          <.delete_confirm_modal
            title="Delete Enclosure"
            id={"delete-confirm-#{enclosure.id}"}
            confirm_value={%{id: enclosure.id}}
          >
            <p class="text-text-secondary dark:text-text-secondary-dark">
              Deleting this enclosure will remove it from {@location.name}. This action cannot be undone.
            </p>
          </.delete_confirm_modal>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"location_id" => location_id}, _session, socket) do
    case Shelter.get_location(location_id) do
      {:ok, location} ->
        socket =
          socket
          |> assign(:page_title, "Enclosures")
          |> assign(:location, location)
          |> stream(:enclosures, Shelter.list_enclosures_for_location!(location.id))

        {:ok, socket}

      {:error, _error} ->
        {:ok, location_not_found(socket)}
    end
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, delete_enclosure(socket, id)}
  end

  defp delete_enclosure(socket, id) do
    with {:ok, enclosure} <- Shelter.get_enclosure(id),
         true <- enclosure.location_id == socket.assigns.location.id do
      destroy_enclosure(socket, enclosure)
    else
      _error -> put_flash(socket, :error, "Enclosure not found")
    end
  end

  defp destroy_enclosure(socket, enclosure) do
    case Shelter.destroy_enclosure(enclosure) do
      :ok ->
        socket
        |> put_flash(:info, "Enclosure deleted successfully")
        |> stream_delete(:enclosures, enclosure)

      {:error, _error} ->
        put_flash(socket, :error, "Could not delete enclosure")
    end
  end

  defp location_not_found(socket) do
    socket
    |> put_flash(:error, "Location not found")
    |> push_navigate(to: ~p"/locations")
  end
end
