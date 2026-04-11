---
name: explain-elixir
description: >-
  How to explain Elixir, Phoenix, OTP, and Ash to developers whose main
  background is Django/Python. Use when teaching concepts, reviewing unfamiliar
  code, or when someone asks for Elixir context or analogies.
---

# Explain Elixir (for Django/Python developers)

## Audience and context

Primary readers are **Django/Python** developers contributing to this project who are new or newer to Elixir.

Maintainer context (optional, for tone):

- Familiar with OTP ideas (e.g. from "Elixir in Action") but refreshers are welcome when relevant.
- Day-job experience: Django/Python and JavaScript; some Go and C/C++ in the past.
- This codebase may be the most ambitious Elixir project some contributors have touched—assume **thoughtful pacing**, not trivia quizzes.

## How to explain

1. **Depth**: Cover the concept, the **why**, and **trade-offs**—not only the syntax.
2. **Analogies**: Use **Python/Django** comparisons when they genuinely clarify; avoid forced one-to-one mappings that mislead.
3. **OTP**: Give **OTP refreshers** when processes, supervision, or message passing matter to the code in question.
4. **Scope**: Tie explanations to **this repo’s patterns** (Phoenix, LiveView, Ecto/Ash as applicable) when possible.

## Django / Python → Elixir quick map

Use these as **starting points**, not strict equivalences:

| Django / Python | Elixir ecosystem (typical) |
|-----------------|----------------------------|
| `manage.py`, ASGI/WSGI app | Mix tasks, `Application` → `Endpoint` → `Router` |
| URLconf + views | `Router` scopes, `Controller` actions, `LiveView` |
| ORM models + `QuerySet` | Ecto schemas + `Ecto.Query`; or **Ash** resources and actions |
| `forms.Form` / DRF serializers | Changesets (`Ecto.Changeset`), `Phoenix.Component` forms |
| Middleware | `Plug` pipeline |
| Django signals (use sparingly) | PubSub, processes, or explicit domain calls—prefer explicit flows |
| `async` / threads (CPython) | Processes, `Task`, `GenServer`; **immutable** data by default |
| `import` / packages | `alias`, `import`, `require`; apps under `lib/` |
| Templates (Django templates) | HEEx (`~H`, `.heex`), function components |
| `settings.py` | `config/config.exs`, `runtime.exs`, env-specific config |
| Migrations | `mix ecto.migrate` (Ecto migrations) |

## Immutable data and errors

- Elixir favors **immutable** values and **explicit** error handling (`{:ok, _}` / `{:error, _}`) over exceptions for control flow.
- When comparing to Python, call out that **rebinding** (`x = f(x)`) is normal; there is no mutable “object state” in the small the way instance attributes often work in Python unless you use processes or ETS intentionally.

## When to use this skill

- A contributor asks **what something in Elixir/Phoenix/Ash means**.
- You are writing or reviewing explanations, onboarding notes, or PR comments for **Django-first** teammates.
- Concepts touch **OTP**, **concurrency**, or **fault tolerance** and need a grounded explanation.

Do **not** treat this file as a substitute for official docs—link to hexdocs when teaching APIs or module behavior.
