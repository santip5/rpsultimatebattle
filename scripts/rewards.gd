extends Control

class RewardDef:
	var id: String
	var title: String
	var desc: String

	func _init(_id: String, _title: String, _desc: String) -> void:
		id = _id
		title = _title
		desc = _desc

@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressLabel
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel

@onready var card_buttons: Array[Button] = [
	$MarginContainer/VBoxContainer/HBoxContainer/RewardCard1,
	$MarginContainer/VBoxContainer/HBoxContainer/RewardCard2,
	$MarginContainer/VBoxContainer/HBoxContainer/RewardCard3,
]

var rng := RandomNumberGenerator.new()
var shown_rewards: Array[RewardDef] = []

var all_rewards: Array[RewardDef] = [
	RewardDef.new("PERMA_DMG",         "+5 Permanent Damage",         "All your attacks deal +5 extra damage."),
	RewardDef.new("BLOCK_PER_TURN",    "+5 Block Every Turn",         "Gain 5 block at the start of every round."),
	RewardDef.new("REROLL",            "+1 Reroll Per Fight",         "Once per fight, redraw your whole hand."),
	RewardDef.new("CHIP_BONUS",        "Sharpened Chips",             "Your chip damage deals +3 extra damage."),
	RewardDef.new("PIERCE_BONUS",      "Sharpened Pierce",            "Your piercing damage deals +5 extra damage."),
	RewardDef.new("ROCK_DMG",          "Rock Blessing",               "Rock cards deal +5 bonus damage."),
	RewardDef.new("PAPER_BLOCK",       "Paper Aura",                  "Paper cards grant +10 extra block."),
	RewardDef.new("SCISSOR_PIERCE",    "Scissor Edge",                "Scissor cards gain +5 extra pierce."),
	RewardDef.new("ROCK_WIN_BONUS",    "Rock Specialist",             "+5 damage when you win with Rock."),
	RewardDef.new("PAPER_WIN_BONUS",   "Paper Specialist",            "+5 damage when you win with Paper."),
	RewardDef.new("SCISSOR_WIN_BONUS", "Scissor Specialist",          "+5 damage when you win with Scissors."),
	]

func _ready() -> void:
	rng.randomize()
	_update_progress_text()
	_setup_info_text()
	_pick_and_show_rewards()
	_connect_buttons()

func _update_progress_text() -> void:
	var cleared := RunState.fights_cleared
	var total := RunState.total_fights
	progress_label.text = "Fights cleared: %d / %d" % [cleared, total]

func _setup_info_text() -> void:
	info_label.text = "Choose one reward to power up your next fight."

func _pick_and_show_rewards() -> void:
	var pool := all_rewards.duplicate()
	pool.shuffle()

	shown_rewards.clear()
	for i in range(3):
		shown_rewards.append(pool[i])

	for i in range(3):
		var btn := card_buttons[i]
		var content: VBoxContainer = btn.get_node("CardContent")
		var title_label: Label = content.get_node("TitleLabel")
		var desc_label: Label = content.get_node("DescLabel")

		title_label.text = shown_rewards[i].title
		desc_label.text = shown_rewards[i].desc

func _connect_buttons() -> void:
	for i in range(card_buttons.size()):
		card_buttons[i].pressed.connect(_on_reward_button_pressed.bind(i))

func _on_reward_button_pressed(index: int) -> void:
	var reward := shown_rewards[index]
	_apply_reward(reward.id)
	_go_to_next_scene()

func _apply_reward(id: String) -> void:
	match id:
		"PERMA_DMG":
			RunState.bonus_damage += 5

		"BLOCK_PER_TURN":
			RunState.block_per_turn += 5

		"REROLL":
			RunState.rerolls_per_fight += 1

		"CHIP_BONUS":
			RunState.chip_bonus += 3

		"PIERCE_BONUS":
			RunState.pierce_bonus += 5

		# Element / archetype rewards
		"ROCK_DMG":
			RunState.rock_bonus += 5

		"PAPER_BLOCK":
			RunState.paper_block_bonus += 10

		"SCISSOR_PIERCE":
			RunState.scissor_pierce_bonus += 5

		# Win-specialist rewards
		"ROCK_WIN_BONUS":
			RunState.rock_win_bonus += 5  

		"PAPER_WIN_BONUS":
			RunState.paper_win_bonus += 5 

		"SCISSOR_WIN_BONUS":
			RunState.scissor_win_bonus += 5

func _go_to_next_scene() -> void:
	if RunState.fights_cleared < RunState.total_fights:
		get_tree().change_scene_to_file("res://scenes/battle.tscn")
