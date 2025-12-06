extends Control

enum Move { ROCK, PAPER, SCISSORS }

class Card:
	var name: String
	var desc: String = ""
	var move: Move
	var dmg_bonus: int = 0
	var block: int = 0
	var chip_damage: int = 0
	var reflect: int = 0
	var stagger: bool = false
	var grant_block_next_turn: int = 0
	var recoil: int = 0
	var pierce: int = 0
	var is_reshuffler: bool = false
	var allowed_moves: Array = []
	
	func _init(_name: String, _desc: String, _move: Move, _dmg_bonus := 0, _block := 0, _chip := 0, _reflect := 0, _stagger := false, _grant_block_next_turn := 0, _recoil := 0, _pierce := 0, _is_reshuffler := false, _allowed_moves := []) -> void:
		name = _name
		desc = _desc
		move = _move
		dmg_bonus = _dmg_bonus
		block = _block
		chip_damage = _chip
		reflect = _reflect
		stagger = _stagger
		grant_block_next_turn = _grant_block_next_turn
		recoil = _recoil
		pierce = _pierce
		is_reshuffler = _is_reshuffler
		allowed_moves = _allowed_moves
	
var all_cards: Array[Card] = [
	#ROCK
	Card.new("Heavy Rock", "A crushing blow. +20 damage.", Move.ROCK, 20,0,0,0,false,0,0,0),
	Card.new("Guard Rock", "Solid defense. +25 block.", Move.ROCK, 0,  25, 0,  0, false, 0,  0,  0),
	Card.new("Spiked Rock", "Hit and bleed. +10 dmg and 10 chip dmg.", Move.ROCK, 10,  0,  10,  0, false, 0,  0,  0),
	Card.new("Reinforced Rock", "Prepare for impact. +20 block next turn.", Move.ROCK, 0,  0,  0,  0, false, 20, 0,  0),
	Card.new("Rock Reforge", "Reshuffle your hand: Draw only Rock and Scissors cards.", Move.ROCK, 0, 0, 0, 0, false, 0, 0, 0, true, [Move.ROCK,Move.SCISSORS]), 
	
	# PAPER
	Card.new("Paper Shield", "Reliable protection. +25 block.", Move.PAPER, 0,  25, 0,  0, false, 0,  0,  0),
	Card.new("Paper Cut", "A sharp slice. +10 damage and +10 block.", Move.PAPER, 10,  10,  0,  0, false, 0,  0,  0),
	Card.new("Reflective Paper", "Reflect attacks. Deal 25 damage when you lose.", Move.PAPER, 0,  0,  0,  25, false, 0,  0,  0),
	Card.new("Confusing Fold", "Stagger the enemy. Their damage is halved if you lose.", Move.PAPER, 0,  0,  0,  0, true,  0,  0,  0),
	Card.new("Paper Reorder", "Reshuffle your hand: Draw only Paper and Rock cards.", Move.PAPER, 0,0,0,0,false,0,0,0, true, [Move.PAPER, Move.ROCK]),

	# SCISSORS
	Card.new("Quick Scissors", "Fast strike. +20 damage.", Move.SCISSORS, 20, 0,  0,  0, false, 0,  0,  0),
	Card.new("Defensive Scissors", "Cut and guard. +10 damage and +15 block.", Move.SCISSORS, 10,  15, 0,  0, false, 0,  0,  0),
	Card.new("Gun Scissors", "High-risk shot. +25 damage but take 10 recoil.", Move.SCISSORS, 25, 0,  0,  0, false, 0,  10,  0),
	Card.new("Piercing Cut", "Armor breaker. +10 damage and 15 pierce damage.", Move.SCISSORS, 10,  0,  0,  0, false, 0,  0,  15),
	Card.new("Scissor Shuffle", "Reshuffle your hand: Draw only Scissors and Paper cards.", Move.SCISSORS, 0,0,0,0,false,0,0,0, true, [Move.SCISSORS, Move.PAPER])
]

