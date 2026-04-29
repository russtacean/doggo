defmodule DoggoWeb.EnclosureLive.Form do
  use DoggoWeb, :live_view

  alias Doggo.Shelter
  alias Doggo.Shelter.EnclosureStatus

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:enclosures} location={@location}>
      <.header>
        <div class="flex items-center gap-inline">
          <.back_button to={return_path(@return_to, @location, @enclosure)} />
          <span class="text-text-primary dark:text-text-primary-dark">{@page_title}</span>
        </div>
        <:subtitle>
          {if is_nil(@enclosure),
            do: "Add a new enclosure for #{@location.name}",
            else: "Edit enclosure details"}
        </:subtitle>
      </.header>

      <.surface_card variant="static" class="p-inset-card-lg">
        <.form
          for={@form}
          id="enclosure-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-stack-form"
        >
          <.field
            type="text"
            label="Name"
            field={@form[:name]}
            required
            placeholder="e.g., Kennel A1"
          />

          <.field
            type="select"
            label="Status"
            field={@form[:status]}
            options={EnclosureStatus.form_select_options()}
            required
          />

          <div class="flex items-center justify-between pt-separator-comfort border-t border-border-divider dark:border-border-divider-dark">
            <.button
              color="gray"
              variant="ghost"
              to={return_path(@return_to, @location, @enclosure)}
              link_type="live_redirect"
            >
              Cancel
            </.button>
            <.button type="submit" color="primary" phx-disable-with="Saving...">
              <.icon name="hero-check" class="w-4 h-4 mr-1" /> Save Enclosure
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

    with {:ok, location} <- Shelter.get_location(params["location_id"]),
         {:ok, enclosure} <- fetch_enclosure(params),
         true <- is_nil(enclosure) or enclosure.location_id == location.id do
      {:ok, assign_enclosure_form(socket, location, enclosure, return_to)}
    else
      {:error, _error} -> {:ok, not_found(socket, ~p"/locations")}
      false -> {:ok, not_found(socket, ~p"/locations/#{params["location_id"]}/enclosures")}
    end
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"enclosure" => enclosure_params}, socket) do
    {:noreply,
     assign(
       socket,
       form:
         AshPhoenix.Form.validate(
           socket.assigns.form,
           params_with_location(socket, enclosure_params)
         )
     )}
  end

  def handle_event("save", %{"enclosure" => enclosure_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form,
           params: params_with_location(socket, enclosure_params)
         ) do
      {:ok, enclosure} ->
        action = if is_nil(socket.assigns.enclosure), do: "created", else: "updated"

        socket =
          socket
          |> put_flash(:info, "Enclosure #{action} successfully")
          |> push_navigate(
            to: return_path(socket.assigns.return_to, socket.assigns.location, enclosure)
          )

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp assign_form(%{assigns: %{enclosure: enclosure, location: location}} = socket) do
    form =
      if enclosure do
        Shelter.form_to_update_enclosure(enclosure, as: "enclosure")
      else
        Shelter.form_to_create_enclosure_at_location(
          as: "enclosure",
          params: %{"location" => location.id}
        )
      end

    assign(socket, form: to_form(form))
  end

  defp assign_enclosure_form(socket, location, enclosure, return_to) do
    page_title = if is_nil(enclosure), do: "New Enclosure", else: "Edit Enclosure"

    socket
    |> assign(:return_to, return_to)
    |> assign(:location, location)
    |> assign(:enclosure, enclosure)
    |> assign(:page_title, page_title)
    |> assign_form()
  end

  defp params_with_location(%{assigns: %{enclosure: nil, location: location}}, params) do
    Map.put(params, "location", location.id)
  end

  defp params_with_location(_socket, params), do: params

  defp fetch_enclosure(%{"id" => id}), do: Shelter.get_enclosure(id)
  defp fetch_enclosure(_params), do: {:ok, nil}

  defp not_found(socket, path) do
    socket
    |> put_flash(:error, "Enclosure not found")
    |> push_navigate(to: path)
  end

  defp return_path("index", location, _enclosure), do: ~p"/locations/#{location}/enclosures"
  defp return_path("show", location, nil), do: ~p"/locations/#{location}/enclosures"

  defp return_path("show", location, enclosure),
    do: ~p"/locations/#{location}/enclosures/#{enclosure}"

  defp return_path(_, location, _enclosure), do: ~p"/locations/#{location}/enclosures"
end
