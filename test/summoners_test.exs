defmodule SummonersTest do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  @tag run: true
  test "get summoner puuid", %{bypass: bypass} do
    url = "http://localhost:#{bypass.port}"

    resp_data = %{
      status_code: 200,
      body: %{"puuid" => "my_puuid", "gameName" => "Fred", "tagLine" => "Yabba"}
    }

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(
        conn,
        200,
        Jason.encode!(resp_data)
      )
    end)

    {:ok, result} = Tracker.Summoners.get_summoner_puuid("Fred", "Yabba", url)
    IO.inspect(result, label: "FROM TEST")

    assert result["body"] == resp_data.body
  end
end
