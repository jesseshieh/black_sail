defmodule Bot.Helpers do

  alias Nostrum.{Api}
  alias Nosedrum.{Converters}

  @errors_channel "errors"
  @logs_channel "logs"
  @game_channel_prefix "Канал пати"

  def errors_channel, do: @errors_channel

  def logs_channel, do: @logs_channel

  def game_channel_prefix, do: @game_channel_prefix

  def create_channel_if_not_exists(channel_name, guild_id, type \\ 0) do
    case Converters.to_channel(channel_name, guild_id) do
      {:error, _} ->
        Api.create_guild_channel(guild_id, name: channel_name, type: type)
      result -> result
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
end
