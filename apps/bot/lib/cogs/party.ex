defmodule Bot.Cogs.Party do
  @moduledoc """
    Sends party message
  """
  @behaviour Nosedrum.Command

  @search_channel "поиск"
  @user_limit 5
  @text_channel_type 0
  @command "party"
  @category_name "игровые комнаты"
  @topic """
  Для поиска введите команду !party ваш_комментарий. Если вы не в голосовом канале, бот создаст канал и переместит вас туда.
"""

  alias Bot.{Helpers, PartySearchParticipants}
  alias Nosedrum.{
    Predicates,
    Converters,
  }
  alias Bot.Predicates, as: CustomPredicates
  alias Nostrum.Api
  alias Nostrum.Struct.{
    Embed,
    Guild,
    Channel,
    Invite,
  }
  alias Nostrum.Cache.GuildCache
  alias Guild.Member
  alias Nostrum.Permission
  import Embed

  @impl true
  def usage,
      do: [
        "!#{@command} ваш_комментарий",
      ]

  @impl true
  def description,
      do: """
      ```
      Отправляет сообщение с поиском пати.
      Если вы находитесь не в голосовом чате, бот создаст для вас канал на #{@user_limit} человек.

      Команда: !#{@command} Предпочитаю играть с любителями народных песен

      Выведет Embed-сообщение:

      Поиск Competitive FaceIT
      @username Gold Nova I KDA 2

      Коммент: Предпочитаю играть с любителями народных песен

#{Enum.reduce(usage, "Примеры использования:", fn text, acc -> acc <> "\n" <> text end)}

        Работает только в канале #{@search_channel}
      ```
      """

  @impl true
  def predicates, do: [&Predicates.guild_only/1]

  def command, do: @command
  def search_channel, do: @search_channel

  @impl true
  def command(msg, args) do
    case CustomPredicates.is_party_search_channel?(msg) do
      {:ok, _msg} -> execute_command(msg, args)
      {:error, reason} -> Helpers.reply_and_delete_message(msg.channel_id, reason)
    end
  end

  def recreate_channel(guild_id) do
    Helpers.delete_channel_if_exists(@search_channel, guild_id)
    Task.start(fn ->
      {:ok, role} = Converters.to_role("@everyone", guild_id)
      opts = [
        name: @search_channel,
        type: 0,
        permission_overwrites: Helpers.special_channel_permission_overwrites(role.id)
      ]
      Api.create_guild_channel(guild_id, opts)
    end)
  end

  @impl true
  def execute_command(%{ guild_id: guild_id } = msg, _args) do
#    IO.inspect(msg, label: "Message")
    usernameWithDiscriminator = msg.author.username <> "#" <> msg.author.discriminator
    channel_name_for_member = get_channel_name_for_member(usernameWithDiscriminator)
    case Helpers.create_channel_if_not_exists(@search_channel, guild_id) do
      {:ok, %{ id: channel_id }} ->
        unless msg.channel_id !== channel_id do
          unless is_in_voice_channel?(msg.author.id) do
            Task.start(fn ->
              delete_empty_voice_channels_with_same_name(channel_name_for_member, guild_id)
            end)
            %Channel{} = channel = create_voice_channel_for_member(guild_id, usernameWithDiscriminator)
            invite = Api.create_channel_invite!(channel.id, max_age: 1200)
            Task.start(fn ->
              Api.create_message(channel_id, content: "<@#{msg.author.id}>", embed: message_if_not_in_voice_channel(msg.author.id, invite))
            end)
            Task.start(fn ->
              Api.delete_message(channel_id, msg.id)
            end)
          else
            voice_channel_id = Bot.VoiceMembers.get_channel_id_by_user_id(msg.author.id)
            unless voice_channel_id == nil do
              invite = Api.create_channel_invite!(voice_channel_id, max_age: 1200)
              reply = Api.create_message!(channel_id, embed: create_party_message(msg, invite))
              PartySearchParticipants.delete_party_messages_for_voice_channel(voice_channel_id)
              PartySearchParticipants.write_party_search_message(%PartySearchParticipants{
                message_id: reply.id,
                voice_channel_id: voice_channel_id,
                guild_id: guild_id,
                invite_code: invite.code,
                text_channel_id: channel_id,
                comment: extract_comment(msg.content)
              })
              Api.delete_message!(channel_id, msg.id)
            else
              Task.start(fn ->
                Api.create_message!(channel_id, "<@#{msg.author.id}>, пожалуйста, перейдите в свободный голосовой канал или введите команду заново")
              end)
              Task.start(fn ->
                Api.delete_message!(channel_id, msg.id)
              end)
            end
          end
        else
          Api.delete_message(msg.channel_id, msg.id)
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

  def create_party_message(%{ guild_id: guild_id } = msg, %Invite{ channel: %{ id: channel_id } } = invite) do
    members = Bot.VoiceMembers.get_channel_members(%Bot.VoiceMembers{ channel_id: channel_id, guild_id: guild_id })
    placesLeft = @user_limit - length(members)
    title = if placesLeft != 0, do: "Ищу +#{placesLeft}", else: "Пати собрано"
    embed = %Embed{}
            |> put_title(title)
    embed_description = Enum.reduce(members, "", fn %Member{ user: %{ id: id } }, acc ->
      acc <> "<@#{id}> Player \n"
    end)
    embed_description = extract_comment(msg.content) <> "\n" <> embed_description <> "\n\nПерейти: https://discord.gg/#{invite.code}"
    embed
    |> put_description(embed_description)
  end

  defp get_comment(%Embed{} = embed, content) do
    case content do
      "!#{@command} " <> comment ->
        embed
        |> put_description("Коммент: #{comment}")
        |> IO.inspect(label: "Embed with comment")
      _ ->
        IO.inspect(content, label: "Content message for comment")
        embed
    end
  end

  def extract_comment(content) do
    case content do
      "!#{@command} " <> comment -> "Комментарий: #{comment}\n"
      _ -> ""
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
    %Channel{} = parent_category = get_or_create_parent_category(guild_id)
    %{id: id} = Api.create_guild_channel!(guild_id, name: get_channel_name_for_member(username), type: 2, user_limit: @user_limit, parent_id: parent_category.id)
  end

  defp message_if_not_in_voice_channel(user_id, %Invite{} = invite) do
    %Embed{}
    |> put_description(
         """
         <@#{user_id}>, для вас был создан канал **#{invite.channel.name}**. Перейдите в него и введите команду заново

         Нажмите для перехода: https://discord.gg/#{invite.code}
         """
       )
  end

  defp get_or_create_parent_category(guild_id) do
    parent_category = Api.get_guild_channels!(guild_id)
    |> Enum.find(fn x -> x.name == @category_name end)
    case parent_category do
      %Channel{} = channel ->
        channel
      err ->
        IO.inspect(err, label: "Unable to find such channel")
        Api.create_guild_channel!(guild_id, name: @category_name, type: 4)
    end
  end

  defp get_channel_name_for_member(username) do
    "#{Helpers.game_channel_prefix} #{username}"
  end

  defp delete_empty_voice_channels_with_same_name(channel_name, guild_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        guild.channels
        |> Enum.filter(fn { id, ch } ->
          ch.name == channel_name and ch.type == 2 and Bot.VoiceMembers.is_voice_channel_empty?(id, guild_id)
        end)
        |> Enum.each(fn { id, ch } ->
          Api.delete_channel(ch.id, "Deleting empty duplicate")
        end)
      _ -> nil
    end
  end
end
