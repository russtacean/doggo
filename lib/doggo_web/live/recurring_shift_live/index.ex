defmodule DoggoWeb.RecurringShiftLive.Index do
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
          <.back_button to={~p"/locations/#{@location}"} />
          <span class="min-w-0 truncate text-text-primary dark:text-text-primary-dark">
            Weekly shift patterns
          </span>
        </div>
        <:subtitle>Set the shifts that repeat each week at this location.</:subtitle>
        <:actions>
          <.button
            color="primary"
            to={~p"/locations/#{@location}/recurring_shifts/new"}
            link_type="live_redirect"
            class="w-full justify-center sm:w-auto"
          >
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> New weekly pattern
          </.button>
        </:actions>
      </.header>

      <div id="recurring_shifts" class="space-y-stack-tight">
        <.empty_state
          :if={Enum.empty?(@recurring_shifts)}
          id="empty-state"
          icon="hero-arrow-path"
          title="No weekly shift patterns yet"
          subtitle="Add the regular shifts volunteers can expect each week."
        >
          <:cta>
            <.button
              color="primary"
              to={~p"/locations/#{@location}/recurring_shifts/new"}
              link_type="live_redirect"
            >
              <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add weekly pattern
            </.button>
          </:cta>
        </.empty_state>

        <div :if={@recurring_shifts != []} class="space-y-stack-section">
          <section
            :for={{day_number, day_label, shifts} <- @weekday_sections}
            id={"weekday-#{day_number}"}
            class="space-y-stack-tight"
          >
            <div class="flex items-center justify-between gap-actions">
              <h2 class="text-sm font-semibold uppercase tracking-wide text-text-secondary dark:text-text-secondary-dark">
                {day_label}
              </h2>
              <.badge color="gray" size="sm" variant="soft">
                {pattern_count(shifts)}
              </.badge>
            </div>

            <div class="space-y-stack-tight">
              <div :for={rs <- shifts} id={"recurring_shifts-#{rs.id}"} class="group">
                <.surface_card class="p-inset-card">
                  <div class="flex flex-col gap-actions sm:flex-row sm:items-start sm:justify-between">
                    <div class="min-w-0">
                      <.link
                        navigate={~p"/locations/#{@location}/recurring_shifts/#{rs}"}
                        class="font-semibold text-text-primary dark:text-text-primary-dark hover:underline block truncate"
                      >
                        {rs.name}
                      </.link>
                      <p class="text-sm text-text-secondary dark:text-text-secondary-dark">
                        {Format.format_time_range(rs.start_time, rs.end_time)}
                      </p>
                    </div>
                    <div class="flex items-center gap-actions self-end shrink-0 sm:self-auto">
                      <.button
                        color="gray"
                        variant="ghost"
                        size="md"
                        to={~p"/locations/#{@location}/recurring_shifts/#{rs}/edit"}
                        link_type="live_redirect"
                        aria-label={gettext("Edit weekly pattern")}
                        class="opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200 hover:bg-surface-hover dark:hover:bg-surface-hover-dark"
                      >
                        <.icon name="hero-pencil-square" class="w-4 h-4" />
                      </.button>
                      <.button
                        color="danger"
                        variant="ghost"
                        size="md"
                        phx-click={PetalComponents.Modal.show_modal("delete-confirm-#{rs.id}")}
                        aria-label={gettext("Delete weekly pattern")}
                        class="opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-200"
                      >
                        <.icon name="hero-trash" class="w-4 h-4" />
                      </.button>
                    </div>
                  </div>

                  <div class="flex items-start gap-actions text-sm text-text-secondary dark:text-text-secondary-dark pt-separator-tight mt-card-block-end border-t border-border-divider dark:border-border-divider-dark">
                    <.icon name="hero-calendar" class="w-4 h-4 shrink-0" />
                    <span class="min-w-0 wrap-break-word">{effective_range_summary(rs)}</span>
                  </div>
                </.surface_card>

                <.delete_confirm_modal
                  title="Delete weekly pattern"
                  id={"delete-confirm-#{rs.id}"}
                  confirm_value={%{id: rs.id}}
                >
                  <p class="text-text-secondary dark:text-text-secondary-dark">
                    This removes the weekly pattern “{rs.name}” from {@location.name}. This action cannot be undone.
                  </p>
                </.delete_confirm_modal>
              </div>
            </div>
          </section>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"location_id" => location_id}, _session, socket) do
    case Shelter.get_location(location_id) do
      {:ok, location} ->
        recurring_shifts = Shelter.list_recurring_shifts_for_location!(location.id)

        socket =
          socket
          |> assign(:page_title, "Weekly shift patterns")
          |> assign(:location, location)
          |> assign_recurring_shifts(recurring_shifts)

        {:ok, socket}

      {:error, _error} ->
        {:ok, location_not_found(socket)}
    end
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, delete_recurring_shift(socket, id)}
  end

  defp delete_recurring_shift(socket, id) do
    with {:ok, rs} <- Shelter.get_recurring_shift(id),
         true <- rs.location_id == socket.assigns.location.id do
      destroy_recurring_shift(socket, rs)
    else
      _error -> put_flash(socket, :error, "Weekly pattern not found")
    end
  end

  defp destroy_recurring_shift(socket, rs) do
    case Shelter.destroy_recurring_shift(rs) do
      :ok ->
        recurring_shifts = Enum.reject(socket.assigns.recurring_shifts, &(&1.id == rs.id))

        socket
        |> put_flash(:info, "Weekly pattern deleted successfully")
        |> assign_recurring_shifts(recurring_shifts)

      {:error, _error} ->
        put_flash(socket, :error, "Could not delete weekly pattern")
    end
  end

  defp location_not_found(socket) do
    socket
    |> put_flash(:error, "Location not found")
    |> push_navigate(to: ~p"/locations")
  end

  defp assign_recurring_shifts(socket, recurring_shifts) do
    socket
    |> assign(:recurring_shifts, recurring_shifts)
    |> assign(:weekday_sections, weekday_sections(recurring_shifts))
  end

  defp weekday_sections(recurring_shifts) do
    grouped = Enum.group_by(recurring_shifts, & &1.day_of_week)

    Enum.flat_map(Day.ordered(), fn {day_number, day_label} ->
      case Map.get(grouped, day_number, []) do
        [] -> []
        shifts -> [{day_number, day_label, shifts}]
      end
    end)
  end

  defp pattern_count([_]), do: "1 pattern"
  defp pattern_count(shifts), do: "#{length(shifts)} patterns"

  defp effective_range_summary(rs) do
    case {rs.start_date, rs.end_date} do
      {nil, nil} ->
        "Active every week"

      {%Date{} = start_date, nil} ->
        "Active from #{Format.format_date(start_date)}"

      {nil, %Date{} = end_date} ->
        "Active until #{Format.format_date(end_date)} (end date not included)"

      {%Date{} = start_date, %Date{} = end_date} ->
        "Active #{Format.format_date(start_date)} until #{Format.format_date(end_date)} (end date not included)"
    end
  end
end
