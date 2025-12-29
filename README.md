# CrucibleModelRegistry

<p align="center">
  <img src="assets/crucible_model_registry.svg" alt="CrucibleModelRegistry Logo" width="200"/>
</p>

<p align="center">
  <strong>Platform-agnostic model registry for ML artifacts with versioning, lineage tracking, and storage backends</strong>
</p>

<p align="center">
  <a href="https://hex.pm/packages/crucible_model_registry"><img src="https://img.shields.io/hexpm/v/crucible_model_registry.svg" alt="Hex Version"/></a>
  <a href="https://hexdocs.pm/crucible_model_registry"><img src="https://img.shields.io/badge/hex-docs-blue.svg" alt="Hex Docs"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License"/></a>
</p>

---

## Features

- Ecto-backed metadata in Postgres
- Pluggable artifact storage (S3, HuggingFace Hub, local, noop)
- Lineage graph with cycle detection
- Query DSL for stage, metrics, recipe, base model, tags
- Deduplication by training config hash (SHA256)
- Crucible stage integrations for register/promote
- Telemetry events for register, promote, upload, download

## Installation

```elixir
def deps do
  [
    {:crucible_model_registry, path: "../crucible_model_registry"}
  ]
end
```

## Configuration

### Database Configuration (Oban Pattern)

CrucibleModelRegistry uses dynamic repo injection - your host application provides the Repo:

```elixir
import Config

config :crucible_model_registry,
  repo: MyApp.Repo,  # Required: host app's Repo module
  storage_backend: :s3,
  storage_opts: [
    bucket: "my-model-artifacts",
    region: "us-east-1"
  ]

# Your host app's Repo configuration
config :my_app, MyApp.Repo,
  database: "my_app_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

Then start your Repo in your application's supervision tree:

```elixir
# lib/my_app/application.ex
children = [
  MyApp.Repo,
  # ... other children
]
```

### Migrations

Copy migrations from `deps/crucible_model_registry/priv/repo/migrations/` or run:

```bash
mix crucible_model_registry.install
```

### Legacy Mode

For backwards compatibility, set `start_repo: true` to auto-start internal Repo:

```elixir
config :crucible_model_registry,
  start_repo: true,
  ecto_repos: [CrucibleModelRegistry.Repo]

config :crucible_model_registry, CrucibleModelRegistry.Repo,
  database: "crucible_model_registry_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

Supported storage backends:
- `:s3` → `CrucibleModelRegistry.Storage.S3`
- `:huggingface` → `CrucibleModelRegistry.Storage.HuggingFace`
- `:local` → `CrucibleModelRegistry.Storage.Local` (needs `storage_opts: [base_path: "..."]`)
- `:noop` → `CrucibleModelRegistry.Storage.Noop`

## Migrations

```bash
mix ecto.create
mix ecto.migrate
```

## Basic Usage

```elixir
{:ok, version} =
  CrucibleModelRegistry.register(%{
    model_name: "llama-3.1-8b-sft",
    version: "1.0.0",
    recipe: "sl_basic",
    base_model: "meta-llama/Llama-3.1-8B",
    training_config: %{"lr" => 1.0e-4},
    metrics: %{"accuracy" => 0.92},
    artifacts: [
      %{type: :checkpoint, storage_backend: :s3, storage_path: "s3://bucket/path"}
    ]
  })

{:ok, version} = CrucibleModelRegistry.promote(version, :staging)
{:ok, version} = CrucibleModelRegistry.promote(version, :production)
```

## Query DSL

```elixir
CrucibleModelRegistry.Query.new()
|> CrucibleModelRegistry.Query.where_stage(:production)
|> CrucibleModelRegistry.Query.where_metric("accuracy", :gte, 0.9)
|> CrucibleModelRegistry.Query.where_recipe("sl_basic")
|> CrucibleModelRegistry.Query.limit(10)
|> CrucibleModelRegistry.Query.execute()
```

Or using filter maps:

```elixir
CrucibleModelRegistry.query(%{
  stage: :production,
  recipe: "sl_basic",
  min_accuracy: 0.9
})
```

## Lineage

```elixir
ancestors = CrucibleModelRegistry.get_ancestors(version)
descendants = CrucibleModelRegistry.get_descendants(version)
```

## Artifacts

```elixir
{:ok, artifact} = CrucibleModelRegistry.upload_artifact(version, :checkpoint, "/tmp/model.bin")
:ok = CrucibleModelRegistry.download_artifact(artifact, "/tmp/model.bin")
```

## Model Registry Stages

This package provides Crucible stages for model lifecycle management:

- `:model_register` - Register trained model versions with lineage tracking
- `:model_promote` - Promote model versions through lifecycle stages

All stages implement the `Crucible.Stage` behaviour with full describe/1 schemas.

### Register Stage

Registers a trained model version in the model registry.

#### Required Options

| Option | Type | Description |
|--------|------|-------------|
| `:model_name` | `:string` | Name of the model |
| `:recipe` | `:atom` | Training recipe used |
| `:base_model` | `:string` | Base model identifier |

#### Optional Options

| Option | Type | Description |
|--------|------|-------------|
| `:version` | `:string` | Version string (auto-generated if not provided) |
| `:training_config` | `:map` | Training configuration |
| `:artifacts` | `{:list, :map}` | List of artifact metadata |
| `:parent_version_id` | `:string` | Parent version for lineage |
| `:lineage_type` | `{:enum, [:fine_tune, :distillation, :merge]}` | Type of lineage relationship |

#### Example

```elixir
CrucibleModelRegistry.Stages.Register.run(context,
  model_name: "math-tutor",
  version: "1.0.0",
  recipe: :sl_basic,
  base_model: "meta-llama/Llama-3.1-8B",
  training_config: %{"lr" => 1.0e-4}
)
```

### Promote Stage

Promotes a model version to a lifecycle stage.

#### Required Options

| Option | Type | Description |
|--------|------|-------------|
| `:stage` | `{:enum, [:development, :staging, :production, :archived]}` | Target lifecycle stage |

#### Optional Options

| Option | Type | Description |
|--------|------|-------------|
| `:version` | `:map` | Model version (uses context artifact if not provided) |

#### Example

```elixir
CrucibleModelRegistry.Stages.Promote.run(context, stage: :production)
```

## Telemetry

Events emitted:
- `[:crucible_model_registry, :register]`
- `[:crucible_model_registry, :promote]`
- `[:crucible_model_registry, :upload]`
- `[:crucible_model_registry, :download]`

## Development

```bash
mix test
mix format
mix dialyzer
mix credo --strict
```
