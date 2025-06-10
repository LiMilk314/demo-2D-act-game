extends MarginContainer

@onready var area_2d: Area2D = $Area2D
@onready var description: Node2D = $Description
@onready var options: Node2D = $Options

@onready var slot_bg: ColorRect = $SlotBG
@onready var item_sprite: Sprite2D = $ItemSprite
@onready var quan_label: Label = $QuanLabel
@onready var describe_label: Label = $Description/Panel/GridContainer/DescribeLabel
@onready var effect_label: Label = $Description/Panel/GridContainer/EffectLabel

var item_container = null
var is_draging = false
var drag_slot_index = -1
var drag_slot_data = null
var drag_item_sprite = null
var drag_offset = Vector2(0,0)
var item_end_slot = null

var this_slot_data: CommonFunction.SlotData

func _ready() -> void:
	description.visible = false
	options.visible = false
	area_2d.visible = false
	slot_bg.color = CommonFunction.quality_color_list[0]
	if get_parent().name == "root": item_container = null
	else: item_container = get_parent().get_parent().get_parent()
	

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# 鼠标右键在范围内点击打开物品功能选项
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			item_end_slot.options.visible = true
			item_end_slot.find_child("UseButton").visible = this_slot_data.item_data.is_usable
			item_end_slot.description.visible = false
			
	# 鼠标左键在范围内按住开始物品拖拽
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			item_end_slot.description.visible = false
			item_end_slot.options.visible = false
			is_draging = true
			drag_slot_index = this_slot_data.item_zero_index
			drag_slot_data = item_container.slots[this_slot_data.item_zero_index]
			item_container.delete_item(this_slot_data.item_zero_index)
			# 创建临时物品图标到鼠标当前位置
			drag_item_sprite = Sprite2D.new()
			add_child(drag_item_sprite)
			drag_item_sprite.z_index = 2
			drag_item_sprite.z_as_relative = false
			var drag_item_texture = load(drag_slot_data.texture_path)
			drag_item_sprite.texture = drag_item_texture
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			var item_size = drag_slot_data.item_data.item_size
			var drag_slot_global_pos = item_container.grid_container.get_child(drag_slot_index).global_position
			drag_offset = get_global_mouse_position()- drag_slot_global_pos - 8 * 1.5 * Vector2(item_size)
			drag_item_sprite.global_position = get_global_mouse_position() - drag_offset
			if drag_slot_data.is_rotate: drag_item_sprite.rotation_degrees = -90
			else: drag_item_sprite.rotation_degrees = 0

func _input(event):
	# 鼠标左键点击任意位置并且物品功能选项打开，则关闭物品功能选项
	if event is InputEventMouseButton:
		if event.pressed and options.visible:
			await get_tree().process_frame
			var item_size = this_slot_data.item_data.item_size
			item_end_slot.options.visible = false


	# 临时物品图标跟随鼠标移动，辅助玩家进行拖拽
	if  event is InputEventMouseMotion and is_draging:
		print("正在拖拽")
		drag_item_sprite.global_position = get_global_mouse_position() - drag_offset
	# 临时物品图标旋转
	if  event.is_action_pressed("Rotate") and is_draging:
		var new_size = Vector2 (drag_slot_data.item_data.item_size.y,drag_slot_data.item_data.item_size.x)
		drag_slot_data.item_data.item_size = new_size
		# 让drag_slot_data的is_rotate切换
		drag_slot_data.is_rotate = !drag_slot_data.is_rotate
		# 根据当前slot的is_rotate数据进行临时图标的旋转
		if drag_slot_data.is_rotate: drag_item_sprite.rotation_degrees = -90
		else: drag_item_sprite.rotation_degrees = 0
		
		
		
	# 鼠标左键松开并且正在拖拽物品，则完成物品拖拽行为
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed and is_draging == true:
			is_draging = false
			var target_item_container = get_slot_under_mouse()["target_item_container"]
			var target_slot_index = get_slot_under_mouse()["target_slot_index"]
			# 判定鼠标是否拖拽到槽位中，未成功直接回原来位置
			if target_item_container and target_slot_index != -1: 
				var target_slot_data = target_item_container.slots[target_slot_index]
				print("找到槽位")
				# 先判定槽位是否为空,空则放入物品
				if target_item_container.is_allow_add(drag_slot_data.item_data, target_slot_index):
					print(drag_slot_data.item_amount)
					target_item_container.add_item_to_index(drag_slot_data.item_data, drag_slot_data.item_amount, target_slot_index, drag_slot_data.is_rotate, drag_slot_data.texture_path)
			# 再判定如果槽位非空，如果相同物品且未堆叠满，则数量变化
				elif target_slot_data.item_data.item_id == drag_slot_data.item_data.item_id\
				 and target_slot_data.item_amount + drag_slot_data.item_amount <= target_slot_data.item_data.max_stack:
					target_slot_data.item_amount += drag_slot_data.item_amount
					target_item_container.grid_container.get_child(target_slot_index).update_slot(target_slot_data)
				else:
					if !item_container.is_allow_add(drag_slot_data.item_data, drag_slot_index):
						var new_size = Vector2 (drag_slot_data.item_data.item_size.y,drag_slot_data.item_data.item_size.x)
						drag_slot_data.item_data.item_size = new_size
						drag_slot_data.is_rotate = !drag_slot_data.is_rotate
					item_container.add_item_to_index(drag_slot_data.item_data, drag_slot_data.item_amount, drag_slot_index, drag_slot_data.is_rotate, drag_slot_data.texture_path)
					
			else:	
				if !item_container.is_allow_add(drag_slot_data.item_data, drag_slot_index):
					var new_size = Vector2 (drag_slot_data.item_data.item_size.y,drag_slot_data.item_data.item_size.x)
					drag_slot_data.item_data.item_size = new_size
					drag_slot_data.is_rotate = !drag_slot_data.is_rotate
				item_container.add_item_to_index(drag_slot_data.item_data, drag_slot_data.item_amount, drag_slot_index, drag_slot_data.is_rotate, drag_slot_data.texture_path)				

			# 重置拖拽相关变量
			drag_slot_index = -1
			drag_slot_data = null
			drag_item_sprite.queue_free()
			drag_item_sprite = null
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
# 获取当前鼠标所在的槽位以及对应的容器
func get_slot_under_mouse() -> Dictionary:
	var item_size = drag_slot_data.item_data.item_size
	var drag_slot_global_pos = get_global_mouse_position() - drag_offset - 8 * 1.5 * Vector2(item_size.x-1,item_size.y-1)
	for slot in get_tree().get_nodes_in_group("Slot"):
		if slot.get_global_rect().has_point(drag_slot_global_pos):
			var target_item_container = slot.item_container
			var target_slot_index = slot.get_index()
			return {"target_item_container": target_item_container, "target_slot_index": target_slot_index}
	return {"target_item_container": null, "target_slot_index": -1}
	
