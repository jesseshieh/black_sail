defmodule Bot.Helpers do

  alias Nostrum.{
    Api,
    Struct.User,
    Struct.Embed,
    Permission,
  }
  import Embed
  alias Nosedrum.{Converters}
  alias Bot.Cogs.{Party, Register}

  @errors_channel "errors"
  @logs_channel "logs"
  @rules_channel "правила"
  @game_channel_prefix "Канал пати"
  @rules_title "Правила очень простые:"
  @rules_text """
  1. Не быть мудаком
  2. Не оскорблять других людей и их родителей
  3. Не спамить и не рекламировать ничего
  4. Не присваивать чужое
"""
  @special_channels [Party.search_channel, Register.stats_channel, @logs_channel, @errors_channel]

  def errors_channel, do: @errors_channel

  def logs_channel, do: @logs_channel

  def game_channel_prefix, do: @game_channel_prefix

  def special_channel_permission_overwrites(role_id) do
    [
      %{ id: role_id, type: "role", deny: Permission.to_bitset([:attach_files, :embed_links, :send_tts_messages, :mention_everyone]) },
    ]
  end

  def create_channel_if_not_exists(channel_name, guild_id, type \\ 0) do
    case Converters.to_channel(channel_name, guild_id) do
      {:error, _} ->
        Api.create_guild_channel(guild_id, name: channel_name, type: type, permission_overwrites: [])
        |> IO.inspect(label: "Created channel")
      result -> result
      |> IO.inspect(label: "Result at create channel if not exists")
    end
  end

  def delete_game_channels_without_parent(guild_id) do
    with {:ok, channels} = Api.get_guild_channels(guild_id) do
      channels
      |> Enum.filter(fn ch ->
        case ch.name do
          @game_channel_prefix <> _other -> ch.parent_id == nil
          _ -> false
        end
      end)
      |> Enum.map(fn ch -> Api.delete_channel(ch.id, "Deleting game channel without parent") end)
    else err -> IO.inspect(err, label: "Cannot delete game channels without parent")
    end
  end

  def get_user_avatar_by_user_id(user_id) do
    case Nostrum.Cache.UserCache.get(user_id) do
      {:ok, %User{} = user} -> User.avatar_url(user, "gif")
      _ -> nil
    end
  end

  def reply_and_delete_message(channel_id, text) do
    Task.start(fn ->
      reply = Api.create_message!(channel_id, text)
              |> IO.inspect(label: "Reply")
      Process.sleep(5000)
      Api.delete_message!(reply.channel_id, reply.id)
    end)
  end

  def delete_casual_message_from_special_channel(%{ guild_id: guild_id, channel_id: channel_id } = msg) when guild_id != nil do
    with {:ok, %{ name: name }} when name in @special_channels <- Converters.to_channel("#{channel_id}", guild_id) do
      Api.delete_message(channel_id, msg.id)
    end
  end
  def delete_casual_message_from_special_channel(_msg), do: nil

  def ensure_rules_message_exists(guild_id) do
    with {:ok, channel} <- Converters.to_channel(@rules_channel, guild_id) do
      Api.delete_channel(channel.id, "Recreating rules")
    end
    {:ok, role} = Converters.to_role("@everyone", guild_id)
    opts = [
      name: @rules_channel,
      type: 0,
      permission_overwrites: [
        %{
          type: "role",
          id: role.id,
          deny: Permission.to_bit(:send_messages)
        }
      ]
    ]
    {:ok, channel} = Api.create_guild_channel(guild_id, opts)
    embed = %Embed{}
            |> put_description(@rules_text)
            |> put_color(0x9768d1)
            |> put_timestamp(DateTime.utc_now())
            |> put_footer("Последний перезапуск бота: ")
    Api.create_message(channel.id, content: @rules_title, embed: embed)
  end

  def delete_channel_if_exists(channel_name, guild_id) do
    with {:ok, channel} <- Converters.to_channel(channel_name, guild_id) do
      Api.delete_channel(channel.id)
    end
  end

  def create_role_if_not_exists(role_name, guild_id, opts \\ []) do
    with {:error, _} <- Converters.to_role(role_name, guild_id) do
      IO.inspect(role_name, label: "Creating role")
      Api.create_guild_role(guild_id, [name: role_name] ++ opts)
    end
  end

end
