defmodule DoggoWeb.ScheduledShiftLive.Form do
  use DoggoWeb, :live_view

  alias Doggo.Shelter

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:scheduled_shifts} location={@location}>
      <.header>
        <div class="flex items-center gap-inline">
          <.back_button to={return_path(@return_to, @location, @scheduled_shift)} />
          <span class="text-text-primary dark:text-text-primary-dark">{@page_title}</span>
        </div>
        <:subtitle>
          {if is_nil(@scheduled_shift),
            do: "Add a scheduled shift for #{@location.name}",
            else: "Edit this scheduled shift"}
        </:subtitle>
      </.header>

      <.surface_card variant="static" class="p-inset-card-lg">
        <.form
          for={@form}
          id="scheduled-shift-form"
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

          <.field type="date" label="Date" field={@form[:date]} required />

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
            Scheduled shifts happen once on the selected date and time.
          </p>

          <div class="flex items-center justify-between pt-separator-comfort border-t border-border-divider dark:border-border-divider-dark">
            <.button
              color="gray"
              variant="ghost"
              to={return_path(@return_to, @location, @scheduled_shift)}
              link_type="live_redirect"
            >
              Cancel
            </.button>
            <.button type="submit" color="primary" phx-disable-with="Saving...">
              <.icon name="hero-check" class="w-4 h-4 mr-1" /> Save scheduled shift
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
  def handle_event("validate", %{"scheduled_shift" => scheduled_shift_params}, socket) do
    {:noreply,
     assign(
       socket,
       form:
         AshPhoenix.Form.validate(
           socket.assigns.form,
           params_with_location(socket, scheduled_shift_params)
         )
     )}
  end

  def handle_event("save", %{"scheduled_shift" => scheduled_shift_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form,
           params: params_with_location(socket, scheduled_shift_params)
         ) do
      {:ok, scheduled_shift} ->
        action = if is_nil(socket.assigns.scheduled_shift), do: "created", else: "updated"

        socket =
          socket
          |> put_flash(:info, "Scheduled shift #{action} successfully")
          |> push_navigate(
            to: return_path(socket.assigns.return_to, socket.assigns.location, scheduled_shift)
          )

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(%{assigns: %{scheduled_shift: scheduled_shift, location: location}} = socket) do
    form =
      if scheduled_shift do
        Shelter.form_to_update_scheduled_shift(scheduled_shift, as: "scheduled_shift")
      else
        Shelter.form_to_create_scheduled_shift_at_location(
          as: "scheduled_shift",
          params: %{"location" => location.id}
        )
      end

    assign(socket, form: to_form(form))
  end

  defp assign_scheduled_shift_form(socket, location, scheduled_shift, return_to) do
    page_title =
      if is_nil(scheduled_shift), do: "New scheduled shift", else: "Edit scheduled shift"

    socket
    |> assign(:return_to, return_to)
    |> assign(:location, location)
    |> assign(:scheduled_shift, scheduled_shift)
    |> assign(:page_title, page_title)
    |> assign_form()
  end

  defp load_form_for_location(socket, params, location, return_to) do
    case fetch_scheduled_shift(params) do
      {:ok, nil} ->
        assign_scheduled_shift_form(socket, location, nil, return_to)

      {:ok, scheduled_shift} when scheduled_shift.location_id == location.id ->
        assign_scheduled_shift_form(socket, location, scheduled_shift, return_to)

      {:ok, _scheduled_shift} ->
        not_found(socket, ~p"/locations/#{location}/scheduled_shifts")

      {:error, _error} ->
        not_found(socket, ~p"/locations/#{location}/scheduled_shifts")
    end
  end

  defp params_with_location(%{assigns: %{scheduled_shift: nil, location: location}}, params) do
    Map.put(params, "location", location.id)
  end

  defp params_with_location(_socket, params), do: params

  defp fetch_scheduled_shift(%{"id" => id}), do: Shelter.get_scheduled_shift(id)
  defp fetch_scheduled_shift(_params), do: {:ok, nil}

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

  defp return_path("index", location, _scheduled_shift),
    do: ~p"/locations/#{location}/scheduled_shifts"

  defp return_path("show", location, nil), do: ~p"/locations/#{location}/scheduled_shifts"

  defp return_path("show", location, scheduled_shift),
    do: ~p"/locations/#{location}/scheduled_shifts/#{scheduled_shift}"

  defp return_path(_, location, _scheduled_shift), do: ~p"/locations/#{location}/scheduled_shifts"
end
