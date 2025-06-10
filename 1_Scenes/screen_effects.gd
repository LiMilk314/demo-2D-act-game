extends CanvasLayer

@onready var overlay = $Overlay
var flash_duration = 0.15
var decay_rate = 5.0

func _ready():
	overlay.color = Color(1, 0, 0, 0) # 初始透明红色
	overlay.material = ShaderMaterial.new()
	overlay.material.shader = load("res://screen_shake.gdshader")
	
func flash_red():
	overlay.color = Color(1, 0, 0, 0.1) # 半透明红色
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, flash_duration)
	tween.set_ease(Tween.EASE_OUT)
	
func dead_red():
	overlay.color = Color(1, 0.2, 0.2, 0.5) # 半透明红色
