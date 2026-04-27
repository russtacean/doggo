defmodule DoggoWeb.RecurringShiftLive.Form do
  use DoggoWeb, :live_view

  alias Doggo.Shelter
  alias Doggo.Shelter.RecurringShift.Day

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:recurring_shifts} location={@location}>
      <.header>
        <div class="flex items-center gap-inline">
          <.back_button to={return_path(@return_to, @location, @recurring_shift)} />
          <span class="text-text-primary dark:text-text-primary-dark">{@page_title}</span>
        </div>
        <:subtitle>
          {if is_nil(@recurring_shift),
            do: "Add a weekly pattern for #{@location.name}",
            else: "Edit this weekly pattern"}
        </:subtitle>
      </.header>

      <.surface_card variant="static" class="p-inset-card-lg">
        <.form
          for={@form}
          id="recurring-shift-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-stack-form"
        >
          <.field
            type="text"
            label="Name"
            field={@form[:name]}
            required
            placeholder="e.g., Morning walk"
          />

          <.field
            type="select"
            label="Day of week"
            field={@form[:day_of_week]}
            options={Day.form_select_options()}
            required
          />

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-field">
            <.field
              type="time"
              label="Start time"
              field={@form[:start_time]}
              required
            />
            <.field
              type="time"
              label="End time"
              field={@form[:end_time]}
              required
            />
          </div>
          <p class="text-sm text-text-secondary dark:text-text-secondary-dark -mt-2">
            This pattern repeats every week on the selected day and time.
          </p>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-field">
            <.field
              type="date"
              label="Start date (optional)"
              field={@form[:start_date]}
            />
            <.field
              type="date"
              label="End date (optional)"
              field={@form[:end_date]}
            />
          </div>
          <p class="text-sm text-text-secondary dark:text-text-secondary-dark -mt-2">
            Optional dates limit when this pattern is active. The end date is not included.
            Leave dates blank for an open-ended pattern.
          </p>

          <div class="flex items-center justify-between pt-separator-comfort border-t border-border-divider dark:border-border-divider-dark">
            <.button
              color="gray"
              variant="ghost"
              to={return_path(@return_to, @location, @recurring_shift)}
              link_type="live_redirect"
            >
              Cancel
            </.button>
            <.button type="submit" color="primary" phx-disable-with="Saving...">
              <.icon name="hero-check" class="w-4 h-4 mr-1" /> Save weekly pattern
            </.button>
          </div>
        </.form>
      </.surface_card>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    return_to = return_to(params["return_to"])

    case Shelter.get_location(params["location_id"]) do
      {:ok, location} ->
        {:ok, load_form_for_location(socket, params, location, return_to)}

      {:error, _error} ->
        {:ok, location_not_found(socket)}
    end
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"recurring_shift" => params}, socket) do
    {:noreply,
     assign(
       socket,
       form:
         AshPhoenix.Form.validate(
           socket.assigns.form,
           params_with_location(socket, normalize_recurring_params(params))
         )
     )}
  end

  def handle_event("save", %{"recurring_shift" => params}, socket) do
    merged = params_with_location(socket, normalize_recurring_params(params))

    case AshPhoenix.Form.submit(socket.assigns.form, params: merged) do
      {:ok, rs} ->
        action = if is_nil(socket.assigns.recurring_shift), do: "created", else: "updated"

        socket =
          socket
          |> put_flash(:info, "Weekly pattern #{action} successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, socket.assigns.location, rs))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(%{assigns: %{recurring_shift: recurring_shift, location: location}} = socket) do
    form =
      if recurring_shift do
        Shelter.form_to_update_recurring_shift(recurring_shift, as: "recurring_shift")
      else
        Shelter.form_to_create_recurring_shift(
          as: "recurring_shift",
          params: %{"location" => location.id}
        )
      end

    assign(socket, form: to_form(form))
  end

  defp assign_recurring_shift_form(socket, location, recurring_shift, return_to) do
    page_title =
      if is_nil(recurring_shift), do: "New weekly pattern", else: "Edit weekly pattern"

    socket
    |> assign(:return_to, return_to)
    |> assign(:location, location)
    |> assign(:recurring_shift, recurring_shift)
    |> assign(:page_title, page_title)
    |> assign_form()
  end

  defp load_form_for_location(socket, params, location, return_to) do
    case fetch_recurring_shift(params) do
      {:ok, nil} ->
        assign_recurring_shift_form(socket, location, nil, return_to)

      {:ok, recurring_shift} when recurring_shift.location_id == location.id ->
        assign_recurring_shift_form(socket, location, recurring_shift, return_to)

      {:ok, _recurring_shift} ->
        not_found(socket, ~p"/locations/#{location}/recurring_shifts")

      {:error, _error} ->
        not_found(socket, ~p"/locations/#{location}/recurring_shifts")
    end
  end

  defp params_with_location(
         %{assigns: %{recurring_shift: nil, location: location}},
         params
       ) do
    params
    |> Map.put("location", location.id)
  end

  defp params_with_location(_socket, params), do: params

  defp normalize_recurring_params(params) do
    params
    |> empty_to_nil("start_date")
    |> empty_to_nil("end_date")
  end

  defp empty_to_nil(params, key) do
    case Map.get(params, key) do
      "" -> Map.put(params, key, nil)
      _ -> params
    end
  end

  defp fetch_recurring_shift(%{"id" => id}), do: Shelter.get_recurring_shift(id)
  defp fetch_recurring_shift(_params), do: {:ok, nil}

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

  defp return_path("index", location, _rs), do: ~p"/locations/#{location}/recurring_shifts"
  defp return_path("show", location, nil), do: ~p"/locations/#{location}/recurring_shifts"

  defp return_path("show", location, rs), do: ~p"/locations/#{location}/recurring_shifts/#{rs}"
  defp return_path(_, location, _rs), do: ~p"/locations/#{location}/recurring_shifts"
end
