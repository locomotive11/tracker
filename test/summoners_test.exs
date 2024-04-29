defmodule SummonersTest do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  @tag run: true
  test "get summoner puuid", %{bypass: bypass} do
    url = "http://localhost:#{bypass.port}"

    bypass_data = %{"puuid" => "my_puuid", "gameName" => "Fred", "tagLine" => "Yabba"}

    # camel case to snake case
    expected_response = %{puuid: "my_puuid", game_name: "Fred", tag_line: "Yabba"}

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(
        conn,
        200,
        Jason.encode!(bypass_data)
      )
    end)

    {:ok, result} = Tracker.Summoners.get_summoner_puuid("Fred", "Yabba", url)

    assert result == expected_response
  end

  @tag run: true
  test "get summoner matches status code 200", %{bypass: bypass} do
    url = "http://localhost:#{bypass.port}"

    bypass_data = ["NA1_MATCHID1234"]

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(
        conn,
        200,
        Jason.encode!(bypass_data)
      )
    end)

    {:ok, result} = Tracker.Summoners.get_summoner_matches("testing_puuid", 1, url)

    assert result == bypass_data
    assert Enum.count(result) == 1
  end

  @tag run: true
  test "get summoner matches status code 429", %{bypass: bypass} do
    url = "http://localhost:#{bypass.port}"

    resp_data = %{
      "status_code" => 429,
      "body" => %{"status" => %{"message" => "Rate limit exceeded", "status_code" => 429}}
    }

    Bypass.expect(bypass, fn conn ->
      conn =
        Plug.Conn.put_resp_header(conn, "Retry-After", "4")

      Plug.Conn.resp(
        conn,
        429,
        Jason.encode!(resp_data)
      )
    end)

    {:error, 429, headers, result} =
      Tracker.Summoners.get_summoner_matches("testing_puuid", 1, url)

    assert result["status_code"] == resp_data["status_code"]
    assert result["body"]["status"]["message"] == resp_data["body"]["status"]["message"]
    assert Enum.any?(headers, fn hdr -> hdr == {"Retry-After", "4"} end)
  end

  @tag run: true
  test "get match participants status code 200", %{bypass: bypass} do
    url = "http://localhost:#{bypass.port}"
    match = "NA1_MATCHID_1234"

    bypass_data = %{
      "info" => %{
        "participants" => [
          %{
            "riotIdGameName" => "Fred",
            "riotIdTagline" => "Flintstone",
            "matches" => ["#{match}"],
            "puuid" => "abc_1234_my_puuid"
          },
          %{
            "riotIdGameName" => "Barney",
            "riotIdTagline" => "Rubble",
            "matches" => ["#{match}"],
            "puuid" => "cba_4321_my_puid"
          }
        ]
      }
    }

    expected_response = [
      %{
        game_name: "Fred",
        tag_line: "Flintstone",
        matches: ["#{match}"],
        puuid: "abc_1234_my_puuid"
      },
      %{game_name: "Barney", tag_line: "Rubble", matches: ["#{match}"], puuid: "cba_4321_my_puid"}
    ]

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(
        conn,
        200,
        Jason.encode!(bypass_data)
      )
    end)

    {:ok, participants} =
      Tracker.Summoners.get_match_participants(match, url)

    fred = List.first(participants)
    barney = List.last(participants)

    assert Enum.count(participants) == 2

    assert fred == List.first(expected_response)
    assert barney == List.last(expected_response)
  end
end
