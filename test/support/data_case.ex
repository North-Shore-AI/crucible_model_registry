defmodule CrucibleModelRegistry.DataCase do
  @moduledoc """
  Test case with database sandboxing helpers.
  """

  use ExUnit.CaseTemplate

  alias CrucibleModelRegistry.Repo
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias CrucibleModelRegistry.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import CrucibleModelRegistry.DataCase
      import CrucibleModelRegistry.Factory
      import Mox

      setup :set_mox_from_context
      setup :verify_on_exit!
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    :ok
  end

  @doc "Returns a map of changeset errors."
  @spec errors_on(Ecto.Changeset.t()) :: map()
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
