defmodule Sunstone.Repo do
  use Ecto.Repo,
    otp_app: :sunstone,
    adapter: Ecto.Adapters.Postgres
end
