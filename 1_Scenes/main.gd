extends Node2D

@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var tile_map_layer: TileMapLayer = $Tilemap/TileMapLayer
@onready var player: CharacterBody2D = $Player
@onready var music_1: AudioStreamPlayer2D = $Audios/Music1
@onready var music_2: AudioStreamPlayer2D = $Audios/Music2

var is_player_dead: bool = false

func _ready() -> void:
	CameraControl()
	music_1.play()
	music_1.volume_db = -10.0
	var audio_length = music_1.stream.get_length()
	var trigger_time = audio_length - 5.0
	print(trigger_time)
	var timer = get_tree().create_timer(trigger_time)
	timer.timeout.connect(_start_transition)

func _process(delta: float) -> void:
	PlayerDeath()
	
# 相机控制	
func CameraControl() -> void:
	var tilemap_used_range = tile_map_layer.get_used_rect().grow(-1)
	var tilemap_size = tile_map_layer.tile_set.tile_size
	# 限定摄像头范围和重置平滑
	camera_2d.limit_top = tilemap_used_range.position.y * tilemap_size.y
	camera_2d.limit_bottom = tilemap_used_range.end.y * tilemap_size.y
	camera_2d.limit_left = tilemap_used_range.position.x * tilemap_size.x
	camera_2d.limit_right = tilemap_used_range.end.x * tilemap_size.x
	camera_2d.reset_smoothing()

# 玩家坠落死亡功能	
func PlayerDeath() -> void:
	if player.global_position.y > 600 and !is_player_dead: 
		is_player_dead = true
		hide()
		# 等待1秒
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1
		timer.start()
		await timer.timeout
		timer.queue_free()
		# 重新加载场景
		get_tree().reload_current_scene()

func _start_transition() -> void:
	var current_music = music_1 if music_1.playing else music_2
	var next_music = music_2 if current_music == music_1 else music_1
	
	create_tween().tween_property(current_music, "volume_db", -50.0, 3.0)
	
	next_music.volume_db = -80.0
	next_music.play()
	create_tween().tween_property(next_music, "volume_db", -10.0, 3.0)
	#var audio_length = next_music.stream.get_length()
	#var trigger_time = audio_length - 5.0
	#var timer = get_tree().create_timer(trigger_time)
	#timer.timeout.connect(_start_transition)
