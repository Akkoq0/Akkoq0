class_name MatchVictoryEvaluator
extends RefCounted
## Pure, deterministic, multiplayer-safe Victory & Defeat Evaluator (rank 2).
## Evaluates Conquest, Kut/Kurgan Hegemony, Time-Horizon Dominance, and
## Dynasty Extinction across both Singleplayer and Online Multiplayer.

const REASON_CONQUEST: StringName = &"conquest_hegemony"
const REASON_KUT_HEGEMONY: StringName = &"kut_hegemony"
const REASON_TIME_DOMINANCE: StringName = &"time_dominance"
const REASON_DYNASTY_EXTINCT: StringName = &"dynasty_extinct"


class PlayerStandingInput:
	extends RefCounted
	var player_id: int = 1
	var kut: float = 50.0
	var controlled_regions: int = 1
	var total_regions: int = 10
	var hegemony_seasons: int = 0
	var dynasty_extinct: bool = false
	var active_armies: int = 1

	func _init(
			p_id: int = 1,
			p_kut: float = 50.0,
			p_ctrl: int = 1,
			p_total: int = 10,
			p_heg_seasons: int = 0,
			p_extinct: bool = false,
			p_armies: int = 1) -> void:
		player_id = p_id
		kut = clampf(p_kut, 0.0, 100.0)
		controlled_regions = maxi(p_ctrl, 0)
		total_regions = maxi(p_total, 1)
		hegemony_seasons = maxi(p_heg_seasons, 0)
		dynasty_extinct = p_extinct
		active_armies = maxi(p_armies, 0)


class MatchOutcomeResult:
	extends RefCounted
	var concluded: bool = false
	var winner_id: int = 0
	var reason: StringName = &""
	var is_local_victory: bool = false


static func evaluate(
		standings: Array[PlayerStandingInput],
		current_season: int,
		quick_match: bool,
		local_player_id: int = 1) -> MatchOutcomeResult:
	var out: MatchOutcomeResult = MatchOutcomeResult.new()
	if standings.is_empty():
		return out

	var conquest_ratio: float = 0.40 if quick_match else 0.60
	var kut_threshold: float = 70.0 if quick_match else 85.0
	var req_heg_seasons: int = 2 if quick_match else 4
	var max_seasons: int = 16 if quick_match else 48

	var alive_players: Array[PlayerStandingInput] = []
	for s: PlayerStandingInput in standings:
		if s == null:
			continue
		if not s.dynasty_extinct and (s.controlled_regions > 0 or s.active_armies > 0):
			alive_players.append(s)

	# 1. Last Dynasty Standing
	if alive_players.size() == 1 and standings.size() > 1:
		out.concluded = true
		out.winner_id = alive_players[0].player_id
		out.reason = REASON_CONQUEST
		out.is_local_victory = (out.winner_id == local_player_id)
		return out

	# 2. Local extinction check
	for s: PlayerStandingInput in standings:
		if s != null and s.player_id == local_player_id and s.dynasty_extinct:
			out.concluded = true
			out.winner_id = alive_players[0].player_id if not alive_players.is_empty() else 0
			out.reason = REASON_DYNASTY_EXTINCT
			out.is_local_victory = false
			return out

	# 3. Conquest & Kut Hegemony thresholds (deterministic lowest player_id tie-break)
	var sorted: Array[PlayerStandingInput] = alive_players.duplicate()
	sorted.sort_custom(func(a: PlayerStandingInput, b: PlayerStandingInput) -> bool:
		var score_a: float = a.kut + float(a.controlled_regions) * 8.0
		var score_b: float = b.kut + float(b.controlled_regions) * 8.0
		if not is_equal_approx(score_a, score_b):
			return score_a > score_b
		return a.player_id < b.player_id)

	for s: PlayerStandingInput in sorted:
		var share: float = float(s.controlled_regions) / float(maxi(s.total_regions, 1))
		if share >= conquest_ratio:
			out.concluded = true
			out.winner_id = s.player_id
			out.reason = REASON_CONQUEST
			out.is_local_victory = (out.winner_id == local_player_id)
			return out
		if s.kut >= kut_threshold and s.hegemony_seasons >= req_heg_seasons:
			out.concluded = true
			out.winner_id = s.player_id
			out.reason = REASON_KUT_HEGEMONY
			out.is_local_victory = (out.winner_id == local_player_id)
			return out

	# 4. Time-Horizon Dominance
	if current_season >= max_seasons and not sorted.is_empty():
		out.concluded = true
		out.winner_id = sorted[0].player_id
		out.reason = REASON_TIME_DOMINANCE
		out.is_local_victory = (out.winner_id == local_player_id)
		return out

	return out
