defmodule CrucibleModelRegistry.Application do
  @moduledoc "OTP application for crucible_model_registry."

  use Application

  @doc false
  @impl true
  def start(_type, _args) do
    children = [
      CrucibleModelRegistry.Repo
    ]

    opts = [strategy: :one_for_one, name: CrucibleModelRegistry.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
