defmodule BioMonitor.Mixfile do
  use Mix.Project

  def project do
    [app: :bio_monitor,
     version: "0.0.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     name: "BioMonitor",
     docs: [
       main: "BioMonitor"]]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {BioMonitor, []},
     applications: [:phoenix, :phoenix_pubsub, :cowboy, :logger, :gettext,
                    :cors_plug, :csv, :nerves_uart, :phoenix_channel_client,
                    :rummage_ecto, :uuid, :phoenix_ecto, :postgrex,
                    :elixir_make, :websocket_client]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:phoenix, "~> 1.2.4"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:faker, "~> 0.8",  only: [:dev, :test]},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:nerves_uart, "~> 0.1"},
      {:csv, "~> 2.0.0"},
      {:cors_plug, "~> 1.2"},
      {:phoenix_channel_client, "~> 0.2.0"},
      {:uuid, "~> 1.1.7"},
      {:rummage_ecto, "~> 1.2.0"},
      {:distillery, "~> 1.5.1", runtime: false},
      {:math, "~> 0.3.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
