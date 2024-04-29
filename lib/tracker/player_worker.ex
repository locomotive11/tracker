defmodule Tracker.PlayerWorker do
  @moduledoc """
    This is the worker module used
    to coordinate match tracking of a single summoner.
  """
  use GenServer, restart: :temporary

  @interval 60_000

  require Logger

  def start_link(args) do
    riot_id = args.game_name <> "_" <> args.tag_line

    args = Map.put(args, :riot_id, riot_id)
    GenServer.start_link(__MODULE__, args, name: via_tuple(args.riot_id))
  end

  @impl true
  def init(args) do
    {:ok, args, {:continue, args}}
  end

  @impl true
  def handle_continue(_args, state) do
    Process.send_after(self(), :check_matches, @interval)
    # exit worker after 1 hour
    Process.send_after(self(), :exit, 60 * 60 * 1000)
    {:noreply, state}
  end

  @impl true
  def handle_info(:check_matches, state) do
    past_matches = state.matches

    response =
      Tracker.Summoners.get_summoner_matches(state.puuid, 1)

    case response do
      {:ok, [last_match | _tail]} ->
        if last_match in past_matches do
          Process.send_after(self(), :check_matches, @interval)
          {:noreply, state}
        else
          new_past_matches = List.insert_at(past_matches, 0, last_match)

          new_state = Map.put(state, :matches, new_past_matches)

          Logger.info("Summoner #{state.riot_id} completed match #{last_match}")
          Process.send_after(self(), :check_matches, @interval)
          {:noreply, new_state}
        end

      {:error, %{message: _msg, headers: headers, status_code: 429}} ->
        retry_period = get_retry_period(headers)

        Logger.debug("Summoner #{state.riot_id} rate throttled retry in: #{retry_period}ms")

        Process.send_after(self(), :check_matches, retry_period)
        {:noreply, state}

      {:error, _msg} ->
        Logger.error(
          "Error retrieving match information for summoner #{state.riot_id} :: #{inspect(response)}"
        )

        Process.send_after(self(), :check_matches, @interval)
        {:noreply, state}
    end
  end

  def handle_info(:exit, state) do
    Logger.debug("Shutdown #{state.riot_id} worker.  Pid: #{inspect(self())}")
    Process.exit(self(), :shutdown)
    {:noreply, state}
  end

  defp via_tuple(name) do
    {:via, Registry, {:summoner_registry, name}}
  end

  defp get_retry_period(headers) do
    {"Retry-After", retry_period} =
      Enum.find(headers, {"Retry-After", "60"}, fn {key, _value} -> key == "Retry-After" end)

    # convert to milliseconds
    String.to_integer(retry_period) * 1000
  end
end
