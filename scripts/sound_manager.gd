extends Node

# SoundManager: Centralized Audio Controller for Cyber Leap
var sounds = {}
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 8

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Load all audio assets
	var sound_files = {
		"jump": "res://assets/audio/jump.wav",
		"dash": "res://assets/audio/dash.wav",
		"collect": "res://assets/audio/collect.wav",
		"stomp": "res://assets/audio/stomp.wav",
		"hit": "res://assets/audio/hit.wav",
		"portal": "res://assets/audio/portal.wav",
		"laser": "res://assets/audio/laser.wav",
		"boss_roar": "res://assets/audio/boss_roar.wav",
		"bgm": "res://assets/audio/bgm.wav",
		"slash": "res://assets/audio/slash.wav",
		"shoot": "res://assets/audio/shoot.wav",
		"weapon_pickup": "res://assets/audio/weapon_pickup.wav",
		"parry": "res://assets/audio/parry.wav"
	}
	
	for name in sound_files:
		var stream = load(sound_files[name])
		if stream:
			sounds[name] = stream
			
	# Create SFX pool
	for i in range(MAX_SFX_PLAYERS):
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
		
	# Create BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -6.0
	add_child(bgm_player)
	play_bgm()

func play_sfx(sound_name: String, pitch_scale: float = 1.0):
	if not sounds.has(sound_name):
		return
	var stream = sounds[sound_name]
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch_scale + randf_range(-0.06, 0.06)
			p.volume_db = 0.0
			p.play()
			return
	# If all busy, steal first one
	sfx_players[0].stream = stream
	sfx_players[0].pitch_scale = pitch_scale
	sfx_players[0].play()

func play_bgm():
	if sounds.has("bgm") and bgm_player:
		bgm_player.stream = sounds["bgm"]
		bgm_player.play()
		if not bgm_player.finished.is_connected(_on_bgm_finished):
			bgm_player.finished.connect(_on_bgm_finished)

func _on_bgm_finished():
	if bgm_player:
		bgm_player.play()