@onready var player_hp_bar: ProgressBar = $MarginContainer/HSplitContainer/VBoxContainer/VBoxContainer/PlayerHP
@onready var enemy_hp_bar: ProgressBar = $MarginContainer/HSplitContainer/VBoxContainer2/VBoxContainer/EnemyHP
@onready var player_sel: Label = $MarginContainer/HSplitContainer/VBoxContainer/PlayerSelection
@onready var enemy_sel: Label = $MarginContainer/HSplitContainer/VBoxContainer2/EnemySelection
@onready var result_label: Label = $MarginContainer/Result

@onready var slot1_btn: Button = $MarginContainer/HBoxContainer/CardSlotWrapper1/CardSlot1
@onready var slot2_btn: Button = $MarginContainer/HBoxContainer/CardSlotWrapper2/CardSlot2
@onready var slot3_btn: Button = $MarginContainer/HBoxContainer/CardSlotWrapper3/CardSlot3
@onready var card_buttons: Array[Button] = [slot1_btn, slot2_btn, slot3_btn]

var rerolls_left: int = 0
@onready var reroll_button: Button = $MarginContainer/HBoxContainer/CardSlotWrapper3/CardSlot3/RerollButton

@onready var music: AudioStreamPlayer = $Music

var max_hp := 100
var player_hp := 100
var enemy_hp := 100
var base_dmg := 15
var hand: Array[Card] = []
var next_turn_block: int = 0

var rng := RandomNumberGenerator.new()

var enemy_types = [
	{
		"name": "Rock Enemy",
		"weights": [0.7,0.15,0.15],
		"is_boss": false,
		"bonus_damage": 0,
		"block": 5,
		"thorns": 0,
		"chip_damage": 0
	},
	{
		"name": "Paper Enemy",
		"weights": [0.15,0.7,0.15],
		"is_boss": false,
		"bonus_damage": 0,
		"block": 10,
		"thorns": 0,
		"chip_damage": 0
	},
	{
		"name": "Scissors Enemy",
		"weights": [0.15,0.15,0.7],
		"is_boss": false,
		"bonus_damage": 5,
		"block": 5,
		"thorns": 0,
		"chip_damage": 0
	},
	{
		"name": "Boss",
		"weights": [0.33,.33,.34],
		"is_boss": true,
		"bonus_damage": 3,
		"block": 3,
		"thorns": 3,
		"chip_damage": 3
	},
]

var enemy_order: Array[int] = []
var current_enemy_index := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()
	_update_ui()
	_start_run()
	
	if RunState.enemy_order.is_empty():
		# First time starting a run: build enemy order
		_start_run()
	else:
		# Continuing a run: reuse existing order
		enemy_order = RunState.enemy_order
		current_enemy_index = clamp(RunState.fights_cleared, 0, enemy_order.size() - 1)
		_start_fight(enemy_order[current_enemy_index])

# ---------- BUTTONS -----------
func _on_card_slot_1_pressed() -> void:
	_play_card_index(0)

func _on_card_slot_2_pressed() -> void:
	_play_card_index(1)

func _on_card_slot_3_pressed() -> void:
	_play_card_index(2)

# ---------- CORE FLOW -----------

func _start_run() -> void:
	enemy_order.clear()
	
	var regular_indices: Array[int] = []
	var boss_index := -1
	
	for i in range(enemy_types.size()):
		if enemy_types[i]["is_boss"]:
			boss_index = i
		else:
			regular_indices.append(i)
	
	regular_indices.shuffle()
	
	enemy_order = regular_indices
	if boss_index != -1:
		enemy_order.append(boss_index)
	RunState.enemy_order = enemy_order
	RunState.total_fights = enemy_order.size()
	
	current_enemy_index = clamp(RunState.fights_cleared, 0, enemy_order.size() - 1)
	_start_fight(enemy_order[current_enemy_index])

func _start_fight(enemy_index: int) -> void:
	player_hp = max_hp
	enemy_hp = max_hp
	

	if enemy_types[enemy_index]["is_boss"]:
		music.stream = load("res://assets/boss_theme.mp3")
	else:
		music.stream = load("res://assets/enemy_theme.mp3")
	music.play()
	
	player_sel.text = ""
	enemy_sel.text = ""
	result_label.text= "Fight vs %s" % enemy_types[enemy_index]["name"]
	
	_set_card_buttons_enabled(true)
	
	_update_ui()
	
	next_turn_block = 0
	
	rerolls_left = RunState.rerolls_per_fight
	reroll_button.visible = rerolls_left > 0
	reroll_button.disabled = rerolls_left <= 0
	
	draw_hand()
	_play_hand_intro()

