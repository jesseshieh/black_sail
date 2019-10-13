defmodule Bot.Cogs.Register do
  @moduledoc """
    Sends party message
  """
  @behaviour Nosedrum.Command

  @stats_channel "статистика"
  @command "register"
  @low_win_rate_key "Низкий винрейт"

  alias Bot.{
    Helpers,
    PartySearchParticipants,
    }
  alias Bot.Predicates, as: CustomPredicates
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
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Permission
  alias Guild.Member
  import Embed

  @impl true
  def usage,
      do: [
        "!#{@command} ваш_никнейм_на_FaceIT",
      ]

  def usage_text, do: """
  ```
  #{Enum.reduce(usage, "Примеры использования:", fn text, acc -> acc <> "\n" <> text end)}
  ```
"""

  @impl true
  def description,
      do: """
      ```
        Вносит ваш никнейм на FaceIT в базу бота

#{Enum.reduce(usage, "Примеры использования:", fn text, acc -> acc <> "\n" <> text end)}

        Работает только в канале #{@stats_channel}

      ```
      """

  @impl true
  def predicates, do: [&Predicates.guild_only/1]

  def command, do: @command
  def stats_channel, do: @stats_channel
  def kdr_roles, do: %{
    "Низкий KDR" => [min: 0, max: 0.9],
    "KDR 1" => [min: 1, max: 1.9],
    "KDR 2" => [min: 2, max: 2.9],
    "KDR 3" => [min: 3, max: 3.9],
    "KDR 4" => [min: 4, max: 4.9],
    "KDR 5" => [min: 5, max: 5.9],
    "KDR 6" => [min: 6, max: 999],
  }
  def win_rate_roles, do: %{
    "#{@low_win_rate_key}" => [range: 0..39],
    "Винрейт 40%" => [range: 40..49 ],
    "Винрейт 50%" => [range: 50..59 ],
    "Винрейт 60%" => [range: 60..69 ],
    "Винрейт 70%" => [range: 70..79 ],
    "Винрейт 80%" => [range: 80..89 ],
    "Винрейт 90%" => [range: 90..99 ],
    "Винрейт 95%" => [range: 95..100 ],
  }

  def recreate_roles(guild_id) do
    [kdr_roles, win_rate_roles]
    |> Stream.concat()
    |> Enum.each(fn { role_name, _role_data } -> Helpers.create_role_if_not_exists(role_name, guild_id) end)
  end

  @impl true
  def command(msg, args) do
    case CustomPredicates.is_stats_channel?(msg) do
      {:ok, _msg} -> execute_command(msg, args)
      {:error, reason} -> Helpers.reply_and_delete_message(msg.channel_id, reason)
    end
  end

  def assign_role_for_win_rate(win_rate, guild_id) do
    {role_name, _} = win_rate_roles
    |> Enum.find(fn { role_name, role_data } ->
      {:range, range} = List.keyfind(role_data, :range, 0)
      {value, _} = Integer.parse(win_rate)
      value in range
    end)
    {:ok, role} = Converters.to_role(role_name, guild_id)
  end

  def assign_role_for_kdr(kdr, guild_id) do
    {role_name, _} = kdr_roles
    |> Enum.find(fn { role_name, role_data } ->
      {:min, min} = List.keyfind(role_data, :min, 0)
      {:max, max} = List.keyfind(role_data, :max, 0)
      {value, _} = Float.parse(kdr)
      value >= min and value <= max
    end)
    {:ok, role} = Converters.to_role(role_name, guild_id)
  end

  def recreate_channel(guild_id) do
    Helpers.delete_channel_if_exists(@stats_channel, guild_id)
    Task.start(fn ->
      {:ok, role} = Converters.to_role("@everyone", guild_id)
      opts = [
        name: @stats_channel,
        type: 0,
        permission_overwrites: Helpers.special_channel_permission_overwrites(role.id)
      ]
      Api.create_guild_channel!(guild_id, opts)
    end)
  end

  @impl true
  def execute_command(%{ guild_id: guild_id, author: %{ id: user_id }, id: msg_id } = msg, args) do
    IO.inspect(args, label: "ARGS")
#    IO.inspect(msg, label: "Message")
    msg_channel_id = msg.channel_id
    case Helpers.create_channel_if_not_exists(@stats_channel, guild_id) do
      {:ok, %{ id: channel_id }} when channel_id == msg_channel_id ->
        nickname = get_nickname_from_message(msg.content)
        unless nickname == nil do
          reply = Api.create_message!(channel_id, "Ищу игрока с никнеймом `#{nickname}`...")
          Task.start(fn ->
            Bot.FaceIT.register_user(nickname, user_id, channel_id, guild_id)
            Api.delete_message(channel_id, reply.id)
          end)
        else
          Task.start(fn ->
            reply = Api.create_message!(channel_id, "<@#{msg.author.id}>#{usage_text}")
            Process.sleep(4000)
            Api.delete_message(channel_id, reply.id)
          end)
        end
        Api.delete_message(channel_id, msg_id)
      {:error, %{ response: error_message }} ->
        error_message
        |> IO.inspect(label: "Unable to create or find channel #{@stats_channel}.")
      {:error, error_message} ->
        error_message
        |> IO.inspect(label: "Unable to create or find channel #{@stats_channel}.")
      z -> z
        |> IO.inspect(label: "Unknown error when creating or finding channel #{@stats_channel}")
    end
  end

  def get_nickname_from_message(content) do
    case content do
      "!#{@command} " <> nickname -> nickname
      _ -> nil
    end
  end

end
