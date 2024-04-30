defmodule Tracker do
  @moduledoc """
  Documentation for `Tracker`.
  """

  @doc """
    Returns a unique list of summoners who have played with the given summoner in their last 5 matches.

    ## Parameters
      - game_name: String that represents the Riot API gameName
      - tag_line: String that represents the Riot API tagLine

    ## Example

      iex> Tracker.track_summoner("Schuler", "NA1")
      ["b bob_glide_1", "Poro Or Gee_NA1_2", "PNL_777_3", "IAmNotAHealer_NA1_4",
       "ArctiqueWolf_NA1_5", "Schuler_NA1_6", "T3ABAGS_NA1_7", "Demonata64_NA1_8",
       "Mgklasesd_123_9", "Gia Phong_phong_10", "mingwa redmage_NA1_11",
       "catbarde_2468_12", "chronicc_NA1_13", "NoodleLegacy_NA1_14",
       "Lv6Slime_NA1_15", "L9 6ix9ine69_NA1_16", "RangariCat_NA1_17",
       "Soupisgood_NA1_18", "Quantum Damage_6277_19", "The One God_NA1_20",
       "LightsCameraAksh_NA1_21", "Pierates_NA1_22", " Vºid Walker_NA1_23",
       "GL Sosa_NA1_24", "你和时间皆是刺客_终不似救赎_25",
       "Iwanttofight10_2913_26", "长风渡_6348_27", "Cake and Souls_9884_28",
       "羊爺喜啦_852_29", "GworHaYun_117_30", "Kurly Boy_NA1_31",
       "TheSuperior_NA1_32", "THREECATT_852_33", "Lofi Beat_NA1_34", "Jobee_42069_35",
       "Mr Zhu_NA1_36", "TyMonster_NA1_37", "St0rm13_NA1_38", "Metroidz_NA1_39",
       "Kauzh_NA1_40", "GentleSnow_NA1_41", "WhosFhamsIsThis_2090_42",
       "faade_2112_43", "Thhranyenth_NA1_44", "Arvenipher_NA1_45", "True_Yoari_46"]

  """

  @spec track_summoner(String.t(), String.t()) :: [String.t()]
  def track_summoner(game_name, tag_line) do
    Tracker.Summoners.track_summoner(game_name, tag_line)
  end
end
