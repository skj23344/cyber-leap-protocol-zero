extends Area2D

@export var weapon_type: String = "blade" # "blade" or "blaster"

var base_y: float = 0.0
var picked_up: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready():
	base_y = position.y
	body_entered.connect(_on_body_entered)
	update_appearance()

func update_appearance():
	if weapon_type == "blade":
		sprite.texture = load("res://assets/textures/weapon_blade_pickup.png")
		label.text = "[ ⚔️ 赛博光刃 // 触碰拾取 ]"
		label.modulate = Color(0.0, 0.94, 1.0)
	elif weapon_type == "blaster":
		sprite.texture = load("res://assets/textures/weapon_blaster_pickup.png")
		label.text = "[ 🔫 等离子爆能枪 // 触碰拾取 ]"
		label.modulate = Color(0.2, 1.0, 0.6)

func _process(delta: float):
	if not picked_up:
		var t = Time.get_ticks_msec() * 0.004
		position.y = base_y + sin(t) * 6.0

func _on_body_entered(body: Node2D):
	if picked_up:
		return
	if body.is_in_group("player") and body.has_method("equip_weapon"):
		picked_up = true
		$CollisionShape2D.set_deferred("disabled", true)
		body.equip_weapon(weapon_type)
		
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("weapon_pickup")
			
		sprite.hide()
		label.hide()
		particles.emitting = true
		await get_tree().create_timer(0.4).timeout
		queue_free()
