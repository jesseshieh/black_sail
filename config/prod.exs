use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
#config :backend, BackendWeb.Endpoint,
#  url: [host: "example.com", port: 80],
#  cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info


# Configures the endpoint
config :backend, BackendWeb.Endpoint,
       url: [host: "thankful-misguided-diamondbackrattlesnake.gigalixirapp.com"],
       http: [port: 4000],
       secret_key_base: System.get_env("SECRET_KEY_BASE"),
       render_errors: [view: BackendWeb.ErrorView, accepts: ~w(html json)],
       pubsub: [name: Backend.PubSub, adapter: Phoenix.PubSub.PG2]
