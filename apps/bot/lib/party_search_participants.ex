defmodule Bot.PartySearchParticipants do
  alias Nostrum.{Api}
  alias Bot.Cogs.Party
  alias Nostrum.Struct.{
    Embed,
  }

  use Memento.Table,
      attributes: [
        :message_id,
        :voice_channel_id,
        :guild_id,
        :invite_code,
        :text_channel_id
      ],
      type: :ordered_set

  def handle_voice_update(channel_id, guild_id) do
    guards = [
      {:==, :voice_channel_id, channel_id},
      {:==, :guild_id, guild_id},
    ]
    IO.inspect(%{ channel_id: channel_id, guild_id: guild_id }, label: "Handle voice update")
    with {:ok, rows} <- Memento.transaction(fn -> Memento.Query.select(Bot.PartySearchParticipants, guards) end),
         x <- length(rows),
         true <- x > 0,
         {:ok, %Bot.PartySearchParticipants{} = data} <- Enum.fetch(rows, 0) do
      IO.inspect(rows, label: "Rows are")
      update_party_search_message(data)
    end
  end

  def update_party_search_message(%{
    message_id: message_id,
    text_channel_id: text_channel_id,
    voice_channel_id: voice_channel_id,
    invite_code: invite_code,
    guild_id: guild_id,
  } = data) do
    IO.inspect(data, label: "Provided to update message")
    with {:ok, msg} <- Api.get_channel_message(text_channel_id, message_id),
         {:ok, invite} <- Api.get_invite(invite_code),
         members <- Bot.VoiceMembers.get_channel_members(%Bot.VoiceMembers{
           channel_id: voice_channel_id,
           guild_id: guild_id,
         }),
         %Embed{} = updated_embed <- Party.create_party_message(msg, invite) do
      IO.inspect(msg.content, label: "Content of the message")
      IO.inspect(updated_embed, label: "New embed")
      unless length(members) == 0 do
        Api.edit_message!(msg, content: msg.content, embed: updated_embed)
      else
        Api.delete_message(text_channel_id, message_id)
      end
    else err -> err
                |> IO.inspect(label: "Cannot edit message")
    end
  end

  def write_party_search_message(message_id, voice_channel_id, guild_id, invite_code, text_channel_id) do
    Memento.transaction(fn ->
      Memento.Query.write(%Bot.PartySearchParticipants{
        message_id: message_id,
        voice_channel_id: voice_channel_id,
        guild_id: guild_id,
        invite_code: invite_code,
        text_channel_id: text_channel_id,
      })
#      Memento.Query.read(Bot.PartySearchParticipants, message_id)
    end)
    |> IO.inspect(label: "Successfully written party search message")
  end

  def delete_party_messages_for_voice_channel(voice_channel_id) do
    Memento.transaction(fn ->
      rows = Memento.Query.select(Bot.PartySearchParticipants, {:==, :voice_channel_id, voice_channel_id})
      Enum.each(rows, fn row ->
        IO.inspect(row, label: "Row")
        Memento.Query.delete(Bot.PartySearchParticipants, row.message_id)
        Api.delete_message(row.text_channel_id, row.message_id)
        |> IO.inspect(label: "Result at delete message")
      end)
    end)
  end

end
