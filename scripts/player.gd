extends CharacterBody2D

signal hp_changed(current_hp: int, max_hp: int)
signal dash_ratio_changed(ratio: float)
signal weapon_changed(weapon_name: String)
signal died

# Weapon System
var current_weapon: String = "none" # "none", "blade", "blaster"
var attack_cooldown_timer: float = 0.0
const BLADE_COOLDOWN = 0.28
const BLASTER_COOLDOWN = 0.2

var slash_scene = preload("res://scenes/player_slash.tscn")
var bullet_scene = preload("res://scenes/player_bullet.tscn")
var weapon_sprite: Sprite2D = null

# Movement Constants
const SPEED = 280.0
const ACCELERATION = 1800.0
const FRICTION = 1400.0
const GRAVITY = 1100.0
const JUMP_VELOCITY = -450.0
const DOUBLE_JUMP_VELOCITY = -400.0
const WALL_SLIDE_SPEED = 100.0
const WALL_JUMP_VELOCITY = Vector2(300.0, -420.0)

# Dash Constants
const DASH_SPEED = 720.0
const DASH_DURATION = 0.16
const DASH_COOLDOWN = 0.75

# Health
var max_hp = 3
var current_hp = 3
var is_invulnerable = false
var invulnerable_timer = 0.0

# State variables
var can_double_jump = true
var coyote_timer = 0.0
const COYOTE_TIME = 0.12
var jump_buffer_timer = 0.0
const JUMP_BUFFER_TIME = 0.12

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 1.0
var facing_direction = 1.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var jump_particles: CPUParticles2D = $JumpParticles
@onready var wall_ray_left: RayCast2D = $WallRayLeft
@onready var wall_ray_right: RayCast2D = $WallRayRight

var ghost_timer = 0.0
const GHOST_INTERVAL = 0.035

func _ready():
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("dash_ratio_changed", 1.0)
	
	weapon_sprite = Sprite2D.new()
	weapon_sprite.position = Vector2(6, 2)
	weapon_sprite.scale = Vector2(0.65, 0.65)
	weapon_sprite.hide()
	add_child(weapon_sprite)
	emit_signal("weapon_changed", current_weapon)

func _physics_process(delta: float):
	# Handle invulnerability flashing
	if is_invulnerable:
		invulnerable_timer -= delta
		sprite.modulate.a = 0.3 if fmod(invulnerable_timer * 16.0, 2.0) > 1.0 else 1.0
		if invulnerable_timer <= 0:
			is_invulnerable = false
			sprite.modulate.a = 1.0

	# Dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		var ratio = 1.0 - clamp(dash_cooldown_timer / DASH_COOLDOWN, 0.0, 1.0)
		emit_signal("dash_ratio_changed", ratio)
	else:
		emit_signal("dash_ratio_changed", 1.0)

	# Handle Active Dash
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0.0
		# Spawn neon ghost afterimages
		ghost_timer -= delta
		if ghost_timer <= 0:
			ghost_timer = GHOST_INTERVAL
			spawn_ghost()
		move_and_slide()
		if dash_timer <= 0:
			is_dashing = false
		return

	# Coyote Time & Ground checks
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		can_double_jump = true
	else:
		coyote_timer -= delta
		velocity.y += GRAVITY * delta

	# Jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# Horizontal Input
	var input_dir = 0.0
	if Input.is_action_pressed("move_left"):
		input_dir -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir += 1.0

	if input_dir != 0:
		facing_direction = input_dir
		sprite.flip_h = (facing_direction < 0)
		if weapon_sprite:
			weapon_sprite.flip_h = (facing_direction < 0)
			weapon_sprite.position.x = -6.0 if facing_direction < 0 else 6.0
		velocity.x = move_toward(velocity.x, input_dir * SPEED, ACCELERATION * delta)
		if is_on_floor():
			dust_particles.emitting = true
		else:
			dust_particles.emitting = false
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		dust_particles.emitting = false

	# Attack cooldown & input
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	if Input.is_action_just_pressed("attack"):
		perform_attack()

	# Wall Slide detection
	var is_touching_wall = (wall_ray_left.is_colliding() or wall_ray_right.is_colliding()) and not is_on_floor()
	if is_touching_wall and velocity.y > 0:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		can_double_jump = true

	# Jump execution
	if jump_buffer_timer > 0:
		if coyote_timer > 0:
			# Normal Ground Jump
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			trigger_jump_fx()
		elif is_touching_wall:
			# Wall Jump
			var wall_dir = -1.0 if wall_ray_right.is_colliding() else 1.0
			velocity.x = wall_dir * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y
			facing_direction = wall_dir
			sprite.flip_h = (facing_direction < 0)
			jump_buffer_timer = 0.0
			trigger_jump_fx()
		elif can_double_jump:
			# Double Jump
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			jump_buffer_timer = 0.0
			trigger_jump_fx(1.2)

	# Dash Trigger
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		start_dash()

	# Sprite tilt / squash & stretch based on movement
	if is_on_floor():
		sprite.rotation = move_toward(sprite.rotation, input_dir * 0.08, 0.2)
	else:
		sprite.rotation = move_toward(sprite.rotation, velocity.x * 0.0006, 0.1)

	# Pit fall death check
	if global_position.y > 760:
		take_damage(max_hp)

	move_and_slide()

