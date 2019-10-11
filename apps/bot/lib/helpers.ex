defmodule Bot.Helpers do

  alias Nostrum.{Api}
  alias Nosedrum.{Converters}

  @errors_channel "errors"
  @logs_channel "logs"

  def errors_channel, do: @errors_channel

  def logs_channel, do: @logs_channel

  def create_channel_if_not_exists(channel_name, guild_id, type \\ 0) do
    case Converters.to_channel(channel_name, guild_id) do
      {:error, _} ->
        Api.create_guild_channel(guild_id, name: channel_name, type: type)
      result -> result
    end
  end
end
