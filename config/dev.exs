import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.

config :nostrum,
       token: System.get_env("BOT_TOKEN"),
       num_shards: :auto

config :nosedrum,
       prefix: System.get_env("BOT_PREFIX") || "!"

config :mnesia,
       dir: '.mnesia/#{Mix.env}/#{node()}'

config :bot,
       faceit_api_key: System.get_env("FACEIT_API_KEY"),
       redis_host: System.get_env("REDIS_HOST"),
       redis_port: System.get_env("REDIS_PORT"),
       redis_password: System.get_env("REDIS_PASSWORD")

config :phoenix, :json_library, Jason

# Configures the endpoint
config :backend, BackendWeb.Endpoint,
       url: [host: "localhost"],
       http: [port: 4000],
       secret_key_base: "bshRq5AtaiaDK+MX83KjZDQvCqHtoPMsg/51ne49KBOirR/YxQqSiIHmQG6OOSzK",
       render_errors: [view: BackendWeb.ErrorView, accepts: ~w(html json)],
       pubsub: [name: Backend.PubSub, adapter: Phoenix.PubSub.PG2],
       http: [port: 4000],
       url: [host: "localhost", port: 4000],
       server: true,
       debug_errors: true,
       code_reloader: true,
       check_origin: false,
       live_reload: [
         patterns: [
           ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
           ~r"priv/gettext/.*(po)$",
           ~r"lib/backend_web/{live,views}/.*(ex)$",
           ~r"lib/backend_web/templates/.*(eex)$"
         ]
       ],
       watchers: []


# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
