defmodule Bot.Cogs.Register do
  @moduledoc """
    Sends party message
  """
  @behaviour Nosedrum.Command

  @stats_channel "статистика"
  @command "register"

  alias Bot.{Helpers, PartySearchParticipants}
  alias Nosedrum.{
    Predicates,
    Converters,
    }
  alias Nostrum.Api
  alias Nostrum.Struct.{
    Embed,
    Guild,
    Channel,
    Invite,
    }
  alias Nostrum.Cache.GuildCache
  alias Guild.Member
  import Embed

  @impl true
  def usage,
      do: [
        "!#{@command} ваш_никнейм_на_FaceIT",
      ]

  def usage_text, do: """
  ```
  #{Enum.reduce(usage, "Примеры использования:", fn text, acc -> acc <> "\n" <> text end)}
  ```
"""

  @impl true
  def description,
      do: """
      ```
        Вносит ваш никнейм на FaceIT в базу бота

#{Enum.reduce(usage, "Примеры использования:", fn text, acc -> acc <> "\n" <> text end)}

        Работает только в канале #{@stats_channel}

      ```
      """

  @impl true
  def predicates, do: [&Predicates.guild_only/1]

  def command, do: @command

  @impl true
  def command(%{ guild_id: guild_id, author: %{ id: user_id }, id: msg_id } = msg, _args) do
    IO.inspect(msg, label: "Message")
    msg_channel_id = msg.channel_id
    case Helpers.create_channel_if_not_exists(@stats_channel, guild_id) do
      {:ok, %{ id: channel_id }} when channel_id == msg_channel_id ->
        nickname = get_nickname_from_message(msg.content)
        unless nickname == nil do
          reply = Api.create_message!(channel_id, "Ищу игрока с никнеймом `#{nickname}`...")
          Task.start(fn ->
            Bot.FaceIT.register_user(nickname, user_id, channel_id)
            Api.delete_message(channel_id, reply.id)
          end)
        else
          Task.start(fn ->
            reply = Api.create_message!(channel_id, "<@#{msg.author.id}>#{usage_text}")
            Process.sleep(4000)
            Api.delete_message(channel_id, reply.id)
          end)
        end
        Api.delete_message(channel_id, msg_id)
      {:error, %{ response: error_message }} ->
        error_message
        |> IO.inspect(label: "Unable to create or find channel #{@stats_channel}.")
      {:error, error_message} ->
        error_message
        |> IO.inspect(label: "Unable to create or find channel #{@stats_channel}.")
      _ ->
        IO.puts("Unknown error when creating or finding channel #{@stats_channel}")
    end
  end

  def command(msg, _args) do
    msg
    |> IO.inspect(label: "Unhandled message")
  end

  def get_nickname_from_message(content) do
    case content do
      "!#{@command} " <> nickname -> nickname
      _ -> nil
    end
  end

end
