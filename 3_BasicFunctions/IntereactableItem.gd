extends RigidBody2D

@export var item_id = 0
@export var texture_path = ""
@export var item_amount = 1
@export var item_scale = Vector2(0.5, 0.5)

var is_container = false
var container = null
var container_size = Vector2(0,0)
var label_position = Vector2(8,2)

@onready var outline_sprite := $OutlineSprite
@onready var main_sprite := $MainSprite
@onready var area_collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var rigid_collision_shape: CollisionShape2D = $CollisionShape2D

@onready var label: Label = $Label
	
var player_in_range := false

func _ready():
	initialize()
	if item_amount > 1: 
		label.text = str(item_amount)
		label.visible = true
	else: label.visible = false
	
func _process(delta):
	# 物品互动
	if player_in_range and Input.is_action_just_pressed("Intereact"):
		# 判断是否是容器，如果不是，则触发拾取事件
		if !is_container:
			var inventory = get_node("/root/Main/UI/Backpack")
			if item_amount > 1 and CommonFunction.item_list[item_id].max_stack > 1:
				var remain_amount = item_amount
				for i in item_amount:
					if inventory.add_new_item(CommonFunction.item_list[item_id], texture_path): 
						remain_amount -= 1
						if remain_amount == 0: 
							queue_free()
							return
					else: item_amount = remain_amount
				if item_amount > 1: 
					label.text = str(item_amount)
					label.visible = true
				else: label.visible = false		
				return
			if inventory.add_new_item(CommonFunction.item_list[item_id], texture_path): 
				queue_free()
				print("pick it up")
			else: print("cannot pick it up")
			return
		# 如果是容器且容器未开启，则触发打开容器事件
		if is_container and !container.visible:
			var UI = get_node("/root/Main/UI")
			remove_child(container)
			UI.add_child(container)
			container.visible = true
			container.position = Vector2(250, 60)
			CommonFunction.SwitchMoveFunc(false)
			return
	# 容器窗口关闭
	if is_container and container.visible and (Input.is_action_just_pressed("Exit") or Input.is_action_just_pressed("Intereact")):
		var UI = get_node("/root/Main/UI")
		UI.remove_child(container)
		add_child(container)
		container.visible = false
		container.position = Vector2(0,0)
		CommonFunction.SwitchMoveFunc(true)
		
func initialize() -> void:
	# 初始化物品材质和轮廓
	texture_path = "res://Resources/Sprites/Items/item_"+str(item_id)+".png"
	if texture_path.is_empty(): push_error(texture_path+"路径材质不存在")
	var loaded_texture = load(texture_path)
	if loaded_texture is not Texture:push_error(texture_path+"文件格式错误")
	main_sprite.texture = loaded_texture
	outline_sprite.texture = loaded_texture
	outline_sprite.material = ShaderMaterial.new()
	outline_sprite.material.shader = load("res://6_shaders/white_outline.gdshader")
	outline_sprite.visible = false
	main_sprite.scale = item_scale
	outline_sprite.scale = item_scale
	# 初始化物品材质和碰撞体积尺寸
	var scale_factor = Vector2(loaded_texture.get_width()/32.0, loaded_texture.get_height()/32.0)
	area_collision_shape.scale = scale_factor*item_scale
	rigid_collision_shape.scale = scale_factor*item_scale
	label.position = label_position * scale_factor
	# 初始化物品容器属性
	is_container = CommonFunction.item_list[item_id].is_container
	container_size = CommonFunction.item_list[item_id].container_size
	if !is_container: return
	var item_container = load("res://3_BasicFunctions/ItemContainer.tscn")
	container = item_container.instantiate()
	add_child(container)
	container.is_player_container = false
	container.grid_rows = container_size.x
	container.grid_columns = container_size.y
	container.initialize()
	container.visible = false
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	# 玩家进入碰撞范围物品白色描边
	print("enter")
	if body.is_in_group("Player"):
		player_in_range = true
		outline_sprite.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	# 玩家离开碰撞范围物品白色描边
	if body.is_in_group("Player"):
		player_in_range = false
		outline_sprite.visible = false

func Use(used_item_id: int) -> void:
	var player = get_node_or_null("/root/Main/Player")
	var texture_progress_bar = get_node_or_null("/root/Main/UI/TextureProgressBar")
	if used_item_id == 1: 
		player.hp_max += 20
		player.hp += 40
	if used_item_id == 9: 
		player.hp += 30
		