# 更新槽位显示
func update_slot(slot_data: CommonFunction.SlotData) -> void:
	this_slot_data = slot_data	
	var item_size = slot_data.item_data.item_size
	var item_end_slot_index = this_slot_data.item_zero_index+ (item_size.x-1)
	item_end_slot = item_container.grid_container.get_child(item_end_slot_index)
	if slot_data.item_data.item_id != 0:
		area_2d.visible = true
		slot_bg.color = CommonFunction.quality_color_list[slot_data.item_data.quality]
		if get_index() == slot_data.item_zero_index:
			item_sprite.visible = true
			item_sprite.texture = load(slot_data.texture_path)
			
			if slot_data.is_rotate: 
				item_sprite.rotation_degrees = -90
				item_sprite.position.x = item_sprite.texture.get_size().y/2
				item_sprite.position.y = item_sprite.texture.get_size().x/2
			else: 
				item_sprite.rotation_degrees = 0
				item_sprite.position.x = item_sprite.texture.get_size().x/2
				item_sprite.position.y = item_sprite.texture.get_size().y/2
		if  get_index() == slot_data.item_zero_index + (item_size.x-1) + item_container.grid_columns*(item_size.y-1):	
			if slot_data.item_amount > 1:
				quan_label.visible = true
				quan_label.text = str(slot_data.item_amount)
	else: 
		area_2d.visible = false
		item_sprite.visible = false
		quan_label.visible = false
		slot_bg.color = CommonFunction.quality_color_list[0]

# 鼠标进入开启悬停计时器	
func _on_area_2d_mouse_entered() -> void:
	if !options.visible: description.find_child("HoverTimer").start()
		
# 鼠标离开停止悬停计时器	
func _on_area_2d_mouse_exited() -> void:
	description.find_child("HoverTimer").stop()
	item_end_slot.description.visible = false
	
# 悬停计时器结束时打开描述标签
func _on_hover_timer_timeout() -> void:
	item_end_slot.open_description()

# 打开描述标签
func open_description() -> void:
	var slot_index = get_index()
	# description可见性，更新panel大小
	description.visible = true
	description.find_child("Panel").size = description.find_child("Panel").find_child("GridContainer").size
	if item_container.slots[slot_index].item_data.effect == "": effect_label.visible = false
	# description内容，包括描述和效果
	describe_label.text = item_container.slots[slot_index].item_data.description
	if item_container.slots[slot_index].item_data.effect != "":
		effect_label.text = item_container.slots[slot_index].item_data.effect

# 点击丢弃按钮时，进行物品丢弃
func _on_drop_button_button_down() -> void:
	var index = get_index()
	if item_container == null: return
	if item_container.slots[index].item_data.item_id != 0:
		item_container.drop_item(item_container.slots[index].item_zero_index)
		options.visible = false
		description.visible = false

# 点击使用按钮时，进行物品使用
func _on_use_button_button_down() -> void:
	var index = get_index()
	var intereactable_item = load("res://3_BasicFunctions/IntereactableItem.tscn").instantiate()
	add_child(intereactable_item)
	intereactable_item.Use(item_container.slots[index].item_data.item_id)
	intereactable_item.queue_free()
	item_container.delete_item(item_container.slots[index].item_zero_index)
	options.visible = false
	description.visible = false
