defmodule Tracker.Summoners do
  @moduledoc """
    This is the context module for tracking summoner matches

  """
  require Logger
  alias Tracker.RiotApi

  @api_key "RGAPI-de3a99bf-f2bf-4334-ae5c-8b0ec1567d79"

  @spec track_summoner(String.t(), String.t()) :: [String.t()] | {:error, String.t()}
  def track_summoner(game_name, tag_line) do
    with {:ok, summoner} <- get_summoner_puuid(game_name, tag_line),
         {:ok, matches} <- get_summoner_matches(summoner.puuid),
         {:ok, participants} <- get_match_participants(matches),
         {:ok, _registry} <- start_tracking_participants(participants) do
      {summoner_names, _acc} =
        Enum.map_reduce(participants, 1, fn participant, acc ->
          {"#{participant.game_name}_#{participant.tag_line}_#{acc}", acc + 1}
        end)

      summoner_names
    else
      {:error, msg} ->
        Logger.error("An Error Occured: #{inspect(msg)}")
        {:error, msg}
    end
  end

  @spec get_summoner_puuid(String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, String.t()}
  def get_summoner_puuid(game_name, tag_line, url \\ nil) do
    url =
      if is_nil(url) do
        "https://americas.api.riotgames.com/riot/account/v1/accounts/by-riot-id/#{game_name}/#{tag_line}?api_key=#{@api_key}"
        |> URI.encode()
      else
        url
      end

    response = RiotApi.make_api_request(url)

    case response do
      {:ok, resp} ->
        IO.inspect(resp, label: "FROM get_summoner_puuid OK")
        {:ok, %{game_name: resp["gameName"], tag_line: resp["tagLine"], puuid: resp["puuid"]}}

      {:error, msg} ->
        Logger.notice("METHOD: get_summoner_puuid #{inspect(msg)}")
        {:error, inspect(msg)}
    end
  end

  @spec get_summoner_matches(String.t(), pos_integer()) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def get_summoner_matches(puuid, match_limit \\ 5, url \\ nil) do
    url =
      if is_nil(url) do
        "https://americas.api.riotgames.com/lol/match/v5/matches/by-puuid/#{puuid}/ids?start=0&count=#{match_limit}&api_key=#{@api_key}"
      else
        url
      end

    RiotApi.make_api_request(url)
  end

  @spec get_match_participants([String.t()]) ::
          {:ok,
           [
             %{
               game_name: String.t(),
               tag_line: String.t(),
               puuid: String.t(),
               matches: [String.t()]
             }
           ]}
  def get_match_participants(matches) when is_list(matches) do
    participants =
      Enum.reduce(matches, [], fn match, acc ->
        case get_match_participants(match) do
          {:ok, participant_list} ->
            participant_list ++ acc

          _ ->
            acc
        end
      end)
      |> Enum.reduce([], fn participant, acc ->
        index =
          Enum.find_index(acc, fn acc_participant ->
            acc_participant.puuid == participant.puuid
          end)

        if is_nil(index) do
          List.insert_at(acc, 0, participant)
        else
          old_participant_map = Enum.at(acc, index)
          matches = participant.matches ++ old_participant_map.matches
          new_participant_map = Map.put(old_participant_map, :matches, matches)

          acc = Enum.reject(acc, fn acc_summoner -> acc_summoner.puuid == participant.puuid end)
          List.insert_at(acc, 0, new_participant_map)
        end
      end)

    {:ok, participants}
  end

  @spec get_match_participants(String.t()) ::
          {:ok,
           [
             %{
               game_name: String.t(),
               tag_line: String.t(),
               matches: [String.t()],
               puuid: String.t()
             }
           ]}
          | {:error, any()}
  def get_match_participants(match, url \\ nil) when is_binary(match) do
    url =
      if is_nil(url) do
        "https://americas.api.riotgames.com/lol/match/v5/matches/#{match}?api_key=#{@api_key}"
      else
        url
      end

    response = RiotApi.make_api_request(url)

    case response do
      {:ok, resp_body} ->
        participants =
          Enum.map(resp_body["info"]["participants"], fn summoner ->
            %{
              game_name: summoner["riotIdGameName"],
              tag_line: summoner["riotIdTagline"],
              matches: ["#{match}"],
              puuid: summoner["puuid"]
            }
          end)

        {:ok, participants}

      {:error, message} ->
        {:error, message}
    end
  end

  @spec start_tracking_participants([
          %{game_name: String.t(), tag_line: String.t(), puuid: String.t(), matches: [String.t()]}
        ]) :: {:ok, [%{riotId: String.t(), pid: pid()}]}
  def start_tracking_participants(participants) do
    participant_registry =
      Enum.map(participants, fn participant ->
        {:ok, pid} =
          DynamicSupervisor.start_child(
            Tracker.SummonerSupervisor,
            {Tracker.PlayerWorker, participant}
          )

        %{riot_id: "#{participant.game_name}_#{participant.tag_line}", pid: pid}
      end)

    {:ok, participant_registry}
  end
end
