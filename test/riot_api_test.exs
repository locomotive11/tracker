defmodule RiotApiTest do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  @tag run: true
  test "make status code 200 api request", %{bypass: bypass} do
    resp_data = %{
      "status_code" => 200,
      "body" => %{"puuid" => "my_puuid", "gameName" => "Fred", "tagLine" => "Yabba"}
    }

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(
        conn,
        200,
        Jason.encode!(resp_data)
      )
    end)

    assert {:ok, 200, result} =
             Tracker.RiotApi.make_api_request("http://localhost:#{bypass.port}")

    assert result["body"] == resp_data["body"]
    assert result["status_code"] == 200
  end

  @tag run: true
  test "make status code 429 api request", %{bypass: bypass} do
    # resp_body = "Hello"
    resp_data = %{
      "status_code" => 429,
      "body" => %{"status" => %{"message" => "Rate limit exceeded", "status_code" => 429}}
    }

    Bypass.expect(bypass, fn conn ->
      conn =
        Plug.Conn.put_resp_header(conn, "Retry-After", "2")

      Plug.Conn.resp(
        conn,
        429,
        Jason.encode!(resp_data)
      )
    end)

    {:error, 429, headers, result} =
      Tracker.RiotApi.make_api_request("http://localhost:#{bypass.port}")

    assert result["status_code"] == resp_data["status_code"]
    assert result["body"]["status"]["message"] == resp_data["body"]["status"]["message"]
    assert Enum.any?(headers, fn hdr -> hdr == {"Retry-After", "2"} end)
  end

  @tag run: true
  test "make status code 503 api request", %{bypass: bypass} do
    # resp_body = "Hello"
    resp_data =
      %{
        "status_code" => 503,
        "body" => %{"status" => %{"message" => "Service Unavailable", "status_code" => 503}}
      }

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(
        conn,
        503,
        Jason.encode!(resp_data)
      )
    end)

    {:error, status_code, result} =
      Tracker.RiotApi.make_api_request("http://localhost:#{bypass.port}")

    assert result["status_code"] == resp_data["status_code"]
    assert result["body"]["status"]["message"] == resp_data["body"]["status"]["message"]
    assert status_code == 503
  end
end
