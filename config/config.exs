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
  token: "NjMxODk4OTg3ODMzNTg5Nzcw.XZ9j0Q.KML5qnEXmIfaiqCG9yFRfjqYHJ8",
  num_shards: :auto

config :nosedrum,
  prefix: System.get_env("BOT_PREFIX") || "!"

config :mnesia,
  dir: '.mnesia/#{Mix.env}/#{node()}'


