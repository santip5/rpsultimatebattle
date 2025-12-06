extends Node

var fights_cleared: int = 0
var total_fights: int = 4

# Global rewards
var bonus_damage: int = 0
var block_per_turn: int = 0
var rerolls_per_fight: int = 0
var chip_bonus: int = 0
var pierce_bonus: int = 0

# Element / archetype bonuses
var rock_bonus: int = 0            # generic rock damage bonus
var paper_block_bonus: int = 0     # extra block when using paper
var scissor_pierce_bonus: int = 0  # extra pierce when using scissors

# Win-specific bonuses
var rock_win_bonus: int = 0
var paper_win_bonus: int = 0
var scissor_win_bonus: int = 0

var enemy_order: Array[int] = []

func reset() -> void:
	fights_cleared = 0
	enemy_order.clear()
	total_fights = 4

	bonus_damage = 0
	rock_bonus = 0
	paper_block_bonus = 0
	scissor_pierce_bonus = 0
	block_per_turn = 0
	rerolls_per_fight = 0
	chip_bonus = 0
	pierce_bonus = 0
	rock_win_bonus = 0
	paper_win_bonus = 0
	scissor_win_bonus = 0
