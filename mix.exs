defmodule CrucibleModelRegistry.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/North-Shore-AI/crucible_model_registry"

  def project do
    [
      app: :crucible_model_registry,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: dialyzer(),
      deps: deps(),
      name: "CrucibleModelRegistry",
      description: "Model versioning, artifact storage, and lineage tracking for ML pipelines",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:crypto, :logger],
      mod: {CrucibleModelRegistry.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.18"},
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2"},
      {:libgraph, "~> 0.16"},
      {:ex_aws, "~> 2.5"},
      {:ex_aws_s3, "~> 2.5"},
      {:hackney, "~> 1.20"},
      {:sweet_xml, "~> 0.7"},
      {:crucible_framework, "~> 0.4.0"},
      {:crucible_ir, "~> 0.2.0"},
      {:mox, "~> 1.1", only: :test},
      {:ex_machina, "~> 2.7", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: :app_tree,
      plt_add_apps: [:crucible_framework, :crucible_ir]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "CrucibleModelRegistry",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @source_url,
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      assets: %{"assets" => "assets"},
      logo: "assets/crucible_model_registry.svg"
    ]
  end

  defp package do
    [
      name: "crucible_model_registry",
      description: "Model versioning, artifact storage, and lineage tracking for ML pipelines",
      files: ~w(README.md CHANGELOG.md mix.exs LICENSE lib assets),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Online documentation" => "https://hexdocs.pm/crucible_model_registry"
      },
      maintainers: ["nshkrdotcom"]
    ]
  end
end
