# Doggo
Doggo is intended to be an open source project to build a webapp for dog shelters to either self host or deploy easily using a PaaS. The app is designed to help volunteers smoothly run operations at dog shelters. Tasks at the dog shelter include:
- Walking the dogs and reporting any happenings during the walk
- Cleaning dog enclosures
- Scheduling adoption appointments
- Ensuring dogs have gotten necessary veterinary care

## Tech Stack
- This project uses Elixir and relies heavily on Phoenix LiveView and Ash Framework.
- We use Salad UI `salad_ui` for styled LiveView components, use these instead of Phoenix's built-in DaisyUI. You can reference them in the `deps` folder if you need to find a component or understand its API

# Contributing to the repository
- Whenever you make changes, use red-green TDD to validate your changes
- Favor integration style tests over unit tests, as they allow for easier refactoring
- You **MUST** run `mix precommit` before considering any task done, fix any compilation errors or test failures before considering the task complete

## Design/UX
This is a webapp that will be most heavily used on mobile phones, as volunteers will likely not have a laptop readily available at the shelter, so **mobile-first** design is a key consideration
