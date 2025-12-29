# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2025-12-28

### Changed

- **Breaking**: Adopted Oban-style dynamic repo injection - host applications now provide their own Repo via `config :crucible_model_registry, repo: MyApp.Repo`
- Repo is no longer auto-started; host app manages its own supervision tree
- Added `CrucibleModelRegistry.repo/0` function for accessing configured repo
- Relaxed Elixir version requirement to ~> 1.14
- Updated postgrex to >= 0.21.1
- Updated telemetry to ~> 1.3
- Updated crucible_framework to ~> 0.5.1

### Added

- Legacy mode support via `start_repo: true` config for backwards compatibility
- `mix crucible_model_registry.install` task documentation for migrations

## [0.2.0] - 2025-12-27

### Added

- Conformance tests for all model registry stages
- README documentation for stage contracts with detailed option tables

### Changed

- Updated crucible_framework dependency to ~> 0.5.0

### Stages

- Register - Model version registration with lineage tracking
- Promote - Lifecycle stage promotion (development -> staging -> production)

## [0.1.0] - 2025-12-25

### Added

- Initial release
- Model versioning and artifact storage
- S3 backend support
- Model lineage tracking with libgraph
- Crucible Framework integration
