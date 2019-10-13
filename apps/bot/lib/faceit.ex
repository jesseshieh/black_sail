defmodule Bot.FaceIT do
  use HTTPoison.Base
  alias Nostrum.Api
  alias Nostrum.Struct.{ Embed }
  alias Bot.{Helpers, Cogs.Register}
  import Embed

  @endpoint "https://open.faceit.com/data/v4"
  @game_id "csgo"

  def process_url(url) do
    @endpoint <> url
  end

  def process_request_headers(headers \\ []) do
    headers ++ [{:authorization, "Bearer #{Application.fetch_env!(:bot, :faceit_api_key)}"}]
  end

  def process_response_body(body) do
    case Jason.decode(body) do
      {:ok, jsonBody} -> jsonBody
      _ -> body
    end
  end

  def register_user(nickname, user_id, channel_id, guild_id) do
    case get_user_stats(nickname, channel_id, user_id, guild_id) do
      {:ok, nickname} when is_binary(nickname) -> assign_nickname_to_user_id!(nickname, user_id)
      _ -> nil
    end
  end

  def update_user(user_id, channel_id, guild_id) do
    with nickname when is_binary(nickname) <- get_nickname_by_user_id(user_id) do
      {:ok, _} = get_user_stats(nickname, channel_id, user_id, guild_id)
    else err ->
      Api.create_message!(channel_id, "<@#{user_id}>, бот не смог найти ваш никнейм. Повторите регистрацию")
    end
  end

  def get_user_stats(nickname, channel_id, user_id, guild_id) do
    case get("/players?nickname=#{nickname}&game=#{@game_id}") do
      {:ok, %{ status_code: 200,
        body: %{
          "player_id" => player_id,
          "games" => %{
            "csgo" => %{
              "faceit_elo" => faceit_elo,
              "skill_level_label" => skill_level_label,
              "game_player_name" => game_player_name,
            }
          },
          "infractions" => %{
            "afk" => afk,
            "leaver" => leaver,
          }
        }
      } = data} -> data
#        |> IO.inspect(label: "Data at get user stats")
        player_afker = if afk > 0, do: "ДА", else: "НЕТ"
        player_leaver = if leaver > 0, do: "ДА", else: "НЕТ"
        embed = %Embed{}
                |> put_thumbnail(Helpers.get_user_avatar_by_user_id(user_id))
                |> put_title("#{game_player_name}")
#                |> put_field("Уровень", skill_level_label)
                |> put_field("FaceIT Эло", faceit_elo)
#                |> put_field("Ливер", player_leaver)
#                |> put_field("АФКер", player_afker)
                |> put_cs_go_stats(player_id, user_id, guild_id)
                |> put_color(0x9768d1)
        Api.create_message!(channel_id, embed: embed)
        {:ok, nickname}
      {:ok, %{ status_code: 200, body: %{ "games" => games } }} when map_size(games) == 0 ->
        Api.create_message!(channel_id, "У игрока с ником #{nickname} нет игр в FaceIT. Перепроверьте введенный никнейм")
      {:ok, %{ status_code: 200, body: %{ "games" => %{ "csgo" => game } } }} when game == nil ->
        Api.create_message!(channel_id, "У игрока с ником #{nickname} нет игры CS:GO в FaceIT. Перепроверьте введенный никнейм и удостоверьтесь, что в FaceIT добавлена CS:GO")
      {:ok, %{ status_code: 404 }} -> Api.create_message!(channel_id, "Не найден игрок с никнеймом #{nickname}")
      {:ok, %{ status_code: 401 }} -> Api.create_message!(channel_id, "Не удалось подключиться к FaceIT API. Сообщите администрации")
      {:ok, %{ status_code: 500 }} -> Api.create_message!(channel_id, "Произошла ошибка на сервере FaceIT API. Попробуйте позднее")
      {:ok, %{ status_code: 429 }} -> Api.create_message!(channel_id, "Слишком много запросов от бота к FaceIT API. Попробуйте позднее")
      {:ok, %{ status_code: 503 }} -> Api.create_message!(channel_id, "Сервис FaceIT API временно недоступен. Попробуйте позднее")
      {:ok, z} ->
        IO.inspect(z, label: "Data for unknown err")
        Api.create_message!(channel_id, "Неизвестная ошибке при поиске игрока с никнеймом #{nickname}")
      {:error, %{ reason: reason }} -> Api.create_message!(channel_id, "Не удалось найти игрока с никнеймом #{nickname}: #{reason}")
    end
  end

  defp put_cs_go_stats(embed, player_id, user_id, guild_id) do
    case get("/players/#{player_id}/stats/#{@game_id}") do
      {:ok, %{
        status_code: 200,
        body: %{
          "lifetime" => %{
            "Average K/D Ratio" => average_kdr,
            "Win Rate %" => win_rate,
            "Wins" => wins,
            "Matches" => total_games,
            "Average Headshots %" => headshots_percents,
            "Current Win Streak" => win_streak
          },
        }
      }} ->
        embed = embed
        |> put_field("Средний КДА", average_kdr)
        |> put_field("Винрейт", win_rate <> "%")
        |> put_field("Побед/Всего игр", wins <> "/" <> total_games)
        |> put_field("Средний процент хедшотов", headshots_percents <> "%")
        {:ok, %{ id: win_rate_role_id }} = Register.assign_role_for_win_rate(win_rate, guild_id)
        {:ok, %{ id: kdr_role_id }} = Register.assign_role_for_kdr(average_kdr, guild_id)
        Api.modify_guild_member!(guild_id, user_id, roles: [win_rate_role_id, kdr_role_id])
        embed = if win_streak != "0", do: put_description(embed, "ВИНСТРИК " <> win_streak <> " ИГР"), else: embed
      d ->
        embed
        |> put_description("Не удалось загрузить статистику по CS:GO")
    end
  end

  defp assign_nickname_to_user_id!(nickname, user_id) do
    {:ok, _} = Redix.command(:redix, ["HSET", "nicknames", user_id, nickname])
    nickname
  end

  def get_nickname_by_user_id(user_id) do
    case Redix.command(:redix, ["HGET", "nicknames", user_id]) do
      {:ok, nickname} when nickname != nil -> nickname
      _ -> nil
    end
  end
end
