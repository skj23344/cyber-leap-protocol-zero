extends Area2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2.DOWN
var is_deflected: bool = false

func _ready():
	add_to_group("enemy_bullet")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float):
	position += direction * speed * delta

func deflect(facing_dir: float):
	is_deflected = true
	remove_from_group("enemy_bullet")
	add_to_group("player_bullet")
	direction = Vector2(facing_dir, randf_range(-0.3, 0.3)).normalized()
	speed = 550.0
	modulate = Color(0.0, 1.0, 0.8) # Turn cyan

func _on_body_entered(body: Node2D):
	if not is_deflected:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(1, direction.x)
			queue_free()
		elif body is TileMap or body is StaticBody2D:
			queue_free()
	else:
		if (body.is_in_group("enemies") or body.is_in_group("boss")) and body.has_method("take_damage"):
			body.take_damage(2)
			queue_free()
		elif body is TileMap or body is StaticBody2D:
			queue_free()

func _on_area_entered(area: Area2D):
	if is_deflected and area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(2)
		queue_free()
