defmodule Bot.Cogs.Help do
  @moduledoc """
  Prints help
"""
  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild

  @impl true
  def usage,
      do: [
        "help",
      ]

  @impl true
  def description,
      do: """
      Показывает информацию по доступным командам
      """

  @impl true
  def predicates, do: [&Predicates.guild_only/1]

  @impl true
  def command(msg, _args) do
    response = """
    Привет!
    """

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
