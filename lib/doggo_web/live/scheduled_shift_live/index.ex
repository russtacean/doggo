defmodule DoggoWeb.ScheduledShiftLive.Index do
  use DoggoWeb, :live_view

  alias Doggo.Shelter
  alias DoggoWeb.Format

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:scheduled_shifts} location={@location}>
      <.header>
        <div class="flex min-w-0 items-center gap-inline">
          <.back_button to={~p"/locations/#{@location}"} />
          <span class="min-w-0 truncate text-text-primary dark:text-text-primary-dark">
            Scheduled shifts
          </span>
        </div>
        <:subtitle>Add one-off shifts for volunteers at {@location.name}.</:subtitle>
        <:actions>
          <.button
            color="primary"
            to={~p"/locations/#{@location}/scheduled_shifts/new"}
            link_type="live_redirect"
            class="w-full justify-center sm:w-auto"
          >
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> New scheduled shift
          </.button>
        </:actions>
      </.header>

      <.surface_card variant="static" class="p-inset-card">
        <.form
          for={@week_form}
          id="scheduled-shift-week-form"
          phx-change="select_week"
          class="flex flex-col gap-field sm:flex-row sm:items-end sm:justify-between"
        >
          <.field type="date" label="Week of" field={@week_form[:date]} />
          <p class="text-sm text-text-secondary dark:text-text-secondary-dark">
            Showing {Format.format_date(@week_start)} through {Format.format_date(@week_last)}
          </p>
        </.form>
      </.surface_card>

      <div id="scheduled_shifts" class="space-y-stack-tight">
        <.empty_state
          :if={Enum.empty?(@scheduled_shifts)}
          id="empty-state"
          icon="hero-calendar-days"
          title="No scheduled shifts yet"
          subtitle="Add one-off shifts for volunteers at this location."
        >
          <:cta>
            <.button
              color="primary"
              to={~p"/locations/#{@location}/scheduled_shifts/new"}
              link_type="live_redirect"
            >
              <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add scheduled shift
            </.button>
          </:cta>
        </.empty_state>

        <div :for={shift <- @scheduled_shifts} id={"scheduled_shifts-#{shift.id}"} class="group">
          <.surface_card class="p-inset-card">
            <div class="flex flex-col gap-actions sm:flex-row sm:items-start sm:justify-between">
              <div class="min-w-0">
                <.link
                  navigate={~p"/locations/#{@location}/scheduled_shifts/#{shift}"}
                  class="font-semibold text-text-primary dark:text-text-primary-dark hover:underline block truncate"
                >
                  {shift.name}
                </.link>
                <p class="text-sm text-text-secondary dark:text-text-secondary-dark">
                  {Format.format_time_range(shift.start_time, shift.end_time)}
                </p>
              </div>
              <div class="flex items-center gap-actions self-end shrink-0 sm:self-auto">
                <.button
                  color="gray"
                  variant="ghost"
                  size="md"
                  to={~p"/locations/#{@location}/scheduled_shifts/#{shift}/edit"}
                  link_type="live_redirect"
                  aria-label={gettext("Edit scheduled shift")}
                  class="min-h-11 min-w-11 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200 hover:bg-surface-hover dark:hover:bg-surface-hover-dark"
                >
                  <.icon name="hero-pencil-square" class="w-4 h-4" />
                </.button>
                <.button
                  color="danger"
                  variant="ghost"
                  size="md"
                  phx-click={PetalComponents.Modal.show_modal("delete-confirm-#{shift.id}")}
                  aria-label={gettext("Delete scheduled shift")}
                  class="min-h-11 min-w-11 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </.button>
              </div>
            </div>

            <div class="flex items-start gap-actions text-sm text-text-secondary dark:text-text-secondary-dark pt-separator-tight mt-card-block-end border-t border-border-divider dark:border-border-divider-dark">
              <.icon name="hero-calendar" class="w-4 h-4 shrink-0" />
              <span>{Format.format_date(shift.date)}</span>
            </div>
          </.surface_card>

          <.delete_confirm_modal
            title="Delete scheduled shift"
            id={"delete-confirm-#{shift.id}"}
            confirm_value={%{id: shift.id}}
          >
            <p class="text-text-secondary dark:text-text-secondary-dark">
              This removes the scheduled shift “{shift.name}” from {@location.name}. This action cannot be undone.
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
          |> assign(:page_title, "Scheduled shifts")
          |> assign(:location, location)

        {:ok, socket}

      {:error, _error} ->
        {:ok, location_not_found(socket)}
    end
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{location: location}} = socket) do
    selected_date = selected_date(params)
    week_start = Date.beginning_of_week(selected_date, :monday)
    week_end = Date.add(week_start, 7)

    scheduled_shifts =
      Shelter.list_scheduled_shifts_for_location_between_dates!(
        location.id,
        week_start,
        week_end
      )

    socket =
      socket
      |> assign(:selected_date, selected_date)
      |> assign(:week_start, week_start)
      |> assign(:week_end, week_end)
      |> assign(:week_last, Date.add(week_end, -1))
      |> assign(:week_form, week_form(selected_date))
      |> assign(:scheduled_shifts, scheduled_shifts)

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("select_week", %{"week" => %{"date" => date}}, socket) do
    selected_date = parse_date(date, socket.assigns.selected_date)

    {:noreply,
     push_patch(socket,
       to:
         ~p"/locations/#{socket.assigns.location}/scheduled_shifts?date=#{Date.to_iso8601(selected_date)}"
     )}
  end

  def handle_event("select_week", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, delete_scheduled_shift(socket, id)}
  end

  defp selected_date(%{"date" => date}), do: parse_date(date, Date.utc_today())
  defp selected_date(_params), do: Date.utc_today()

  defp parse_date(date, fallback) do
    case Date.from_iso8601(date) do
      {:ok, date} -> date
      {:error, _reason} -> fallback
    end
  end

  defp week_form(selected_date) do
    to_form(%{"date" => Date.to_iso8601(selected_date)}, as: :week)
  end

  defp delete_scheduled_shift(socket, id) do
    with {:ok, shift} <- Shelter.get_scheduled_shift(id),
         true <- shift.location_id == socket.assigns.location.id do
      destroy_scheduled_shift(socket, shift)
    else
      _error -> put_flash(socket, :error, "Scheduled shift not found")
    end
  end

  defp destroy_scheduled_shift(socket, shift) do
    case Shelter.destroy_scheduled_shift(shift) do
      :ok ->
        scheduled_shifts = Enum.reject(socket.assigns.scheduled_shifts, &(&1.id == shift.id))

        socket
        |> put_flash(:info, "Scheduled shift deleted successfully")
        |> assign(:scheduled_shifts, scheduled_shifts)

      {:error, _error} ->
        put_flash(socket, :error, "Could not delete scheduled shift")
    end
  end

  defp location_not_found(socket) do
    socket
    |> put_flash(:error, "Location not found")
    |> push_navigate(to: ~p"/locations")
  end
end
