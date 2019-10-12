defmodule Bot.Consumer.Ready do
  @moduledoc "Handles the `READY` event."

  alias Nosedrum.Storage.ETS, as: CommandStorage
  alias Bot.{Cogs, Helpers}
  alias Nostrum.Api
  alias Nosedrum.{Converters}

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
    Enum.each(data.guilds, fn %{ id: guild_id } ->
      IO.inspect(guild_id, label: "Deleting guild game channels")
      Helpers.delete_game_channels_without_parent(guild_id)
    end)
    :ok = Api.update_status(:online, "you | !help", 3)
  end

  defp load_commands do
    [@commands, @aliases]
    |> Stream.concat()
    |> Enum.each(fn {name, cog} -> CommandStorage.add_command({name}, cog) end)
  end
end
