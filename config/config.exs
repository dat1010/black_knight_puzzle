# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :black_knight_puzzle,
  ecto_repos: [BlackKnightPuzzle.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :black_knight_puzzle, BlackKnightPuzzleWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BlackKnightPuzzleWeb.ErrorHTML, json: BlackKnightPuzzleWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BlackKnightPuzzle.PubSub,
  live_view: [signing_salt: "6AzhVBcZ"]

config :swoosh, :api_client, Swoosh.ApiClient.Hackney

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :black_knight_puzzle, BlackKnightPuzzle.Mailer, adapter: Swoosh.Adapters.Local

config :black_knight_puzzle, BlackKnightPuzzle.Mailer,
  adapter: Swoosh.Adapters.AmazonSES,
  region: "us-east-1",
  access_key: System.get_env("SES_ACCESS_KEY"),
  secret: System.get_env("SES_SECRET")

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  black_knight_puzzle: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  black_knight_puzzle: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
