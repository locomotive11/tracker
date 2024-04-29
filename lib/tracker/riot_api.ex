defmodule Tracker.RiotApi do
  @spec make_api_request(String.t()) :: {:ok, String.t()} | {:error, map()} | {:error, String.t()}
  def make_api_request(url) do
    {status, response} = HTTPoison.get(url)
    IO.inspect(Map.from_struct(response), label: "RESPONSE STRUCT")
    IO.inspect(status, label: "RESPONSE STATUS")
    response({status, Map.from_struct(response)})
  end

  defp response({:ok, %{status_code: 200}} = resp) do
    {_, resp} = resp
    {:ok, Jason.decode!(resp.body)}
  end

  defp response({:ok, %{status_code: 429}} = resp) do
    {_, resp} = resp
    IO.inspect(resp, label: "RESPONSE FROM 429 CATCH")
    body = Jason.decode!(resp.body)
    IO.inspect(body, label: "BODY FROM 429 CATCH")

    {:error,
     %{
       status_code: 429,
       message: body["body"]["status"]["message"],
       headers: resp.headers
     }}
  end

  defp response({:ok, %{status_code: status_code}} = resp) do
    {_, resp} = resp
    IO.inspect(resp, label: "RESP FROM OK CATCH-ALL")
    body = Jason.decode!(resp.body)
    IO.inspect(body, label: "BODY FROM OK CATCH-ALL")

    {:error, %{status_code: status_code, message: body["body"]["status"]["message"]}}
  end

  defp response({:error, %{}} = resp) do
    {_, resp} = resp
    IO.inspect(resp, label: "RESP FROM ERROR CATCH")
    {:error, resp["reason"]}
  end
end
