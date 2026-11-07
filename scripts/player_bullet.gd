extends Area2D

@export var speed: float = 680.0
@export var damage: int = 1
var direction: float = 1.0
var lifetime: float = 1.8

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if direction < 0:
		sprite.flip_h = true

func _physics_process(delta: float):
	position.x += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage(4)
		queue_free()
	elif body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body is TileMap or body is StaticBody2D:
		queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()
