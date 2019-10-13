# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
    # This sets the default release built by `mix distillery.release`
    default_release: :default,
    # This sets the default environment used by `mix distillery.release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.
  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.
  set dev_mode: true
  set include_erts: false
  set cookie: :"c;[Szg:J)to}~[0%_>ng}72Q(APhd&i!Me[G~(lRi/P[(0x>&^^I7t3t:8@k:~.)"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"Q!|xg.`T6$PHx4Zbdkm3^f%P}z)1g|90t!||!s@12NaHBBjC6rPAsPQM4Zli|kdw"
  set vm_args: "rel/vm.args"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix distillery.release`, the first release in the file
# will be used by default

release :bot do
  set version: current_version(:bot)
  set applications: [
    backend: :permanent,
    bot: :transient,
    runtime_tools: :temporary
  ]
  set config_providers: [
    {Distillery.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
  ]
  set overlays: [
    {:copy, "rel/etc/config.exs", "etc/config.exs"}
  ]
end
