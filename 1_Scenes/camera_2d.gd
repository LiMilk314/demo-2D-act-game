extends Camera2D

var shake_power: float = 0.0
var shake_decay: float = 5.0  # 抖动衰减速度
var max_shake_offset: Vector2 = Vector2(10, 10)  # 最大抖动幅度

func _process(delta):
	if shake_power > 0:
		# 计算随机偏移
		var new_offset = Vector2(
			randf_range(-max_shake_offset.x, max_shake_offset.x) * shake_power,
			randf_range(-max_shake_offset.y, max_shake_offset.y) * shake_power
		)
		
		# 应用偏移
		offset = new_offset
		
		# 衰减抖动强度
		shake_power = max(shake_power - shake_decay * delta, 0)
	else:
		# 重置相机位置
		offset = Vector2.ZERO

# 外部调用此方法触发抖动
func shake(power: float):
	shake_power = power
