ExUnit.start()

case CrucibleModelRegistry.Repo.start_link() do
  {:ok, _pid} -> :ok
  {:error, {:already_started, _pid}} -> :ok
end

Ecto.Adapters.SQL.Sandbox.mode(CrucibleModelRegistry.Repo, :manual)