func _play_card_index(idx: int) -> void:
	if hand.size() <= idx:
		print("Hand does not have index: ",idx)
		return
	
	var card: Card = hand[idx]
	_play_round(card)
	
	if player_hp >0 and enemy_hp > 0:
		if card.is_reshuffler:
			_redraw_hand_filtered(card.allowed_moves)
		else:
			await _animate_card_replace(idx)

func _play_round(card: Card) -> void:
	var player_move: Move = card.move
	var enemy_move : Move = _get_enemy_move()
	var enemy = _current_enemy()
	
	_show_moves(player_move,enemy_move)
	
	var outcome := _rps_result(player_move, enemy_move) # 1 win, 0 draw, -1 lose
	match outcome:
		1:
			var total_damage := base_dmg + card.dmg_bonus + RunState.bonus_damage
			
			match player_move:
				Move.ROCK:
					total_damage += RunState.rock_bonus + RunState.rock_win_bonus
				Move.PAPER:
					total_damage += RunState.paper_win_bonus
				Move.SCISSORS:
					total_damage += RunState.scissor_win_bonus
			
			var enemy_block: int = int(enemy["block"])
			var reduced: int =  max(total_damage - enemy_block,0)
			
			enemy_hp -= reduced
			
			# Piercing damage: ignores block
			var pierce_damage := card.pierce + RunState.pierce_bonus
			if player_move == Move.SCISSORS:
				pierce_damage += RunState.scissor_pierce_bonus
			if pierce_damage > 0:
				enemy_hp -= pierce_damage
			
			var chip := card.chip_damage
			if chip > 0:
				chip += RunState.chip_bonus
				enemy_hp -= chip
				
			# Enemy thorns
			if enemy["thorns"] > 0:
				player_hp -= enemy["thorns"]
			
			result_label.text = "You win the round!"
		-1:
			var enemy_bonus: int = int(enemy["bonus_damage"])
			var incoming := base_dmg + enemy_bonus
			
			# Stagger: halve damage before block
			if card.stagger:
				incoming = int(ceil(incoming*0.5))
			
			# Total block = card block + stored next-turn block
			var total_block := card.block + next_turn_block + RunState.block_per_turn
			if player_move == Move.PAPER:
				total_block += RunState.paper_block_bonus
			next_turn_block = 0
			
			incoming = max(incoming - total_block,0)
			player_hp -= incoming
			
			if enemy["chip_damage"] > 0:
				player_hp -= enemy["chip_damage"]
			
			# Reflect damage: enemy takes damage when you lose
			if card.reflect > 0:
				enemy_hp -= card.reflect
			
			# Chip damage: card always deals damage on loss
			var chip_loss := card.chip_damage
			if chip_loss > 0:
				enemy_hp -= chip_loss + RunState.chip_bonus

			result_label.text = "You lose the round!"
		0:
			var chip_draw := card.chip_damage
			if chip_draw > 0:
				enemy_hp -= chip_draw + RunState.chip_bonus
			
			if enemy["chip_damage"] > 0:
				player_hp -= enemy["chip_damage"]
				
			result_label.text = "Draw!"
	#Self damage
	if card.recoil > 0:
		player_hp -= card.recoil
	
	if card.grant_block_next_turn > 0:
		next_turn_block += card.grant_block_next_turn
		
	_update_ui()
	_check_end()

func _get_enemy_move() -> Move:
	var enemy = _current_enemy()
	var weights = enemy["weights"] # [rock,paper, scissors]
	var r = rng.randf()
	
	if r < weights[0]:
		return Move.ROCK
	elif r < weights[0] + weights[1]:
		return Move.PAPER
	else:
		return Move.SCISSORS

func draw_hand() -> void:
	hand.clear()
	var temp := all_cards.duplicate()
	temp.shuffle()
	
	for i in range(3):
		hand.append(temp[i])

	_update_hand_ui()

func _replace_card_in_hand(idx: int) -> void:
	var temp := all_cards.duplicate()
	temp.shuffle()
	hand[idx] = temp[0]

