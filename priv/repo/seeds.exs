# Populates the database with demo / dev data.
#
#     mix run priv/repo/seeds.exs
#
# Force a fresh seed (drops canonical dev locations first, then re-inserts):
#
#     FORCE_DEV_SEED=1 mix run priv/repo/seeds.exs
#
# `mix setup` and `ecto.setup` also run this script. The seed is idempotent: it
# skips when the primary dev location (see `Doggo.DevSeed`) already exists.

force? = System.get_env("FORCE_DEV_SEED") in ~w(1 true yes)

Doggo.DevSeed.run(force: force?)