func start_dash():
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	dash_direction = facing_direction
	ghost_timer = 0.0
	spawn_ghost()
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("dash")

func trigger_jump_fx(pitch: float = 1.0):
	jump_particles.restart()
	jump_particles.emitting = true
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("jump", pitch)

func spawn_ghost():
	var ghost = Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_position = sprite.global_position
	ghost.flip_h = sprite.flip_h
	ghost.rotation = sprite.rotation
	ghost.scale = sprite.scale
	ghost.modulate = Color(0.0, 0.94, 1.0, 0.6) # Cyan glow
	get_parent().add_child(ghost)
	
	# Tween fade out and destroy
	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)

func bounce_stomp():
	velocity.y = JUMP_VELOCITY * 0.9
	can_double_jump = true
	trigger_jump_fx(1.3)
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("stomp")

func take_damage(amount: int = 1, from_dir: float = 0.0):
	if is_invulnerable or current_hp <= 0:
		return
	current_hp -= amount
	emit_signal("hp_changed", current_hp, max_hp)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("hit")

	# Knockback
	velocity = Vector2(-facing_direction * 220.0, -280.0)

	if current_hp <= 0:
		die()
	else:
		is_invulnerable = true
		invulnerable_timer = 1.2

func die():
	current_hp = 0
	emit_signal("hp_changed", 0, max_hp)
	emit_signal("died")
	hide()
	set_physics_process(false)
	# Death particle explosion
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("hit", 0.6)

func heal(amount: int = 1):
	current_hp = min(max_hp, current_hp + amount)
	emit_signal("hp_changed", current_hp, max_hp)

func equip_weapon(w_type: String):
	current_weapon = w_type
	emit_signal("weapon_changed", current_weapon)
	if weapon_sprite:
		weapon_sprite.show()
		if current_weapon == "blade":
			weapon_sprite.texture = load("res://assets/textures/weapon_blade_pickup.png")
		elif current_weapon == "blaster":
			weapon_sprite.texture = load("res://assets/textures/weapon_blaster_pickup.png")

func perform_attack():
	if current_weapon == "none":
		return
	if attack_cooldown_timer > 0:
		return

	if current_weapon == "blade":
		attack_cooldown_timer = BLADE_COOLDOWN
		var slash = slash_scene.instantiate()
		slash.global_position = global_position + Vector2(facing_direction * 22.0, 0)
		slash.facing_direction = facing_direction
		get_parent().add_child(slash)
		
		# Slight forward nudge when slashing
		velocity.x += facing_direction * 70.0
		
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("slash", 1.0)
	elif current_weapon == "blaster":
		attack_cooldown_timer = BLASTER_COOLDOWN
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position + Vector2(facing_direction * 24.0, 0)
		bullet.direction = facing_direction
		get_parent().add_child(bullet)
		
		# Tiny recoil
		velocity.x -= facing_direction * 35.0
		
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("shoot", 1.0)
