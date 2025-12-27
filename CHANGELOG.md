# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
