defmodule Bot.FaceIT do
  use HTTPoison.Base
  alias Nostrum.Api
  alias Nostrum.Struct.{ Embed }
  alias Bot.Helpers
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

  def register_user(nickname, user_id, channel_id) do
    case get_user_stats(nickname, channel_id, user_id) do
      {:ok, nickname} when is_binary(nickname) -> assign_nickname_to_user_id!(nickname, user_id)
      _ -> nil
    end
  end

  def update_user(user_id, channel_id) do
    with nickname when is_binary(nickname) <- get_nickname_by_user_id(user_id) do
      {:ok, _} = get_user_stats(nickname, channel_id, user_id)
    else err ->
      Api.create_message!(channel_id, "<@#{user_id}>, бот не смог найти ваш никнейм. Повторите регистрацию")
    end
  end

  def get_user_stats(nickname, channel_id, user_id) do
    case get("/players?nickname=#{nickname}&game=#{@game_id}") do
      {:ok, %{ status_code: 200,
        body: %{
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
        player_afker = if afk > 0, do: "ДА", else: "НЕТ"
        player_leaver = if leaver > 0, do: "ДА", else: "НЕТ"
        embed = %Embed{}
                |> put_thumbnail(Helpers.get_user_avatar_by_user_id(user_id))
                |> put_title("#{game_player_name}")
                |> put_field("Уровень", skill_level_label)
                |> put_field("FaceIT Эло", faceit_elo)
                |> put_field("Ливер", player_leaver)
                |> put_field("АФКер", player_afker)
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
