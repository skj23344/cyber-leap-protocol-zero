extends Area2D

@export var launch_force: float = -700.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		body.velocity.y = launch_force
		if "can_double_jump" in body:
			body.can_double_jump = true
		
		# Animate bounce (squash and stretch)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.4, 0.6), 0.08)
		tween.tween_property(sprite, "scale", Vector2(0.9, 1.2), 0.12)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
		
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("jump", 1.4)
