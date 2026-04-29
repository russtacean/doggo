defmodule DoggoWeb.Layouts do
  @moduledoc false
  use DoggoWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :current_page, :atom, default: :locations, doc: "the current navigation item"
  attr :location, :any, default: nil, doc: "the selected location for location-scoped navigation"

  slot :inner_block, required: true

  def app(assigns) do
    assigns =
      assigns
      |> assign(:current_page, nav_current_page(assigns.current_page))
      |> assign(:menu_items, main_menu_items(assigns))
      |> assign(:location_name, location_name(assigns.location))

    ~H"""
    <div class="min-h-dvh bg-surface-inset dark:bg-surface-inset-dark">
      <header class="sticky top-0 z-30 flex items-center justify-between gap-3 border-b border-border-default bg-surface/95 px-4 pb-3 pt-[max(0.75rem,env(safe-area-inset-top))] backdrop-blur dark:border-border-default-dark dark:bg-surface-dark/95 lg:hidden">
        <a href={~p"/locations"} class="flex min-w-0 items-center gap-3">
          <img src={~p"/images/logo.svg"} width="36" height="36" alt="Doggo" />
          <div class="min-w-0">
            <p class="text-sm font-semibold leading-5 text-text-primary dark:text-text-primary-dark">
              Doggo
            </p>
            <p class="truncate text-xs text-text-secondary dark:text-text-secondary-dark">
              {@location_name || "Shelter operations"}
            </p>
          </div>
        </a>
        <button
          type="button"
          class="inline-flex min-h-11 min-w-11 items-center justify-center rounded-lg border border-border-default bg-surface text-text-primary shadow-card active:scale-95 dark:border-border-default-dark dark:bg-surface-dark dark:text-text-primary-dark"
          aria-label={gettext("Open navigation")}
          phx-click={JS.remove_class("hidden", to: "#app-nav-shell")}
        >
          <.icon name="hero-bars-3" class="h-6 w-6" />
        </button>
      </header>

      <div
        id="app-nav-shell"
        class="fixed inset-0 z-50 hidden lg:pointer-events-none lg:block"
      >
        <button
          type="button"
          class="absolute inset-0 h-full w-full bg-gray-900/50 lg:hidden"
          aria-label={gettext("Close navigation")}
          phx-click={JS.add_class("hidden", to: "#app-nav-shell")}
        />
        <aside class="relative flex h-full w-60 max-w-[65vw] flex-col border-r border-border-default bg-surface shadow-modal dark:border-border-default-dark dark:bg-surface-dark lg:pointer-events-auto lg:fixed lg:inset-y-0 lg:left-0 lg:w-60 lg:max-w-none lg:shadow-none">
          <div class="flex items-center justify-between gap-3 border-b border-border-divider px-4 pb-3 pt-[max(0.75rem,env(safe-area-inset-top))] dark:border-border-divider-dark">
            <.brand_lockup location_name={@location_name} logo_size={36} />
            <button
              type="button"
              class="inline-flex min-h-11 min-w-11 items-center justify-center rounded-lg text-text-secondary hover:bg-surface-hover hover:text-text-primary active:scale-95 dark:text-text-secondary-dark dark:hover:bg-surface-hover-dark dark:hover:text-text-primary-dark lg:hidden"
              aria-label={gettext("Close navigation")}
              phx-click={JS.add_class("hidden", to: "#app-nav-shell")}
            >
              <.icon name="hero-x-mark" class="h-6 w-6" />
            </button>
          </div>
          <.app_nav
            id="desktop-main-nav"
            menu_items={@menu_items}
            current_page={@current_page}
            class="flex-1 overflow-y-auto p-4"
          />
          <div class="border-t border-border-divider p-4 dark:border-border-divider-dark">
            <.theme_toggle />
          </div>
        </aside>
      </div>

      <div class="lg:pl-72">
        <main class="px-4 py-6 sm:px-6 lg:px-8 lg:py-10">
          <div class="mx-auto max-w-form space-y-4">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :location_name, :string, default: nil
  attr :logo_size, :integer, default: 40

  defp brand_lockup(assigns) do
    ~H"""
    <a href={~p"/locations"} class="flex min-w-0 items-center gap-3">
      <img src={~p"/images/logo.svg"} width={@logo_size} height={@logo_size} alt="Doggo" />
      <div class="min-w-0">
        <p class={[
          "font-semibold text-text-primary dark:text-text-primary-dark",
          @logo_size == 36 && "text-sm leading-5",
          @logo_size == 40 && "text-base leading-6"
        ]}>
          Doggo
        </p>
        <p class={[
          "truncate text-text-secondary dark:text-text-secondary-dark",
          @logo_size == 36 && "text-xs",
          @logo_size == 40 && "text-sm"
        ]}>
          {@location_name || "Shelter operations"}
        </p>
      </div>
    </a>
    """
  end

  attr :menu_items, :list, required: true
  attr :current_page, :atom, required: true
  attr :id, :string, required: true
  attr :class, :string, default: nil

  defp app_nav(assigns) do
    assigns =
      assigns
      |> assign(:menu_items, namespace_menu_items(assigns.menu_items, assigns.id))
      |> assign(:current_page, namespace_name(assigns.current_page, assigns.id))

    ~H"""
    <nav id={@id} class={@class} aria-label={gettext("Main navigation")}>
      <.vertical_menu menu_items={@menu_items} current_page={@current_page} js_lib="live_view_js" />
    </nav>
    """
  end

  defp namespace_menu_items(menu_items, namespace) do
    Enum.map(menu_items, fn menu_item ->
      menu_item
      |> Map.update!(:name, &namespace_name(&1, namespace))
      |> Map.update(:menu_items, nil, &namespace_menu_items(&1, namespace))
    end)
  end

  defp namespace_name(name, namespace), do: :"#{namespace}_#{name}"

  defp main_menu_items(assigns) do
    [
      %{
        name: :locations,
        label: "Shelter",
        path: ~p"/locations",
        icon: "hero-building-office-2"
      }
    ] ++ location_menu_items(assigns.location)
  end

  defp location_menu_items(nil), do: []

  defp location_menu_items(location) do
    [
      %{
        name: :location_setup,
        label: "Location setup",
        icon: "hero-map-pin",
        menu_items: [
          %{
            name: :location_overview,
            label: "Overview",
            path: ~p"/locations/#{location}",
            icon: "hero-clipboard-document-list"
          },
          %{
            name: :enclosures,
            label: "Enclosures",
            path: ~p"/locations/#{location}/enclosures",
            icon: "hero-home-modern"
          },
          %{
            name: :scheduled_shifts,
            label: "Scheduled shifts",
            path: ~p"/locations/#{location}/scheduled_shifts",
            icon: "hero-calendar-days"
          },
          %{
            name: :recurring_shifts,
            label: "Weekly patterns",
            path: ~p"/locations/#{location}/recurring_shifts",
            icon: "hero-arrow-path"
          }
        ]
      }
    ]
  end

  defp nav_current_page(nil), do: :locations
  defp nav_current_page(current_page), do: current_page

  defp location_name(nil), do: nil
  defp location_name(%{name: name}), do: name
  defp location_name(_location), do: nil

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div
      id="theme-toggle"
      class="relative flex flex-row items-center border-2 border-gray-300 dark:border-gray-600 bg-gray-100 dark:bg-gray-700 rounded-full p-1"
    >
      <%!-- Indicator positioned based on data-theme attribute --%>
      <div
        id="theme-indicator"
        class="absolute w-1/3 h-[calc(100%-0.5rem)] rounded-full bg-white dark:bg-gray-500 shadow-md transition-all duration-300 left-1"
        data-theme="system"
      />

      <button
        class="flex p-2 cursor-pointer w-1/3 relative z-10 justify-center"
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "system"})}
        data-theme="system"
      >
        <.icon
          name="hero-computer-desktop-micro"
          class="size-4 text-gray-700 dark:text-gray-300 opacity-75 hover:opacity-100"
        />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3 relative z-10 justify-center"
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "light"})}
        data-theme="light"
      >
        <.icon
          name="hero-sun-micro"
          class="size-4 text-gray-700 dark:text-gray-300 opacity-75 hover:opacity-100"
        />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3 relative z-10 justify-center"
        phx-click={JS.dispatch("phx:set-theme", detail: %{theme: "dark"})}
        data-theme="dark"
      >
        <.icon
          name="hero-moon-micro"
          class="size-4 text-gray-700 dark:text-gray-300 opacity-75 hover:opacity-100"
        />
      </button>
    </div>
    """
  end
end
