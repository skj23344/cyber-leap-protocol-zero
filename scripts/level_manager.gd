extends Node2D

@export var current_stage_num: int = 1
var total_cores_needed: int = 3
var cores_collected: int = 0

@onready var hud = $HUD
@onready var player = $Player
@onready var portal = get_node_or_null("Portal")

var stage_names = {
	1: "STAGE 01 // 启动阵列 [GENESIS GRID]",
	2: "STAGE 02 // 失控反应堆 [OVERDRIVE REACTOR]",
	3: "STAGE 03 // 终焉矩阵 [CYBER OVERLORD ARENA]"
}

func _ready():
	add_to_group("level_manager")
	setup_inputs()
	
	hud.set_stage_name(stage_names.get(current_stage_num, "STAGE %02d" % current_stage_num))
	if current_stage_num == 3:
		hud.core_label.text = "TARGET: BOSS OVERLORD // 终焉主脑"
		hud.core_label.modulate = Color(1.0, 0.2, 0.4)
	else:
		hud.update_cores(cores_collected, total_cores_needed)
	
	if player:
		player.hp_changed.connect(hud.update_hp)
		player.dash_ratio_changed.connect(hud.update_dash)
		player.died.connect(_on_player_died)
		player.weapon_changed.connect(hud.update_weapon)
		
	# Check if boss exists in Stage 3
	var boss = get_node_or_null("BossOverlord")
	if boss:
		boss.boss_defeated.connect(_on_boss_defeated)

func setup_inputs():
	var action_keys = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"dash": [KEY_SHIFT, KEY_K],
		"attack": [KEY_J, KEY_X],
		"restart": [KEY_R],
		"pause": [KEY_ESCAPE]
	}
	for action in action_keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in action_keys[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

	# Also add Left Mouse Click for attack
	var mouse_ev = InputEventMouseButton.new()
	mouse_ev.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mouse_ev)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("restart"):
		restart_stage()

func collect_core():
	cores_collected += 1
	hud.update_cores(cores_collected, total_cores_needed)
	if cores_collected >= total_cores_needed:
		if portal and portal.has_method("unlock"):
			portal.unlock()

func complete_stage():
	if current_stage_num < 3:
		hud.show_stage_clear(false)
		await get_tree().create_timer(1.2).timeout
		var next_path = "res://scenes/stage%d.tscn" % (current_stage_num + 1)
		get_tree().change_scene_to_file(next_path)
	else:
		hud.show_stage_clear(true)

func _on_boss_defeated():
	await get_tree().create_timer(1.5).timeout
	hud.show_stage_clear(true)

func _on_player_died():
	hud.show_game_over()

func restart_stage():
	get_tree().reload_current_scene()
