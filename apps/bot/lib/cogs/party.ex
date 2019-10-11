defmodule Bot.Cogs.Party do
  @moduledoc """
    Sends party message
  """
  @behaviour Nosedrum.Command

  @search_channel "поиск"
  @user_limit 5
  @text_channel_type 0
  @command "party"
  @category_name "Игровые комнаты"
  @topic """
  Для поиска введите команду !party ваш_комментарий. Если вы не в голосовом канале, бот создаст канал и переместит вас туда.
"""

  alias Bot.{Helpers}
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
  alias Guild.Member
  import Embed

  @impl true
  def usage,
      do: [
        "!#{@command} <comment>",
      ]

  @impl true
  def description,
      do: """
      Отправляет сообщение с поиском пати.
      Пример ниже.
      Если вы находитесь не в голосовом чате, бот создаст для вас канал на #{@user_limit} человек.

      Команда: !#{@command} Предпочитаю играть с любителями народных песен

      Выведет сообщение:

      ```
      Поиск Competitive FaceIT
      @username Gold Nova I KDA 2

      Comment: Предпочитаю играть с любителями народных песен
      ```
      """

  @impl true
  def predicates, do: [&Predicates.guild_only/1]

  @impl true
  def command(%{ guild_id: guild_id } = msg, _args) do
    IO.inspect(msg, label: "Message")
    case Helpers.create_channel_if_not_exists(@search_channel, guild_id) do
      {:ok, %{ id: channel_id }} ->
        unless msg.channel_id !== channel_id do
          unless is_in_voice_channel?(msg.author.id) do
            %Channel{} = channel = create_voice_channel_for_member(guild_id, msg.author.username <> "#" <> msg.author.discriminator)
            invite = Api.create_channel_invite!(channel.id, max_age: 1200)
            Api.create_message(channel_id, embed: message_if_not_in_voice_channel(msg.author.id, invite))
          else
            voice_channel_id = Bot.VoiceMembers.get_channel_id_by_user_id(msg.author.id)
            unless voice_channel_id == nil do
              invite = Api.create_channel_invite!(voice_channel_id, max_age: 1200)
              Api.create_message!(channel_id, embed: create_party_message(msg, invite))
              Api.delete_message!(channel_id, msg.id)
            else
              Api.create_message!(channel_id, "<@#{msg.author.id}>, пожалуйста, перейдите в свободный голосовой канал или введите команду заново")
              Api.delete_message!(channel_id, msg.id)
            end
          end
        end
      {:error, %{ response: error_message }} ->
        error_message
        |> IO.inspect(label: "Unable to create or find channel #{@search_channel}.")
      {:error, error_message} ->
        error_message
        |> IO.inspect(label: "Unable to create or find channel #{@search_channel}.")
      _ ->
        IO.puts("Unknown error when creating or finding channel #{@search_channel}")
    end
  end

  def command(msg, _args) do
    msg
    |> IO.inspect(label: "Unhandled message")
  end

  defp create_party_message(%{ guild_id: guild_id } = msg, %Invite{} = invite) do
    embed = %Embed{}
            |> put_title("Ищу")
            |> get_comment(msg.content)
    members = Bot.VoiceMembers.get_channel_members_by_user_id(msg.author.id)
    embed_description = Enum.reduce(members, "", fn %Member{ user: %{ id: id } }, acc ->
      acc <> "<@#{id}> Player \n"
    end)
    embed_description = embed_description <> "\n\nПерейти: https://discord.gg/#{invite.code}"
    embed
    |> put_description(embed_description)
  end

  defp get_comment(%Embed{} = embed, content) do
    case content do
      "!#{@command} " <> comment ->
        embed
        |> put_description("Коммент: #{comment}")
      _ ->
        embed
    end
  end

  defp get_member_description(user_id) do
    "<@#{user_id}>: Player"
  end

  defp is_in_voice_channel?(user_id) do
    case Bot.VoiceMembers.get_channel_members_by_user_id(user_id) do
      x when is_list(x) and length(x) > 0 -> true
      _ -> false
    end
  end

  defp create_voice_channel_for_member(guild_id, username) do
    %{id: id} = Api.create_guild_channel!(guild_id, name: "Канал команды #{username}", type: 2, user_limit: @user_limit)
  end

  defp message_if_not_in_voice_channel(user_id, %Invite{} = invite) do
    %Embed{}
    |> put_description(
         """
         <@#{user_id}>, для вас был создан канал **#{invite.channel.name}**. Перейдите в него и поиск начнется автоматически

         Нажмите для перехода: https://discord.gg/#{invite.code}
         """
       )
  end
end
