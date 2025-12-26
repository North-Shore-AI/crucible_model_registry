import Config

config :crucible_model_registry,
  ecto_repos: [CrucibleModelRegistry.Repo],
  storage_backend: CrucibleModelRegistry.Storage.Noop,
  storage_opts: []

# Disable crucible_framework's built-in repo since we use our own
config :crucible_framework, enable_repo: false

config :crucible_model_registry, CrucibleModelRegistry.Repo,
  database: "crucible_model_registry_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10

import_config "#{config_env()}.exs"
