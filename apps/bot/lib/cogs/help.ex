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
  alias Bot.Helpers
  import Embed

  @impl true
  def predicates, do: []

  @impl true
  def usage,
      do: [
        "!help",
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
    |> put_color(0x9768d1)
    Task.start(fn ->
      Api.delete_message(msg.channel_id, msg.id)
    end)
    Helpers.reply_and_delete_message(msg.channel_id, "<@#{msg.author.id}>, отправил список команд с описанием в личку")
    {:ok, dm_channel} = Api.create_dm(msg.author.id)
    {:ok, _message} = Api.create_message(dm_channel.id, content: "Привет, ты просил помочь тебе с командами. Вот они:", embed: embed)
  end
end
