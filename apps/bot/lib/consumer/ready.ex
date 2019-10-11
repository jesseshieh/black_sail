defmodule Bot.Consumer.Ready do
  @moduledoc "Handles the `READY` event."

  alias Nosedrum.Storage.ETS, as: CommandStorage
  alias Bot.{Cogs}
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
  }

  @aliases %{}

  @spec handle(map()) :: :ok
  def handle(data) do
    :ok = load_commands()
    IO.puts("⚡ Logged in and ready, seeing `#{length(data.guilds)}` guilds.")
    :ok = Api.update_status(:online, "you | !help", 3)
  end

  defp load_commands do
    [@commands, @aliases]
    |> Stream.concat()
    |> Enum.each(fn {name, cog} -> CommandStorage.add_command({name}, cog) end)
  end
end
