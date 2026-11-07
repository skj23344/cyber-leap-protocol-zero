extends Area2D

var is_unlocked: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var lock_label: Label = $LockLabel

func _ready():
	body_entered.connect(_on_body_entered)
	update_appearance()

func unlock():
	is_unlocked = true
	update_appearance()
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("portal")

func update_appearance():
	if is_unlocked:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		particles.emitting = true
		lock_label.text = "[ 跃迁通道已激活 // ENTER ]"
		lock_label.modulate = Color(0.0, 1.0, 0.6)
	else:
		sprite.modulate = Color(0.35, 0.2, 0.45, 0.5)
		particles.emitting = false
		lock_label.text = "[ 锁定: 需3枚核心 ]"
		lock_label.modulate = Color(1.0, 0.3, 0.4)

func _on_body_entered(body: Node2D):
	if is_unlocked and body.is_in_group("player"):
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("portal", 1.2)
		var lm = get_tree().get_first_node_in_group("level_manager")
		if lm and lm.has_method("complete_stage"):
			lm.complete_stage()
