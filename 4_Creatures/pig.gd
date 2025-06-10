extends CharacterBody2D

enum STATE {IDLE, WALK, RUN, JUMP, HIT}

var current_state: STATE = STATE.IDLE
var direction: int = -1
var is_preparing_run = false

# 配置参数
@export var acceleration = 500
@export var walk_speed = 100
@export var run_speed = 200
@export var jump_speed = -300
@export var jump_prob = 0.6
@export var turn_prob = 0.3
var gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@export var hp = 150
@export var hp_max = 150
@export var damage = 20

@onready var graphics = $Graphics
@onready var hit_box: HitBox = $HitBox
@onready var animation = $AnimationPlayer
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar
@onready var timers = {
		walk = $Timers/WalkTimer,
		idle = $Timers/IdleTimer,
		run = $Timers/RunTimer,
		detect_calm = $Timers/DetectCalmTimer,
		run_calm = $Timers/RunCalmTimer
	}
@onready var detectors = {
		low = $Graphics/LowChecker,
		high = $Graphics/HighChecker,
		floor = $Graphics/FloorChecker,
		player = $Graphics/PlayerChecker
	}

func _ready() -> void:
	graphics.scale.x = -direction
	hit_box.scale.x = -direction
	NextState(STATE.IDLE)

func _physics_process(delta: float) -> void:
	StateMachine(delta)
	
#状态机，总控所有行为
func StateMachine(delta: float) -> void:
	#先默认下一状态为当前状态
	var next_state = current_state
	# 环境检测
	var is_player = detectors.player.is_colliding()
	
	var is_high = detectors.high.is_colliding()
	var is_low = detectors.low.is_colliding()
	var is_floor = detectors.floor.is_colliding()
	
	var is_cliff = !is_floor and !is_high and !is_low
	var is_platform = is_floor and !is_high and is_low
	var is_wall = is_floor and is_high and is_low
		
	match current_state:
		#当前静止，如果 静止计时器结束，如果 有悬崖 或 有墙 或 过转身随机检定 则 转身，无论是否转身都行走；
		STATE.IDLE:
			if timers.idle.is_stopped():
				if is_cliff or is_wall or randf() < turn_prob: TurnAround()
				next_state = STATE.WALK
		#当前行走，如果 有平台：过跳跃检定 则 跳跃，否则静止；如果 行走计时器结束 或 有悬崖 或 有墙 则静止； 
		STATE.WALK:
			if is_platform:
				if randf() < jump_prob: next_state = STATE.JUMP
				else: next_state = STATE.IDLE
			elif timers.walk.is_stopped() or is_cliff or is_wall:
				next_state = STATE.IDLE
		#当前奔跑，如果 有平台 则 跳跃；如果 奔跑计时器结束 或 有悬崖 或 有墙 则停止； 			
		STATE.RUN:
			if is_platform:
				next_state = STATE.JUMP
			elif timers.run.is_stopped() or timers.run_calm.time_left > 0 or is_cliff or is_wall:
				next_state = STATE.IDLE
		#当前跳跃，如果 有平台，则行走；
		STATE.JUMP:
			if is_on_floor():
				next_state = STATE.WALK
	
	# 所有状态均可直接转换
	if is_player:
		if !is_preparing_run: 
			timers.detect_calm.start()
			is_preparing_run = true
		if timers.detect_calm.time_left == 0 and timers.run_calm.time_left == 0: next_state = STATE.RUN
				
	#如果下一状态和当前状态不同（即上述代码使状态发生变化），则触发状态转换函数，并且把当前状态变为计算出的下一状态
	if next_state != current_state:
		NextState(next_state)
		current_state = next_state
		
	StateCycle(delta)
	move_and_slide()
	
#进行当前状态相应的行为循环代码
func StateCycle(delta: float) -> void:
	match current_state:
		STATE.IDLE:
			Move(0, delta)
			animation.play("idle")
		
		STATE.WALK:
			Move(walk_speed, delta)
			animation.play("walk")
		
		STATE.RUN:
			Move(run_speed, delta)
			animation.play("run")
		
		STATE.JUMP:
			Move(walk_speed, delta)
			animation.play("idle")
			
#只在切换到某一状态时触发一次的代码
func NextState(next_state: STATE) -> void:

	# 进入新状态的初始化
	match next_state:
		STATE.IDLE:
			timers.idle.wait_time = randf_range(0.5, 1)
			timers.idle.start()
		
		STATE.WALK:
			timers.walk.wait_time = randf_range(0.5, 2)
			timers.walk.start()
		
		STATE.RUN:
			timers.run.start()
			is_preparing_run = false
		
		STATE.JUMP:
			velocity.y = jump_speed

# 辅助函数
func Move(speed: int, delta: float) -> void:
	velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y += gravity * delta

func TurnAround() -> void:
	direction *= -1
	graphics.scale.x = -direction
	hit_box.scale.x = -direction
	

func _on_hurt_box_hurt(hitbox: HitBox) -> void:
	var damage = hitbox.owner.damage
	if hp - damage <= 0: 
		texture_progress_bar.value = 0
		var loot_items = [6,7,8]
		randomize()
		generate_loot(9)
		generate_loot(loot_items[randi()%loot_items.size()])
		if CommonFunction.Possibility(0.5): generate_loot(loot_items[randi_range(0,2)])
		if CommonFunction.Possibility(0.1): generate_loot(10)
		queue_free()
	else: 
		hp -= damage
		texture_progress_bar.value = 100 * hp/hp_max
		var knock_direction: Vector2
		knock_direction.x = sign(global_position.x - hitbox.global_position.x)
		knock_direction.y = -0.3
		velocity = knock_direction * 200
		move_and_slide()
		await get_tree().create_timer(0.5)
		if (hitbox.global_position.x - global_position.x) * direction < 0: 
			TurnAround()

func _on_hit_box_hit(hurtbox: HurtBox) -> void:
	timers.run_calm.start()
	var knock_direction: Vector2
	knock_direction.x = sign(global_position.x - hurtbox.global_position.x)
	knock_direction.y = -0.3
	velocity = knock_direction * 300
	move_and_slide()

func generate_loot(item_id: int) -> void:
	var loot_item = load("res://3_BasicFunctions/IntereactableItem.tscn")
	var new_loot_item = loot_item.instantiate()
	get_node("/root/Main/Non-creatures").add_child(new_loot_item)
	new_loot_item.item_id = item_id
	new_loot_item.initialize()
	new_loot_item.global_position = Vector2(global_position.x, global_position.y - 20)
	new_loot_item.linear_velocity = Vector2(randf_range(-200,200), randf_range(-100, -200))

	
