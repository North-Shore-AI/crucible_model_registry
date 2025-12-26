import Config

config :crucible_model_registry, CrucibleModelRegistry.Repo,
  database: "crucible_model_registry_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :crucible_model_registry,
  storage_backend: :noop,
  storage_opts: []
