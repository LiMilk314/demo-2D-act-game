extends Node2D
#这是一个打开的包括多个槽位的容器

var empty_slot_data: CommonFunction.SlotData

@export var grid_rows:int = 6 #背包行数
@export var grid_columns:int = 6 #背包列数
@export var is_player_container = false #是否是玩家的背包

@onready var panel: Panel = $Panel
@onready var grid_container: GridContainer = $Panel/GridContainer

@export var slots = {} #背包槽位数据的字典

func _ready():
	empty_slot_data = CommonFunction.SlotData.new()
	empty_slot_data.item_data = CommonFunction.item_list[0]
	empty_slot_data.item_amount = 0
	empty_slot_data.item_zero_index = 0
	empty_slot_data.is_rotate = false
	empty_slot_data.texture_path = ""
	initialize()

func _physics_process(delta: float) -> void:
	# 按下退出键关闭玩家背包
	if is_player_container and Input.is_action_just_pressed("Exit"): 
		visible = false
		return
	# 按下打开物品栏键切换玩家背包可视性
	if is_player_container and Input.is_action_just_pressed("OpenInventory"):  
		visible = not visible

# 添加物品功能
func add_new_item(item_data: CommonFunction.ItemData, texture_path: String) -> bool:
	# 如果物品可堆叠，首先寻找可堆叠的已有物品
	if item_data.max_stack > 1:
		for i in slots.size():
			if slots[i].item_data.item_id == item_data.item_id and slots[i].item_amount < slots[i].item_data.max_stack:
				slots[i].item_amount  += 1
				grid_container.get_child(i).update_slot(slots[i])
				return true
	# 如果不可堆叠或未找到空槽位，则，寻找背包空槽位
	for i in slots.size():
		if is_allow_add(item_data, i):
			add_item_to_index(item_data, 1, i, false, texture_path)
			return true
	return false	

# 添加物品到指定槽位功能
func add_item_to_index(item_data: CommonFunction.ItemData, item_amount: int, item_zero_index: int, is_rotate: bool, texture_path: String) -> void:
	if is_allow_add(item_data, item_zero_index):
				for x in item_data.item_size.x:
					for y in item_data.item_size.y:	
						var index = int(item_zero_index+x+grid_columns*y)
						slots[index] = CommonFunction.SlotData.new()
						slots[index].item_data = item_data
						slots[index].item_amount = item_amount
						slots[index].item_zero_index = item_zero_index
						slots[index].is_rotate = is_rotate
						slots[index].texture_path = texture_path
						print(slots[index].item_amount)
						grid_container.get_child(index).update_slot(slots[index])
				return

# 丢弃物品功能
func drop_item(item_zero_index: int) -> void:
	# 在地面生成被丢弃物品
	var intereactable_item = load("res://3_BasicFunctions/IntereactableItem.tscn")
	var drop_item = intereactable_item.instantiate()
	drop_item.item_id = slots[item_zero_index].item_data.item_id
	get_node_or_null("/root/Main/Non-creatures").add_child(drop_item)
	var face_direction = get_node_or_null("/root/Main/Player").graphics.scale.x
	drop_item.global_position.x = get_node_or_null("/root/Main/Player").global_position.x + 10*face_direction
	drop_item.global_position.y = get_node_or_null("/root/Main/Player").global_position.y - 20
	drop_item.linear_velocity = Vector2(100*face_direction, -50)
	drop_item.initialize()
	# 在背包中删除该物品
	var size = slots[item_zero_index].item_data.item_size
	for x in size.x:
		for y in size.y:	
			var index = int(item_zero_index+x+grid_columns*y)
			slots[index] = empty_slot_data
			grid_container.get_child(index).update_slot(slots[index])

# 删除物品功能
func delete_item(item_zero_index: int) -> void:
	# 在背包中删除该物品
	var size = slots[item_zero_index].item_data.item_size
	for x in size.x:
		for y in size.y:	
			var index = int(item_zero_index+x+grid_columns*y)
			slots[index] = empty_slot_data
			grid_container.get_child(index).update_slot(slots[index])

#检测槽位能否装进物品，合法性
func is_allow_add(item_data: CommonFunction.ItemData, item_zero_index: int) -> bool:
	if item_zero_index%grid_columns + item_data.item_size.x > grid_columns: return false # 检测物品右侧是否超出容器
	if int(item_zero_index/grid_columns) + item_data.item_size.y > grid_rows: return false# 检测物品下侧是否超出容器
	for x in item_data.item_size.x:
		for y in item_data.item_size.y:
			if slots[int(item_zero_index+x+grid_columns*y)].item_data.item_id != 0: return false
	return true
	
# 初始化
func initialize() -> void:
	# 向grid_container中添加相应数量的空槽位
	visible = false
	var slot = load("res://3_BasicFunctions/Slot.tscn")	
	var slot_size = slot.instantiate().size.x
	grid_container.columns = grid_columns
	panel.size.x = slot_size * grid_columns
	panel.size.y = slot_size * grid_rows
	grid_container.size = panel.size
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
	for i in (grid_rows*grid_columns):
		var new_slot = slot.instantiate()
		grid_container.add_child(new_slot)
		slots[i] = empty_slot_data
		new_slot.update_slot(slots[i])
