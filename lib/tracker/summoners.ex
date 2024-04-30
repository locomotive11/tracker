defmodule Tracker.Summoners do
  @moduledoc """
    This is the context module for tracking summoner matches
  """
  require Logger
  alias Tracker.RiotApi

  @api_key Application.compile_env!(:tracker, :api_key)

  @doc """
    Returns a unique list of summoners who have played with the given summoner in their last 5 matches.
    See Tracker.track_summoner/2 for additional documentation.
  """
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

  @doc """
    Returns a summoner puuid from the Riot Games account-v1 api.

    ## Parameters
    - game_name: String that represents the Riot API gameName
    - tag_line: String that represents the Riot API tagLine

    ## Example
    iex> Tracker.Summoners.get_summoner_puuid("Schuler", "NA1")
    {:ok,
     %{
       game_name: "Schuler",
       tag_line: "NA1",
       puuid: "bojt5-cZF9VPkfB1rRQddm6GvvOc70c2OTO878ig_ZVfV0Wln412oxjuw0UT_H07G2OBZtMyRDVtlQ"
     }}

  """

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

    case RiotApi.make_api_request(url) do
      {:ok, 200, resp} ->
        {:ok, %{game_name: resp["gameName"], tag_line: resp["tagLine"], puuid: resp["puuid"]}}

      {:error, 429, headers, resp} ->
        Logger.info(
          "Rate Throttling - get_summoner_puuid game_name: #{game_name} tag_line: #{tag_line} \n headers: #{inspect(headers)}"
        )

        {:error, %{resp: resp.body}}

      {:error, msg} ->
        Logger.notice("METHOD: get_summoner_puuid #{inspect(msg)}")
        {:error, inspect(msg)}
    end
  end

  @doc """
    Returns the last x number of matches for the given puuid

    ## Parameters
      - puuid String representing the unique id for a summoner
      - match_limit Integer respresenting the number of recent match ids to return (optional defaults to 5 matches)
      - url String representing the endpoint for the api call (optional defaults to nil is useful for testing)

  ## Example
  iex> Tracker.Summoners.get_summoner_matches("bojt5-cZF9VPkfB1rRQddm6GvvOc70c2OTO878ig_ZVfV0Wln412oxjuw0UT_H07G2OBZtMyRDVtlQ", 5, nil)
  {:ok,
   ["NA1_4986981570", "NA1_4986962961", "NA1_4986941599", "NA1_4986926239",
    "NA1_4985873060"]}

  """

  @spec get_summoner_matches(String.t(), pos_integer()) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def get_summoner_matches(puuid, match_limit \\ 5, url \\ nil) do
    url =
      if is_nil(url) do
        "https://americas.api.riotgames.com/lol/match/v5/matches/by-puuid/#{puuid}/ids?start=0&count=#{match_limit}&api_key=#{@api_key}"
      else
        url
      end

    case RiotApi.make_api_request(url) do
      {:ok, 200, resp} ->
        # IO.inspect(resp, label: "FROM get_summoner_matches OK")
        {:ok, resp}

      {:error, 429, headers, resp} ->
        Logger.debug(
          "Rate Throttling - Summoners.get_summoner_matches() headers: #{inspect(headers)}"
        )

        {:error, 429, headers, resp}

      {:error, msg} ->
        Logger.error("METHOD: get_summoner_matches() #{inspect(msg)}")
        {:error, inspect(msg)}
    end
  end

  @doc """
    Returns a list of participants for a given match id.

    ## Parameters
      -matches List of Strings, or String representing Riot Games match ids

    ## Examples
    iex(5)> Tracker.Summoners.get_match_participants(["NA1_4986981570", "NA1_4986962961"])
    {:ok,
     [
       %{
         matches: ["NA1_4986981570"],
         game_name: "Dagarin",
         tag_line: "NA1",
         puuid: "rjB_o96EsYolGVnh90uHMRLFtJzo4IjQQl0BybxUuv-pQt53BiGMYFZt140QYA1MMgj3vKJyPf6mkw"
       },
       %{
         matches: ["NA1_4986981570"],
         game_name: "Wibby",
         tag_line: "NA1",
         puuid: "O-bCSqumIGvd8GdYWNF0CZpRiz6o2OUZOcKtkmjTD-TBZISXZHw3Tq08Yy6PZYm7N-eTEbsQ2dzNJg"
       } ...]}

       iex(6)> Tracker.Summoners.get_match_participants("NA1_4986962961")
       {:ok,
        [
          %{
            matches: ["NA1_4986962961"],
            game_name: "Schuler",
            tag_line: "NA1",
            puuid: "bojt5-cZF9VPkfB1rRQddm6GvvOc70c2OTO878ig_ZVfV0Wln412oxjuw0UT_H07G2OBZtMyRDVtlQ"
          },
          %{
            matches: ["NA1_4986962961"],
            game_name: "ArctiqueWolf",
            tag_line: "NA1",
            puuid: "tTvbKOWIQ1aQXDai3tyzm5_xJdf0h0_Dc5a9QQLGEi_0ZFsI9Osajh6ziwr3x-fVB2oQSP6CtjpP0Q"
          } ...]}

  """

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

    case RiotApi.make_api_request(url) do
      {:ok, 200, resp_body} ->
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

      {:error, 429, _headers, resp} ->
        Logger.debug("Rate Throttling - get_match_participants MatchID: #{match}")

        {:error, %{resp: resp.body}}

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Starts a Tracker.PlayerWorker for each summoners in the participants list
  Returns the pid of the Tracker.PlayerWorker and the Riot Games riotId

  ## Parameters
    - participants a List of summoner maps

  ## Example
  iex(7)> Tracker.Summoners.start_tracking_participants([   %{
  ...(7)>      matches: ["NA1_4986962961"],
  ...(7)>      game_name: "ArctiqueWolf",
  ...(7)>      tag_line: "NA1",
  ...(7)>      puuid: "tTvbKOWIQ1aQXDai3tyzm5_xJdf0h0_Dc5a9QQLGEi_0ZFsI9Osajh6ziwr3x-fVB2oQSP6CtjpP0Q"
  ...(7)>    },
  ...(7)>    %{
  ...(7)>      matches: ["NA1_4986962961"],
  ...(7)>      game_name: "IAmNotAHealer",
  ...(7)>      tag_line: "NA1",
  ...(7)>      puuid: "1lJWf68lvbjcaBnLNWPDYfTuzgDv6ArwB_3cWKQQFfDzqcFwugyx4TnWvmyqDIauxT1P8iROaF-cVA"
  ...(7)>    }])
  {:ok,
   [
     %{pid: #PID<0.266.0>, riot_id: "ArctiqueWolf_NA1"},
     %{pid: #PID<0.267.0>, riot_id: "IAmNotAHealer_NA1"}
   ]}
  """

  @spec start_tracking_participants([
          %{game_name: String.t(), tag_line: String.t(), puuid: String.t(), matches: [String.t()]}
        ]) :: {:ok, [%{pid: pid(), riotId: String.t()}]}
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
