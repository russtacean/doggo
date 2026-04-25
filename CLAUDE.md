# Doggo
Doggo is intended to be an open source project to build a webapp for dog shelters to either self host or deploy easily using a PaaS. The app is designed to help volunteers smoothly run operations at dog shelters. Tasks at the dog shelter include:
- Walking the dogs and reporting any happenings during the walk
- Cleaning dog enclosures
- Scheduling adoption appointments
- Ensuring dogs have gotten necessary veterinary care

## Tech Stack
- This project uses Elixir and relies heavily on Phoenix LiveView and Ash Framework.
- We use [Petal Components](https://petal.build/components) `petal_components` for styled LiveView components. Use the component-function approach (`<.button>`, `<.alert>`, `<.badge>`, `<.field>`) in templates.

## Petal Components Usage
- **Button**: `<.button color="primary" variant="solid">Label</.button>`
  - Colors: primary, secondary, info, success, warning, danger, gray
  - Variants: solid, light, outline, inverted, shadow, ghost
  - Sizes: xs, sm, md, lg, xl
- **Alert**: `<.alert color="info" variant="soft" with_icon>message</.alert>`
  - Colors: info, success, warning, danger
  - Variants: light, soft, dark, outline
- **Badge**: `<.badge color="warning" size="sm">label</.badge>`
- **Field**: For form inputs, use `<.field type="text" label="Name" field={@form[:name]} />`

## Dark Mode
- Use Tailwind's `dark:` variant (e.g., `dark:bg-gray-800`)
- Add/remove `dark` class on `<html>` element for class-based dark mode

# Contributing to the repository
- Whenever you make changes, use red-green TDD to validate your changes
- Favor integration style tests over unit tests, as they allow for easier refactoring
- You **MUST** run `mix precommit` before considering any task done, fix any compilation errors or test failures before considering the task complete

## Interval Conventions
All time and date intervals in the app use an **inclusive start, exclusive end** convention:
- `start_time` is the first moment the interval is active.
- `end_time` is the first moment the interval is no longer active.
- `start_date` is the first date the pattern is active (inclusive).
- `end_date` is the first date the pattern is no longer active (exclusive).

This allows adjacent intervals to share the same boundary (e.g. a shift ending at 12:00 and the next shift starting at 12:00) without overlap.

## Design/UX
This is a webapp that will be most heavily used on mobile phones, as volunteers will likely not have a laptop readily available at the shelter, so **mobile-first** design is a key consideration
