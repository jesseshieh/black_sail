defmodule Bot.Consumer do
  @moduledoc """
    Consumes events and reacts to them
  """

  use Nostrum.Consumer
  alias Nostrum.Struct.Message
  alias Bot.Consumer.{
    MessageCreate,
    Ready,
    VoiceStateUpdate,
  }
  import Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  @impl true
  def handle_event({:MESSAGE_CREATE, %{ content: "!" <> command } = msg, _ws_state}) do
    unless msg.author.bot do
      MessageCreate.handle(msg)
    end
  end

  @impl true
  def handle_event({:READY, data, _ws_state}) do
    Ready.handle(data)
  end

  @impl true
  def handle_event({:VOICE_STATE_UPDATE, %{ channel_id: channel_id, user_id: user_id, guild_id: guild_id }, _ws_state}) do
    %Bot.VoiceMembers{ channel_id: channel_id, user_id: user_id, guild_id: guild_id }
    |> VoiceStateUpdate.handle
  end
  def handle_event(data) do
  end

end
