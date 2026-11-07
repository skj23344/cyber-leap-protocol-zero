extends Area2D

@export var cycle_active: float = 1.6
@export var cycle_inactive: float = 1.4

var timer: float = 0.0
var is_active: bool = true

@onready var beam_rect: ColorRect = $BeamRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	body_entered.connect(_on_body_entered)
	update_state()

func _physics_process(delta: float):
	timer += delta
	var current_limit = cycle_active if is_active else cycle_inactive
	
	# Flickering effect when about to switch
	if not is_active and timer > current_limit - 0.5:
		beam_rect.color.a = 0.3 if fmod(timer * 20.0, 2.0) > 1.0 else 0.05
	
	if timer >= current_limit:
		timer = 0.0
		is_active = not is_active
		update_state()

func update_state():
	collision_shape.set_deferred("disabled", not is_active)
	if is_active:
		beam_rect.color = Color(1.0, 0.0, 0.33, 0.85) # Vivid Magenta
		var sm = get_node_or_null("/root/SoundManager")
		if sm:
			sm.play_sfx("laser", 0.9)
	else:
		beam_rect.color = Color(1.0, 0.0, 0.33, 0.08) # Dim warning outline

func _on_body_entered(body: Node2D):
	if is_active and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, 0.0)
