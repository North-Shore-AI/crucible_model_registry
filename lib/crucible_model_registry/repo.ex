defmodule CrucibleModelRegistry.Repo do
  @moduledoc "Ecto repository for registry metadata storage."

  use Ecto.Repo,
    otp_app: :crucible_model_registry,
    adapter: Ecto.Adapters.Postgres
end
