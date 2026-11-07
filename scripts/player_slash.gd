extends Area2D

@export var damage: int = 2
var facing_direction: float = 1.0
var lifetime: float = 0.12

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_particles: CPUParticles2D = $HitParticles

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# Flip sprite based on direction
	if facing_direction < 0:
		scale.x = -1.0

func _physics_process(delta: float):
	lifetime -= delta
	# Fade out slightly
	sprite.modulate.a = lifetime / 0.12
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage(15)
			trigger_hit_effects(body.global_position)
	elif body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			trigger_hit_effects(body.global_position)

func _on_area_entered(area: Area2D):
	# Deflect / destroy enemy bullets!
	if area.is_in_group("enemy_bullet") or area.name.begins_with("Bullet"):
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("parry", 1.2)
		# Convert or destroy bullet
		if area.has_method("deflect"):
			area.deflect(facing_direction)
		else:
			area.queue_free()
		trigger_hit_effects(area.global_position)

func trigger_hit_effects(pos: Vector2):
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("hit", 1.3)
	hit_particles.restart()
	hit_particles.emitting = true
