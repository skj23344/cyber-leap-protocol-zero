extends CharacterBody2D

@export var speed: float = 80.0
@export var patrol_distance: float = 140.0

var start_x: float = 0.0
var direction: float = 1.0
var is_dead = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var death_particles: CPUParticles2D = $DeathParticles

func _ready():
	add_to_group("enemies")
	start_x = global_position.x

func take_damage(amount: int = 1):
	if is_dead:
		return
	die()

func _physics_process(delta: float):
	if is_dead:
		return
		
	# Move patrol
	velocity.x = direction * speed
	# Sine bobbing in Y
	velocity.y = sin(Time.get_ticks_msec() * 0.005) * 20.0
	
	if abs(global_position.x - start_x) > patrol_distance:
		direction = -sign(global_position.x - start_x)
		sprite.flip_h = (direction < 0)
		
	move_and_slide()

func _on_stomp_area_body_entered(body: Node2D):
	if is_dead:
		return
	if body.is_in_group("player") and body.has_method("bounce_stomp"):
		if body.global_position.y < global_position.y:
			body.bounce_stomp()
			die()

func _on_hitbox_body_entered(body: Node2D):
	if is_dead:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, direction)

func die():
	is_dead = true
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$StompArea/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	sprite.hide()
	death_particles.emitting = true
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("stomp")
	await get_tree().create_timer(0.6).timeout
	queue_free()
