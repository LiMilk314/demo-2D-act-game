extends TileMapLayer

func _ready():
	# 连接物理信号
	self.connect("body_entered", self, "_on_body_entered")
	self.connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
	# 当有物体进入TileMap的碰撞区域时
	if body.name == "Player":
		print("Player entered TileMap area!")
		# 执行相应操作，例如调整TileMap的透明度
		self.modulate = Color(1, 1, 1, 0.5)  # 设置透明度为0.5

func _on_body_exited(body):
	# 当有物体离开TileMap的碰撞区域时
	if body.name == "Player":
		print("Player exited TileMap area!")
		# 执行相应操作，例如恢复TileMap的透明度
		self.modulate = Color(1, 1, 1, 1)  # 设置透明度为1
