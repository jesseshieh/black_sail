defmodule Bot.Consumer.Ready do
  @moduledoc "Handles the `READY` event."

  alias Nosedrum.Storage.ETS, as: CommandStorage
  alias Bot.{Cogs, Helpers}
  alias Nostrum.Api
  alias Nosedrum.{Converters}
  alias Cogs.Party
  alias Cogs.Register

  @infraction_group %{
    "detail" => Cogs.Infraction.Detail,
    "reason" => Cogs.Infraction.Reason,
    "list" => Cogs.Infraction.List,
    "user" => Cogs.Infraction.User,
    "expiry" => Cogs.Infraction.Expiry
  }

  @commands %{
    ## Bot meta commands
    "help" => Cogs.Help,
    "party" => Cogs.Party,
    "register" => Cogs.Register,
    "update" => Cogs.Update,
  }

  @aliases %{
    "рудз" => Map.fetch!(@commands, "help"),
    "h" => Map.fetch!(@commands, "help"),

    "зфкен" => Map.fetch!(@commands, "party"),
    # Английская эр
    "p" => Map.fetch!(@commands, "party"),
    # Русская эр
    "р" => Map.fetch!(@commands, "party"),
    "пати" => Map.fetch!(@commands, "party"),
    "поиск" => Map.fetch!(@commands, "party"),

    "r" => Map.fetch!(@commands, "register"),
    "reg" => Map.fetch!(@commands, "register"),
    "купшыеук" => Map.fetch!(@commands, "register"),
    "куп" => Map.fetch!(@commands, "register"),
    "рег" => Map.fetch!(@commands, "register"),

    "u" => Map.fetch!(@commands, "update"),
    "гзвфеу" => Map.fetch!(@commands, "update"),
    "stats" => Map.fetch!(@commands, "update"),
    "ыефеы" => Map.fetch!(@commands, "update"),
    "статс" => Map.fetch!(@commands, "update"),
  }

  def commands, do: @commands

  @spec handle(map()) :: :ok
  def handle(data) do
    :ok = load_commands()
    IO.puts("⚡ Logged in and ready, seeing `#{length(data.guilds)}` guilds.")
    data.guilds
    |> Enum.map(fn %{ id: guild_id } = guild -> Map.put(guild, :channels, Api.get_guild_channels!(guild_id)) end)
    |> Enum.each(fn %{ id: guild_id } ->
      IO.inspect(guild_id, label: "Deleting guild game channels")
      Task.start(fn ->
        {:ok, role} = Converters.to_role("@everyone", guild_id)
        opts = [
          permissions: Nostrum.Permission.to_bitset([
            :attach_files,
            :send_messages,
            :read_message_history,
            :use_external_emojis,
            :view_channel,
            :add_reactions,
            :speak,
            :connect,
          ]),
        ]
        Api.modify_guild_role(guild_id, role.id, opts)
      end)
      Task.start(fn ->
        Party.recreate_channel(guild_id)
        Register.recreate_channel(guild_id)
        Helpers.ensure_rules_message_exists(guild_id)
      end)
#      Task.start(fn -> Register.recreate_roles(guild_id) end)
      Register.recreate_roles(guild_id)
      Task.start(fn -> Helpers.delete_game_channels_without_parent(guild_id) end)
    end)
    :ok = Api.update_status(:online, "you | !help", 3)
  end

  defp load_commands do
    [@commands, @aliases]
    |> Stream.concat()
    |> Enum.each(fn {name, cog} -> CommandStorage.add_command({name}, cog) end)
  end
end
