defmodule DoggoWeb.ScheduledShiftLive.Show do
  use DoggoWeb, :live_view

  alias Doggo.Shelter
  alias DoggoWeb.Format

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        <div class="flex min-w-0 items-center gap-inline">
          <.back_button to={~p"/locations/#{@location}/scheduled_shifts"} />
          <span class="min-w-0 truncate text-text-primary dark:text-text-primary-dark">
            {@scheduled_shift.name}
          </span>
        </div>
        <:subtitle>A scheduled shift for {@location.name}</:subtitle>
        <:actions>
          <.button
            color="primary"
            to={~p"/locations/#{@location}/scheduled_shifts/#{@scheduled_shift}/edit?return_to=show"}
            link_type="live_redirect"
            class="w-full justify-center sm:w-auto"
          >
            <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit
          </.button>
        </:actions>
      </.header>

      <.delete_confirm_modal
        title="Delete scheduled shift"
        id="delete-confirm"
        confirm_value={%{id: @scheduled_shift.id}}
      >
        <p class="text-text-secondary dark:text-text-secondary-dark">
          This removes this scheduled shift from {@location.name}. This action cannot be undone.
        </p>
      </.delete_confirm_modal>

      <div class="space-y-stack-section">
        <.surface_card class="p-inset-card-lg">
          <div class="flex items-center gap-inline mb-section-header pb-header-rule border-b border-border-divider dark:border-border-divider-dark">
            <div class="p-inset-icon rounded-lg bg-surface-accent dark:bg-surface-accent-dark">
              <.icon
                name="hero-calendar-days"
                class="w-6 h-6 text-text-accent dark:text-text-accent-dark"
              />
            </div>
            <div class="min-w-0">
              <h2 class="wrap-break-word text-lg font-semibold text-text-primary dark:text-text-primary-dark">
                {@scheduled_shift.name}
              </h2>
            </div>
          </div>

          <div class="space-y-stack-tight">
            <div class="flex items-start gap-inline">
              <.icon
                name="hero-calendar"
                class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
              />
              <div>
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Date</p>
                <p class="text-text-primary dark:text-text-primary-dark">
                  {Format.format_date(@scheduled_shift.date)}
                </p>
              </div>
            </div>

            <div class="flex items-start gap-inline pt-separator-comfort border-t border-border-divider dark:border-border-divider-dark">
              <.icon
                name="hero-clock"
                class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
              />
              <div>
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Time</p>
                <p class="text-text-primary dark:text-text-primary-dark">
                  {Format.format_time_range(@scheduled_shift.start_time, @scheduled_shift.end_time)}
                </p>
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
    {:ok, load_scheduled_shift(socket, location_id, id)}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, delete_scheduled_shift(socket, id)}
  end

  defp load_scheduled_shift(socket, location_id, id) do
    case Shelter.get_location(location_id) do
      {:ok, location} ->
        load_scheduled_shift_for_location(socket, location, id)

      {:error, _error} ->
        location_not_found(socket)
    end
  end

  defp load_scheduled_shift_for_location(socket, location, id) do
    case Shelter.get_scheduled_shift(id) do
      {:ok, shift} when shift.location_id == location.id ->
        socket
        |> assign(:page_title, shift.name)
        |> assign(:location, location)
        |> assign(:scheduled_shift, shift)

      {:ok, _shift} ->
        not_found(socket, ~p"/locations/#{location}/scheduled_shifts")

      {:error, _error} ->
        not_found(socket, ~p"/locations/#{location}/scheduled_shifts")
    end
  end

  defp delete_scheduled_shift(socket, id) do
    with {:ok, shift} <- Shelter.get_scheduled_shift(id),
         true <- shift.location_id == socket.assigns.location.id do
      destroy_scheduled_shift(socket, shift)
    else
      _error -> not_found(socket, ~p"/locations/#{socket.assigns.location}/scheduled_shifts")
    end
  end

  defp destroy_scheduled_shift(socket, shift) do
    case Shelter.destroy_scheduled_shift(shift) do
      :ok ->
        socket
        |> put_flash(:info, "Scheduled shift deleted successfully")
        |> push_navigate(to: ~p"/locations/#{socket.assigns.location}/scheduled_shifts")

      {:error, _error} ->
        put_flash(socket, :error, "Could not delete scheduled shift")
    end
  end

  defp location_not_found(socket) do
    socket
    |> put_flash(:error, "Location not found")
    |> push_navigate(to: ~p"/locations")
  end

  defp not_found(socket, path) do
    socket
    |> put_flash(:error, "Scheduled shift not found")
    |> push_navigate(to: path)
  end
end
