defmodule Doggo.Repo do
  use Ecto.Repo,
    otp_app: :doggo,
    adapter: Ecto.Adapters.Postgres
end