func _redraw_hand_filtered(allowed_moves: Array) -> void:
	hand.clear()
	
	var candidates: Array[Card] = []
	for c in all_cards:
		if c.move in allowed_moves:
			candidates.append(c)
	for i in range(3):
		var idx := rng.randi_range(0,candidates.size()-1)
		hand.append(candidates[idx])
	_update_hand_ui()
	_play_hand_intro()

func _set_card_buttons_enabled(enabled: bool) -> void:
	for btn in card_buttons:
		btn.disabled = not enabled

func _current_enemy() -> Dictionary:
	return enemy_types[enemy_order[current_enemy_index]]

func _on_reroll_button_pressed() -> void:
	if rerolls_left <= 0:
		return
	rerolls_left -= 1
	if rerolls_left <= 0:
		reroll_button.disabled = true
		reroll_button.visible = false

	draw_hand()
	_play_hand_intro()

# ---------- UI -----------

func _show_moves(p: Move, e: Move) -> void:
	player_sel.text = "You chose %s" % _move_name(p)
	enemy_sel.text = "Enemy chose %s" % _move_name(e)

func _move_name(m: Move) -> String:
	match m:
		Move.ROCK: return "Rock"
		Move.PAPER: return "Paper"
		Move.SCISSORS: return "Scissors"
	return "?"

func _update_ui() -> void:
	player_hp = clamp(player_hp, 0, max_hp)
	enemy_hp  = clamp(enemy_hp, 0, max_hp)
	player_hp_bar.max_value = max_hp
	enemy_hp_bar.max_value  = max_hp
	player_hp_bar.value = player_hp
	enemy_hp_bar.value  = enemy_hp

func _update_hand_ui() -> void:
	for i in range(min(3, hand.size())):
		var card: Card = hand[i]
		var btn: Button = card_buttons[i]
		var content: VBoxContainer = btn.get_node("CardContent")
		var title_label: Label = content.get_node("CardTitle")
		var desc_label: Label = content.get_node("CardDesc")
		var icon_rect: TextureRect = content.get_node("CardIcon")

		title_label.text = card.name
		desc_label.text = card.desc
		icon_rect.texture = _icon_for_move(card.move)

func _icon_for_move(move: Move) -> Texture2D:
	match move:
		Move.ROCK:
			return load("res://assets/Rock.png")
		Move.PAPER:
			return load("res://assets/Paper.png")
		Move.SCISSORS:
			return load("res://assets/Scissors.png")
	return null

func _animate_card_replace(idx: int) -> void:
	var btn: Button = card_buttons[idx]
	var wrapper: Control = btn.get_parent()
	var anim: AnimationPlayer = wrapper.get_node("Anim")
	
	anim.play("swipe_out")
	await anim.animation_finished
	
	_replace_card_in_hand(idx)
	_update_hand_ui()
	
	anim.play("swipe_in")
	await anim.animation_finished

func _play_hand_intro() -> void:
	for btn in card_buttons:
		var wrapper: Control = btn.get_parent()
		var anim: AnimationPlayer = wrapper.get_node("Anim")
		anim.play("intro")

# ---------- Game Logic -----------

func _rps_result(p: Move, e: Move) -> int:
	if p == e: return 0
	if (p == Move.ROCK and e == Move.SCISSORS) or (p == Move.PAPER and e == Move.ROCK) or (p == Move.SCISSORS and e == Move.PAPER):
		return 1
	return -1

func _check_end() -> void:
	if player_hp <= 0 or enemy_hp <= 0:
		_set_card_buttons_enabled(false)
		reroll_button.disabled = true
		reroll_button.visible = false
	
	if enemy_hp <= 0 and player_hp <= 0:
		result_label.text = "Double KO!"
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	elif enemy_hp <= 0:
		result_label.text = "You won the fight!"
		RunState.fights_cleared += 1
		
		await get_tree().create_timer(1.2).timeout
		
		if RunState.fights_cleared >= RunState.total_fights:
			get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/rewards.tscn")
	elif player_hp <= 0:
		result_label.text = "You Lost."
		await get_tree().create_timer(2.0).timeout
		RunState.reset()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
