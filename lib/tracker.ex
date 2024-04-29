defmodule Tracker do
  @moduledoc """
  Documentation for `Tracker`.
  """

  @spec track_summoner(String.t(), String.t()) :: [String.t()]
  def track_summoner(game_name, tag_line) do
    Tracker.Summoners.track_summoner(game_name, tag_line)
  end
end
