defmodule Bot.Cogs.Help do
  @moduledoc """
  Prints help
"""
  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild
  alias Bot.Consumer.Ready
  import Embed

  @impl true
  def predicates, do: []

  @impl true
  def usage,
      do: [
        "!help",
        "!help команда",
      ]

  @impl true
  def description,
      do: """
      ```
      Показывает информацию по доступным командам

#{Enum.reduce(usage, "Примеры использования:", fn text, acc -> acc <> "\n" <> text end)}
      ```
      """

  @impl true
  def command(msg, _args) do
    embed = Enum.reduce(Ready.commands, %Embed{}, fn { command, module }, acc ->
      acc
      |> put_field("!#{command}", module.description)
    end)
    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end
end
