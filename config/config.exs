# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

config :nostrum,
  token: System.get_env("BOT_TOKEN"),
  num_shards: :auto

config :nosedrum,
  prefix: System.get_env("BOT_PREFIX") || "!"

config :mnesia,
  dir: '.mnesia/#{Mix.env}/#{node()}'

config :api, Api.Server,
       adapter: Plug.Cowboy,
       plug: Api.API,
       scheme: :http,
       port: 8880

config :api,
       maru_servers: [Api.Server]
config :phoenix, :json_library, Jason

# Configures the endpoint
config :backend, BackendWeb.Endpoint,
       url: [host: "localhost"],
       http: [port: 4000],
       secret_key_base: "bshRq5AtaiaDK+MX83KjZDQvCqHtoPMsg/51ne49KBOirR/YxQqSiIHmQG6OOSzK",
       render_errors: [view: BackendWeb.ErrorView, accepts: ~w(html json)],
       pubsub: [name: Backend.PubSub, adapter: Phoenix.PubSub.PG2]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
