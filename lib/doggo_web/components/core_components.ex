defmodule DoggoWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

    * [Petal Components](https://petal.build/components) - a Phoenix components
      library for LiveView and HTML. Use Petal's `<.button>`, `<.alert>`, `<.badge>`,
      `<.field>` components in your templates.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing. Use `dark:` variants for dark mode.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  Dark mode is class-based using the `dark:` variant. Add the `dark` class
  to the `<html>` element to enable dark mode.
  """
  use Phoenix.Component
  use Gettext, backend: DoggoWeb.Gettext

  import PetalComponents.Alert
  import PetalComponents.Button
  import PetalComponents.Icon
  import PetalComponents.Modal

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices using Petal Components Alert.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :autoshow, :boolean, default: true, doc: "whether to auto show the flash on mount"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    flash_color =
      case assigns.kind do
        :info -> "info"
        :error -> "danger"
      end

    assigns = assign(assigns, :flash_color, flash_color)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      role="alert"
      class="fixed top-4 right-4 z-50"
      {@rest}
    >
      <.alert
        color={@flash_color}
        variant="soft"
        with_icon
        on_dismiss={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
        close_button_properties={[aria_label: gettext("close")]}
      >
        <p :if={@title} class="font-semibold">{@title}</p>
        <p>{msg}</p>
      </.alert>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-text-primary dark:text-text-primary-dark">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-text-secondary dark:text-text-secondary-dark">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="flex gap-inline mt-error-block text-sm leading-6 text-text-danger dark:text-text-danger-dark">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="divide-y divide-border-divider dark:divide-border-divider-dark">
      <li :for={item <- @item} class="py-list-row">
        <div class="font-medium text-text-primary dark:text-text-primary-dark">{item.title}</div>
        <div class="text-text-secondary dark:text-text-secondary-dark">{render_slot(item)}</div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a card container with consistent surface, border, and optional hover styles.

  * `variant="interactive"` (default) — list/index cards: resting `shadow-card` and hover lift.
  * `variant="static"` — forms and read-only panels: no hover affordance on the container.

  ## Examples

      <.surface_card class="p-inset-card">
        <p>Card content</p>
      </.surface_card>
  """
  attr :variant, :string, default: "interactive", doc: "interactive | static"
  attr :class, :string, default: nil, doc: "additional Tailwind classes"
  slot :inner_block, required: true

  def surface_card(assigns) do
    ~H"""
    <div class={[
      "bg-surface dark:bg-surface-dark border border-border-default dark:border-border-default-dark",
      "rounded-lg shadow-card",
      "transition-all duration-200",
      @variant == "interactive" &&
        [
          "hover:shadow-card-hover",
          "hover:border-border-accent dark:hover:border-border-accent-dark"
        ],
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Empty state for stream-based index lists. Render as a direct child of the
  `phx-update="stream"` container, sibling to streamed row elements.
  """
  attr :id, :string, required: true
  attr :icon, :string, required: true, doc: "e.g. hero-home-modern"
  attr :title, :string, required: true
  attr :subtitle, :string, required: true
  attr :class, :string, default: nil
  slot :cta, doc: "primary call to action (e.g. a Petal button)"

  def empty_state(assigns) do
    ~H"""
    <div id={@id} class={["hidden only:block text-center py-empty-state", @class]}>
      <.icon
        name={@icon}
        class="w-16 h-16 mx-auto text-text-secondary dark:text-text-secondary-dark mb-empty-cta"
      />
      <h3 class="text-lg font-medium text-text-primary dark:text-text-primary-dark">
        {@title}
      </h3>
      <p class="text-text-secondary dark:text-text-secondary-dark mt-empty-prose mb-empty-cta">
        {@subtitle}
      </p>
      {render_slot(@cta)}
    </div>
    """
  end

  @doc """
  Renders a back navigation button with an arrow icon.

  ## Examples

      <.back_button to={~p"/locations"} />
  """
  attr :to, :string, required: true
  attr :size, :string, default: "sm"
  attr :rest, :global

  def back_button(assigns) do
    ~H"""
    <.button
      color="gray"
      variant="ghost"
      size={@size}
      to={@to}
      link_type="live_redirect"
      aria-label={gettext("Back")}
      {@rest}
    >
      <.icon name="hero-arrow-left" class="w-5 h-5" />
    </.button>
    """
  end

  @doc """
  Renders a Petal modal to confirm destructive delete actions.

  Expects a LiveView handler for `confirm_event`. Open the modal from the template
  with `PetalComponents.Modal.show_modal/1` using the same `id` (default `"delete-confirm"`).

  ## Examples

      <.delete_confirm_modal
        title={gettext("Delete Location")}
        confirm_value={%{id: location.id}}
      >
        <p class="text-text-secondary dark:text-text-secondary-dark">{gettext("Are you sure?")}</p>
      </.delete_confirm_modal>
  """
  attr :id, :string, default: "delete-confirm"
  attr :title, :string, required: true
  attr :confirm_event, :string, default: "confirm_delete"
  attr :confirm_value, :map, default: %{}

  slot :inner_block, required: true

  def delete_confirm_modal(assigns) do
    ~H"""
    <.modal id={@id} hide title={@title} on_cancel={%JS{}}>
      {render_slot(@inner_block)}
      <div class="flex items-center justify-end gap-actions mt-block-actions">
        <.button
          color="gray"
          variant="outline"
          type="button"
          phx-click={JS.exec("data-cancel", to: "##{@id}")}
        >
          Cancel
        </.button>
        <.button
          color="danger"
          type="button"
          phx-click={JS.push(@confirm_event, value: @confirm_value)}
        >
          <.icon name="hero-trash" class="w-4 h-4 mr-1" /> {gettext("Delete")}
        </.button>
      </div>
    </.modal>
    """
  end

  ## JS Commands
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(DoggoWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(DoggoWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
