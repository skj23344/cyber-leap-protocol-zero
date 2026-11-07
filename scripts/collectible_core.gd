extends Area2D

var base_y: float = 0.0
var collected = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready():
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	if not collected:
		# Floating sinusoidal bobbing + subtle rotation
		var t = Time.get_ticks_msec() * 0.004
		position.y = base_y + sin(t) * 8.0
		sprite.rotation = sin(t * 0.5) * 0.2

func _on_body_entered(body: Node2D):
	if collected:
		return
	if body.is_in_group("player"):
		collected = true
		$CollisionShape2D.set_deferred("disabled", true)
		sprite.hide()
		particles.emitting = true
		
		# Notify LevelManager
		var lm = get_tree().get_first_node_in_group("level_manager")
		if lm and lm.has_method("collect_core"):
			lm.collect_core()
			
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("collect")
			
		await get_tree().create_timer(0.4).timeout
		queue_free()
