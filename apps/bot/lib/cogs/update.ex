defmodule Bot.Cogs.Update do
  @moduledoc """
    Sends party message
  """
  @behaviour Nosedrum.Command

  @stats_channel "статистика"
  @command "update"

  alias Bot.{
    Helpers,
    PartySearchParticipants,
    Cogs.Register,
    }
  alias Bot.Predicates, as: CustomPredicates
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
        "!#{@command}",
      ]

  @impl true
  def description,
      do: """
      ```
        Обновляет данные FaceIT по вашему никнейму, указанному при регистрации (см. !#{Register.command})

        ВАЖНО: Для использования этой команды вам сначала нужно зарегистрировать свой никнейм в нашей базе, введите !help для получения дополнительной информации

#{Enum.reduce(usage, "Примеры использования:", fn text, acc -> acc <> "\n" <> text end)}

        Работает только в канале #{@stats_channel}

      ```
      """

  @impl true
  def predicates, do: [&Predicates.guild_only/1]

  def command, do: @command

  @impl true
  def command(msg, args) do
    case CustomPredicates.is_stats_channel?(msg) do
      {:ok, _msg} -> execute_command(msg, args)
      {:error, reason} -> Helpers.reply_and_delete_message(msg.channel_id, reason)
    end
  end

  @impl true
  def execute_command(%{ guild_id: guild_id, author: %{ id: user_id }, id: msg_id } = msg, _args) do
#    IO.inspect(msg, label: "Message")
    msg_channel_id = msg.channel_id
    case Helpers.create_channel_if_not_exists(@stats_channel, guild_id) do
      {:ok, %{ id: channel_id }} when channel_id == msg_channel_id ->
        reply = Api.create_message!(channel_id, "Обновляю данные...")
        Bot.FaceIT.update_user(user_id, channel_id, guild_id)
        Api.delete_message(channel_id, reply.id)
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

  def get_nickname_from_message(content) do
    case content do
      "!#{@command} " <> nickname -> nickname
      _ -> nil
    end
  end

end
