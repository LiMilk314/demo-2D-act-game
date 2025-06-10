extends Node

enum QUALITY{POLLUTED=1,SCRAP,COMPRESSED,REFINED, FLAWLESS, FISSILE}#污染级，废料级，压缩级，精炼级，无瑕级，裂变级
var quality_color_list = [
	Color(200.0/255,160.0/255,160.0/255,90.0/255), #槽位空背景
	Color(160.0/255,160.0/255,160.0/255,90.0/255), #污染级背景
	Color(148.0/255,190.0/255,52.0 /255,90.0/255), #废料级背景
	Color(76.0 /255,190.0/255,119.0/255,90.0/255), #压缩级背景
	Color(104.0/255,202.0/255,185.0/255,90.0/255), #精炼级背景
	Color(156.0/255,101.0/255,177.0/255,90.0/255), #无瑕级背景
	Color(355.0/255,63.0 /255,70.0 /255,90.0/255) #裂变级背景
	]
class ItemData:
	var item_id: int
	var item_name: String
	var weight: float
	var quality: QUALITY
	var price: int
	var description: String
	var is_usable: bool
	var effect: String
	var max_stack: int
	var item_size: Vector2
	var is_container: bool
	var container_size: Vector2
	var is_specific_container: bool
	var specific_stack_item: int
	var specific_max_stack : int

var item_list = {}

class SlotData: 
	var item_data: ItemData
	var item_amount: int
	var item_zero_index: int
	var is_rotate: bool
	var texture_path: String

func _enter_tree() -> void:
	ReadItemList()
	
# 随机数发生函数
static func Possibility(possibility: float) -> bool:
	# 检测参数合法性，概率应该在0-1之间
	assert(possibility > 0 and possibility <= 1, "input possibility is out of range!!!")
	# 返回随机概率结果	
	var ran_num = randf_range(0,1)
	if ran_num < possibility: return true
	else: return false
	
# 切换玩家动作开启关闭函数
static func SwitchMoveFunc(is_movable: bool) -> void:
	if is_movable == true:
		var event_A = InputEventKey.new()
		event_A.keycode = KEY_A
		event_A.physical_keycode = true
		var event_D = InputEventKey.new()
		event_D.keycode = KEY_D
		event_D.physical_keycode = true
		var event_SPACE = InputEventKey.new()
		event_SPACE.keycode = KEY_SPACE
		event_SPACE.physical_keycode = true
		var event_LMB = InputEventMouseButton.new()
		event_LMB.button_index = MOUSE_BUTTON_LEFT
		event_LMB.pressed = true  
		InputMap.action_add_event("MoveLeft", event_A)	
		InputMap.action_add_event("MoveRight", event_D)	
		InputMap.action_add_event("Jump", event_SPACE)	
		InputMap.action_add_event("Attack", event_LMB)	
		print("动作绑定已添加")
	if is_movable == false:
		InputMap.action_erase_event("MoveLeft", InputMap.action_get_events("MoveLeft")[0])	
		InputMap.action_erase_event("MoveRight", InputMap.action_get_events("MoveRight")[0])	
		InputMap.action_erase_event("Jump", InputMap.action_get_events("Jump")[0])	
		InputMap.action_erase_event("Attack", InputMap.action_get_events("Attack")[0])	
		print("动作绑定已移除")

# 读取物品列表函数		
func ReadItemList() -> void:
	var item_list_data_csv = preload("res://Resources/item_list.csv")
	var item_list_data = item_list_data_csv.records
	print(item_list_data)
	for i in item_list_data.size():
		var item_data = ItemData.new()
		item_data.item_id = item_list_data[i]["item_id"]
		item_data.item_name = item_list_data[i]["item_name"]
		item_data.weight = item_list_data[i]["weight"]
		item_data.quality = item_list_data[i]["quality"] as QUALITY
		item_data.price = item_list_data[i]["price"]
		item_data.description = item_list_data[i]["description"]
		item_data.is_usable = item_list_data[i]["is_usable"]
		item_data.effect = item_list_data[i]["effect"]
		item_data.max_stack = item_list_data[i]["max_stack"]
		item_data.item_size = Vector2(item_list_data[i]["item_size_x"],item_list_data[i]["item_size_y"])
		item_data.is_container =  item_list_data[i]["is_container"]
		item_data.container_size = Vector2(item_list_data[i]["container_size_x"],item_list_data[i]["container_size_y"])
		item_data.is_specific_container = item_list_data[i]["is_specific_container"]
		item_data.specific_stack_item = item_list_data[i]["specific_stack_item"]
		item_data.specific_max_stack = item_list_data[i]["specific_max_stack"]
		item_list[item_data.item_id] = item_data
