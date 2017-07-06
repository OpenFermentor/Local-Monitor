# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :bio_monitor,
  ecto_repos: [BioMonitor.Repo]

# Configures the endpoint
config :bio_monitor, BioMonitor.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "YD7uc6HoF9HzoYOA6zJsqQP+HId3AuCwEIfo1A19/ngirkgueS8VW0lItsierccq",
  render_errors: [view: BioMonitor.ErrorView, accepts: ~w(json)],
  pubsub: [name: BioMonitor.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configures ports and variables for Sensors.
config :bio_monitor, BioMonitor.SensorManager,
  arduino: [
    port: "dummy port",
    speed: 9600,
    sensors: [temp: "getTemp"]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
