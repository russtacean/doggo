defmodule DoggoWeb.Layouts do
  @moduledoc false
  use DoggoWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="flex items-center justify-between px-4 sm:px-6 lg:px-8 py-4">
      <div class="flex-1">
        <a href="/" class="flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold text-gray-900 dark:text-gray-100">
            v{Application.spec(:phoenix, :vsn)}
          </span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex items-center gap-4">
          <li>
            <.button variant="ghost" link_type="a" to="https://phoenixframework.org/">
              Website
            </.button>
          </li>
          <li>
            <.button variant="ghost" link_type="a" to="https://github.com/phoenixframework/phoenix">
              GitHub
            </.button>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <.button color="primary" link_type="a" to="https://hexdocs.pm/phoenix/overview.html">
              Get Started <span aria-hidden="true">&rarr;</span>
            </.button>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-form space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

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
