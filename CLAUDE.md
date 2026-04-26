# Doggo
Doggo is intended to be an open source project to build a webapp for dog shelters to either self host or deploy easily using a PaaS. The app is designed to help volunteers smoothly run operations at dog shelters. Tasks at the dog shelter include:
- Walking the dogs and reporting any happenings during the walk
- Cleaning dog enclosures
- Scheduling adoption appointments
- Ensuring dogs have gotten necessary veterinary care

## Tech Stack
- This project uses Elixir and relies heavily on Phoenix LiveView and Ash Framework.
- Phoenix heavily uses Tailwind v4 for styling
- We use [Petal Components](https://petal.build/components) `petal_components` for styled LiveView components. Use the component-function approach (`<.button>`, `<.alert>`, `<.badge>`, `<.field>`) in templates.

See the `phoenix-framework` skill for Phoenix/LiveView patterns (streams, forms, navigation) as needed
See the `ash-framework` skill for domain + resource patterns as needed.


## Design/UX
This is a webapp that will be most heavily used on mobile phones, as volunteers will likely not have a laptop readily available at the shelter, so **mobile-first** design is a key consideration

### Design Tokens
We use semantic design tokens for colors, spacing, and shadows. See `assets/css/semantic.css` for available tokens. Examples: `text-text-accent` (icons on accent chips), `shadow-card` (resting card shadow), `max-w-form` (primary content width, used in the app layout `main` wrapper).

### Core layout components (`lib/doggo_web/components/core_components.ex`)
- **`surface_card`**: `variant="interactive"` (default) for list cards and other browsable rows—resting `shadow-card` plus hover lift. `variant="static"` for form panels and read-only detail blocks so the whole surface does not look tappable.
- **`empty_state`**: Stream list empty states (icon, title, subtitle, optional `cta` slot) so index empty UIs stay consistent.
- **Delete confirm** and **flash** patterns live in the same module; prefer these over ad hoc markup.

### Micro-interactions
- Interactive `surface_card`: `shadow-card` at rest, then `hover:shadow-card-hover hover:border-border-accent dark:hover:border-border-accent-dark` (see component; list rows also use `group` and ghost actions as below).
- Button active: `active:scale-95` (built into Petal)
- Action visibility: Show edit/delete on hover with `opacity-100 sm:opacity-0 sm:group-hover:opacity-100` (always visible on mobile, hover-only on desktop)

# Contributing to the repository
- Whenever you make changes, use red-green TDD to validate your changes
- Favor integration style tests over unit tests, as they allow for easier refactoring
- You **MUST** run `mix precommit` before considering any task done, fix any compilation errors or test failures before considering the task complete
- If you use the Docker dev workflow (`make dc.up`, etc.), after pulling changes that touch `mix.lock` run `make dc.deps` (with the app container up) so Hex dependencies are fetched into `deps/devcontainer` — project deps are not baked into the image

## Interval Conventions
All time and date intervals in the app use an **inclusive start, exclusive end** convention:
- `start_time` is the first moment the interval is active.
- `end_time` is the first moment the interval is no longer active.
- `start_date` is the first date the pattern is active (inclusive).
- `end_date` is the first date the pattern is no longer active (exclusive).

This allows adjacent intervals to share the same boundary (e.g. a shift ending at 12:00 and the next shift starting at 12:00) without overlap.
