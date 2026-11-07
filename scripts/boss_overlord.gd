extends CharacterBody2D

signal boss_hp_changed(current: int, max_val: int)
signal boss_defeated

const MAX_HP = 100
var current_hp = MAX_HP
var is_invulnerable = false
var invuln_timer = 0.0

var attack_timer: float = 0.0
var move_timer: float = 0.0
var target_pos: Vector2 = Vector2.ZERO
var arena_bounds_min: Vector2 = Vector2(200, 180)
var arena_bounds_max: Vector2 = Vector2(1080, 420)

var bullet_scene = preload("res://scenes/bullet.tscn")
var drone_scene = preload("res://scenes/enemy_drone.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var death_particles: CPUParticles2D = $DeathParticles
@onready var hp_bar: ProgressBar = $BossUI/ProgressBar

func _ready():
	target_pos = global_position
	hp_bar.max_value = MAX_HP
	hp_bar.value = current_hp
	emit_signal("boss_hp_changed", current_hp, MAX_HP)
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("boss_roar")

func _physics_process(delta: float):
	if current_hp <= 0:
		return

	# Invulnerability flashing
	if is_invulnerable:
		invuln_timer -= delta
		sprite.modulate = Color(1, 1, 1, 0.4) if fmod(invuln_timer * 20.0, 2.0) > 1.0 else Color(1, 0.2, 0.4)
		if invuln_timer <= 0:
			is_invulnerable = false
			sprite.modulate = Color(1, 1, 1, 1)

	# Movement: smooth hover towards target_pos
	move_timer += delta
	var move_interval = 2.8 if current_hp > 30 else 1.8
	if move_timer >= move_interval:
		move_timer = 0.0
		target_pos = Vector2(
			randf_range(arena_bounds_min.x, arena_bounds_max.x),
			randf_range(arena_bounds_min.y, arena_bounds_max.y)
		)

	global_position = global_position.lerp(target_pos, delta * 2.2)
	# Gentle floating oscillation
	sprite.rotation = sin(Time.get_ticks_msec() * 0.003) * 0.1

	# Attack pattern timer
	attack_timer += delta
	var attack_rate = 2.0 if current_hp > 65 else (1.4 if current_hp > 30 else 0.9)
	if attack_timer >= attack_rate:
		attack_timer = 0.0
		execute_attack()

func execute_attack():
	if current_hp > 65:
		# Phase 1: 5-way spread bullets
		fire_spread_bullets(5, 0.5)
	elif current_hp > 30:
		# Phase 2: 8-way circular burst + summon drone if none
		fire_circular_bullets(8)
		spawn_minion()
	else:
		# Phase 3 (Overdrive): 12-way rapid barrage
		fire_circular_bullets(12)
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("laser", 0.8)

func fire_spread_bullets(count: int, spread_angle: float):
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var target = players[0].global_position
	var base_angle = (target - global_position).angle()
	
	var start_angle = base_angle - spread_angle / 2.0
	var step = spread_angle / float(count - 1) if count > 1 else 0.0
	for i in range(count):
		var angle = start_angle + i * step
		spawn_single_bullet(Vector2(cos(angle), sin(angle)))
		
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("laser", 1.0)

func fire_circular_bullets(count: int):
	var step = (PI * 2.0) / float(count)
	for i in range(count):
		var angle = i * step + Time.get_ticks_msec() * 0.002
		spawn_single_bullet(Vector2(cos(angle), sin(angle)))
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("laser", 1.1)

func spawn_single_bullet(dir: Vector2):
	var b = bullet_scene.instantiate()
	b.global_position = global_position
	b.direction = dir
	b.speed = 240.0
	get_parent().add_child(b)

func spawn_minion():
	var existing = get_tree().get_nodes_in_group("boss_minion")
	if existing.size() < 2:
		var drone = drone_scene.instantiate()
		drone.add_to_group("boss_minion")
		drone.global_position = global_position + Vector2(randf_range(-100, 100), 50)
		get_parent().add_child(drone)

func _on_stomp_area_body_entered(body: Node2D):
	if is_invulnerable or current_hp <= 0:
		return
	if body.is_in_group("player") and body.has_method("bounce_stomp"):
		if body.global_position.y < global_position.y:
			body.bounce_stomp()
			take_damage(20)

func _on_hitbox_body_entered(body: Node2D):
	if current_hp <= 0:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, sign(body.global_position.x - global_position.x))

func take_damage(amount: int):
	if is_invulnerable or current_hp <= 0:
		return
	current_hp -= amount
	hp_bar.value = current_hp
	emit_signal("boss_hp_changed", current_hp, MAX_HP)
	
	is_invulnerable = true
	invuln_timer = 1.0
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("hit", 0.8)

	if current_hp <= 0:
		defeat()

func defeat():
	current_hp = 0
	emit_signal("boss_hp_changed", 0, MAX_HP)
	emit_signal("boss_defeated")
	death_particles.emitting = true
	$BossUI.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	$StompArea/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("boss_roar", 1.4)
		sm.play_sfx("portal")
		
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.2)
	await tween.finished
	queue_free()
