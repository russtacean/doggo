defmodule DoggoWeb.RecurringShiftLive.Show do
  use DoggoWeb, :live_view

  alias Doggo.Shelter
  alias Doggo.Shelter.RecurringShift.Day
  alias DoggoWeb.Format

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        <div class="flex min-w-0 items-center gap-inline">
          <.back_button to={~p"/locations/#{@location}/recurring_shifts"} />
          <span class="min-w-0 truncate text-text-primary dark:text-text-primary-dark">
            {@recurring_shift.name}
          </span>
        </div>
        <:subtitle>A weekly shift pattern for {@location.name}</:subtitle>
        <:actions>
          <.button
            color="primary"
            to={~p"/locations/#{@location}/recurring_shifts/#{@recurring_shift}/edit?return_to=show"}
            link_type="live_redirect"
            class="w-full justify-center sm:w-auto"
          >
            <.icon name="hero-pencil-square" class="w-4 h-4 mr-1" /> Edit
          </.button>
        </:actions>
      </.header>

      <.delete_confirm_modal
        title="Delete weekly pattern"
        id="delete-confirm"
        confirm_value={%{id: @recurring_shift.id}}
      >
        <p class="text-text-secondary dark:text-text-secondary-dark">
          This removes this weekly pattern from {@location.name}. This action cannot be undone.
        </p>
      </.delete_confirm_modal>

      <div class="space-y-stack-section">
        <.surface_card class="p-inset-card-lg">
          <div class="flex items-center gap-inline mb-section-header pb-header-rule border-b border-border-divider dark:border-border-divider-dark">
            <div class="p-inset-icon rounded-lg bg-surface-accent dark:bg-surface-accent-dark">
              <.icon
                name="hero-arrow-path"
                class="w-6 h-6 text-text-accent dark:text-text-accent-dark"
              />
            </div>
            <div class="min-w-0">
              <h2 class="wrap-break-word text-lg font-semibold text-text-primary dark:text-text-primary-dark">
                {@recurring_shift.name}
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
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">Day</p>
                <.badge color="primary" size="sm" variant="soft">
                  {Day.label(@recurring_shift.day_of_week)}
                </.badge>
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
                  {Format.format_time_range(
                    @recurring_shift.start_time,
                    @recurring_shift.end_time,
                    "–"
                  )}
                </p>
              </div>
            </div>

            <div class="flex items-start gap-inline pt-separator-comfort border-t border-border-divider dark:border-border-divider-dark">
              <.icon
                name="hero-calendar-days"
                class="w-5 h-5 text-icon dark:text-icon-dark mt-0.5 shrink-0"
              />
              <div class="min-w-0">
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">
                  Active date range
                </p>
                <p class="wrap-break-word text-text-primary dark:text-text-primary-dark">
                  {active_date_range(@recurring_shift)}
                </p>
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark mt-1">
                  Optional dates limit when this pattern is active. The end date is not included.
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
    {:ok, load_recurring_shift(socket, location_id, id)}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, delete_recurring_shift(socket, id)}
  end

  defp load_recurring_shift(socket, location_id, id) do
    case Shelter.get_location(location_id) do
      {:ok, location} ->
        load_recurring_shift_for_location(socket, location, id)

      {:error, _error} ->
        location_not_found(socket)
    end
  end

  defp load_recurring_shift_for_location(socket, location, id) do
    case Shelter.get_recurring_shift(id) do
      {:ok, rs} when rs.location_id == location.id ->
        socket
        |> assign(:page_title, rs.name)
        |> assign(:location, location)
        |> assign(:recurring_shift, rs)

      {:ok, _rs} ->
        not_found(socket, ~p"/locations/#{location}/recurring_shifts")

      {:error, _error} ->
        not_found(socket, ~p"/locations/#{location}/recurring_shifts")
    end
  end

  defp delete_recurring_shift(socket, id) do
    with {:ok, rs} <- Shelter.get_recurring_shift(id),
         true <- rs.location_id == socket.assigns.location.id do
      destroy_recurring_shift(socket, rs)
    else
      _error -> not_found(socket, ~p"/locations/#{socket.assigns.location}/recurring_shifts")
    end
  end

  defp destroy_recurring_shift(socket, rs) do
    case Shelter.destroy_recurring_shift(rs) do
      :ok ->
        socket
        |> put_flash(:info, "Weekly pattern deleted successfully")
        |> push_navigate(to: ~p"/locations/#{socket.assigns.location}/recurring_shifts")

      {:error, _error} ->
        put_flash(socket, :error, "Could not delete weekly pattern")
    end
  end

  defp location_not_found(socket) do
    socket
    |> put_flash(:error, "Location not found")
    |> push_navigate(to: ~p"/locations")
  end

  defp not_found(socket, path) do
    socket
    |> put_flash(:error, "Weekly pattern not found")
    |> push_navigate(to: path)
  end

  defp active_date_range(%{start_date: nil, end_date: nil}), do: "Active every week"

  defp active_date_range(%{start_date: %Date{} = start_date, end_date: nil}) do
    "Active from #{Format.format_date(start_date)}"
  end

  defp active_date_range(%{start_date: nil, end_date: %Date{} = end_date}) do
    "Active until #{Format.format_date(end_date)}"
  end

  defp active_date_range(%{start_date: %Date{} = start_date, end_date: %Date{} = end_date}) do
    "Active #{Format.format_date(start_date)} until #{Format.format_date(end_date)}"
  end
end
