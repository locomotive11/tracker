defmodule Tracker.RiotApi do
  @moduledoc """
    Riot Api module
  """

  @doc """
    Makes a request to the Riot Games API

    ## Parameters
    -url String representing the desired api endpoint The url params include the required api_key

  """
  @spec make_api_request(String.t()) ::
          {:ok, integer(), String.t()} | {:error, integer(), map()} | {:error, String.t()}
  def make_api_request(url) do
    {status, response} = HTTPoison.get(url)

    response({status, Map.from_struct(response)})
  end

  defp response({:ok, %{status_code: 200}} = resp) do
    {_, resp} = resp
    {:ok, 200, Jason.decode!(resp.body)}
  end

  defp response({:ok, %{status_code: 429}} = resp) do
    {_, resp} = resp
    {:error, 429, resp.headers, Jason.decode!(resp.body)}
  end

  defp response({:ok, %{status_code: status_code}} = resp) do
    {_, resp} = resp
    {:error, status_code, Jason.decode!(resp.body)}
  end

  defp response({:error, %{}} = resp) do
    {_, resp} = resp

    {:error, resp.reason}
  end
end
