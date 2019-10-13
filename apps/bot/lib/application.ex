defmodule Bot.Application do
  @moduledoc """
  The entry point for bot.
  Starts the required processes, including the gateway consumer supervisor.
  """
  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    Application.fetch_env!(:bot, :redis_host)
    |> IO.inspect(label: "REDIS_HOST from application fetch_env")
    Application.fetch_env!(:bot, :redis_port)
    |> IO.inspect(label: "REDIS_PORT from application fetch_env")
    Application.fetch_env!(:bot, :faceit_api_key)
    |> IO.inspect(label: "face it api key from application fetch_env")
    Application.fetch_env!(:bot, :redis_password)
    |> IO.inspect(label: "Redis pass")
    children = [
      {Redix,
        host: Application.fetch_env!(:bot, :redis_host),
        port: String.to_integer(Application.fetch_env!(:bot, :redis_port)),
        password: Application.fetch_env!(:bot, :redis_password),
        name: :redix
      },
      Nosedrum.Storage.ETS,
      # Supervises Discord Gateway event consumers.
      Bot.ConsumerSupervisor,
    ]
    Memento.Table.create(Bot.VoiceMembers)
    Memento.Table.create(Bot.PartySearchParticipants)
    options = [strategy: :rest_for_one, name: Bot.Supervisor]
    Supervisor.start_link(children, options)
  end

end
