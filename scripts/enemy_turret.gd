extends StaticBody2D

@export var fire_interval: float = 2.0
@export var detection_range: float = 450.0
@export var max_hp: int = 2

var current_hp: int = 2
var fire_timer: float = 0.0
var target_player: Node2D = null
var bullet_scene = preload("res://scenes/bullet.tscn")
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_pos: Marker2D = $ShootPos

func _ready():
	add_to_group("enemies")
	current_hp = max_hp
	fire_timer = randf_range(0.5, 1.5)

func take_damage(amount: int = 1):
	if is_dead:
		return
	current_hp -= amount
	# Flash white
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.06)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.06)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("hit", 1.2)
		
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	sprite.hide()
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("stomp", 0.9)
	queue_free()

func _physics_process(delta: float):
	if not target_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]

	if target_player and is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= detection_range:
			# Aim at player
			var angle = (target_player.global_position - global_position).angle()
			# Barrel points downward by default (angle + PI/2)
			sprite.rotation = angle - PI / 2.0
			
			fire_timer += delta
			if fire_timer >= fire_interval:
				fire_timer = 0.0
				shoot()

func shoot():
	if not target_player:
		return
	var b = bullet_scene.instantiate()
	b.global_position = shoot_pos.global_position
	b.direction = (target_player.global_position - shoot_pos.global_position).normalized()
	get_parent().add_child(b)
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("laser", 1.2)
