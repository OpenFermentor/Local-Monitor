use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or you later on).
config :bio_monitor, BioMonitor.Endpoint,
  secret_key_base: "BtVSjB9lLvW88hbR9tsnq6r73gM8++Cx+ffJw0DIu0ZNJMhKcyiasxfACfdi1YjJ"

# Configure your database
config :bio_monitor, BioMonitor.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "bio_monitor_prod",
  pool_size: 20
