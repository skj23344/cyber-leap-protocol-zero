extends CanvasLayer

@onready var hp_container: HBoxContainer = $MarginContainer/VBoxContainer/TopBar/HPContainer
@onready var dash_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/DashBar
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/TopBar/WeaponLabel
@onready var core_label: Label = $MarginContainer/VBoxContainer/TopBar/CoreLabel
@onready var stage_label: Label = $MarginContainer/VBoxContainer/TopBar/StageLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopBar/TimerLabel

@onready var game_over_panel: Panel = $GameOverPanel
@onready var victory_panel: Panel = $VictoryPanel
@onready var victory_stats_label: Label = $VictoryPanel/VBoxContainer/StatsLabel

var elapsed_time: float = 0.0
var timer_running: bool = true

func _ready():
	game_over_panel.hide()
	victory_panel.hide()

func _process(delta: float):
	if timer_running:
		elapsed_time += delta
		var minutes = int(elapsed_time / 60.0)
		var seconds = fmod(elapsed_time, 60.0)
		timer_label.text = "TIME: %02d:%05.2f" % [minutes, seconds]

func update_hp(current: int, max_val: int):
	for i in range(hp_container.get_child_count()):
		var child = hp_container.get_child(i)
		if i < current:
			child.modulate = Color(0.0, 0.94, 1.0, 1.0) # Bright Cyan
		else:
			child.modulate = Color(0.3, 0.3, 0.3, 0.4) # Depleted

func update_dash(ratio: float):
	dash_bar.value = ratio * 100.0
	if ratio >= 1.0:
		dash_bar.modulate = Color(0.0, 1.0, 0.8)
	else:
		dash_bar.modulate = Color(0.5, 0.8, 1.0)

func update_weapon(weapon_name: String):
	if weapon_name == "blade":
		weapon_label.text = "WEAPON: [ ⚔️ 赛博光刃 // [J] 挥砍/反弹 ]"
		weapon_label.modulate = Color(0.0, 0.94, 1.0)
	elif weapon_name == "blaster":
		weapon_label.text = "WEAPON: [ 🔫 等离子枪 // [J] 连射 ]"
		weapon_label.modulate = Color(0.2, 1.0, 0.6)
	else:
		weapon_label.text = "WEAPON: [ 空手 (找寻地面武器) ]"
		weapon_label.modulate = Color(0.6, 0.6, 0.7)

func update_cores(collected: int, total: int):
	core_label.text = "DATA CORES: %d / %d" % [collected, total]
	if collected >= total:
		core_label.modulate = Color(0.0, 1.0, 0.5)
	else:
		core_label.modulate = Color(1.0, 0.85, 0.2)

func set_stage_name(st_name: String):
	stage_label.text = st_name

func show_game_over():
	timer_running = false
	game_over_panel.show()

func show_stage_clear(is_final: bool = false):
	timer_running = false
	victory_panel.show()
	var minutes = int(elapsed_time / 60.0)
	var seconds = fmod(elapsed_time, 60.0)
	var time_str = "%02d:%05.2f" % [minutes, seconds]
	if is_final:
		$VictoryPanel/VBoxContainer/TitleLabel.text = "★ PROTOCOL COMPLETED ★\n恭喜通关！所有数据矩阵已破译！"
		$VictoryPanel/VBoxContainer/NextPromptLabel.text = "按 [R] 重新挑战极速记录"
	else:
		$VictoryPanel/VBoxContainer/TitleLabel.text = "STAGE CLEARED // 阶段突破"
		$VictoryPanel/VBoxContainer/NextPromptLabel.text = "正在进入跃迁通道..."
	victory_stats_label.text = "通关用时: " + time_str
