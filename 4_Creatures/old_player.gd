extends CharacterBody2D

enum STATE {IDLE, RUN, JUMP, WALLSLIDE, ATTACK, HIT}

var run_speed := 200
var jump_speed := -400
var wall_slide_speed := 10
var acceleration := run_speed/0.1
var gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var graphics: Node2D = $Graphics
@onready var coyote_jump_timer: Timer = $CoyoteJumpTimer
@onready var coyote_wall_slide_timer: Timer = $CoyoteWallSlideTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var wall_checker_lower: RayCast2D = $Graphics/WallCheckerLower
@onready var wall_checker_upper: RayCast2D = $Graphics/WallCheckerUpper
@onready var tile_map_layer_front: TileMapLayer = $"../Tilemap/TileMapLayer_front"
@onready var ui: CanvasLayer = $"../UI"
@onready var die_page: CanvasLayer = $"../DiePage"
@onready var win_page: CanvasLayer = $"../WinPage"

var start_position: Vector2
var is_win = false
var gem_num = 0

func _ready() -> void:
	start_position = global_position
	
func _physics_process(delta: float) -> void:
	if gem_num == 3 and !is_win:
		win_page.visible = true
		is_win = true
		gem_num = 0
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1
		timer.start()
		await timer.timeout
		timer.queue_free()
		get_tree().reload_current_scene()
		
	Move(delta)
	
#跳跃预输入窗口与按键时间控制跳跃高度
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Jump"):
		jump_request_timer.start()
	if event.is_action_released("Jump") and velocity.y < jump_speed * 0.5:
		velocity.y = jump_speed * 0.5
		
func Move(delta) -> void:
	var direction = Input.get_axis("MoveLeft","MoveRight")
	velocity.x = move_toward(velocity.x, direction * run_speed, acceleration * delta)
		
	#跳跃功能 allow_jump：允许跳跃 is_jumping：此帧开始跳跃
	var allow_jump = is_on_floor() or coyote_jump_timer.time_left > 0
	var is_jumping = false
	if allow_jump and jump_request_timer.time_left > 0:
		#预输入实现跳跃时，仅小跳
		if Input.is_action_pressed("Jump"):
			velocity.y = jump_speed
		else: 
			velocity.y = jump_speed * 0.5
		coyote_jump_timer.stop()
		jump_request_timer.stop()
		is_jumping = true
		
	#滑墙判定及垂直速度变化 is_wall_sliding：正在滑墙
	var is_wall_sliding = is_on_wall() and velocity.y > 0 and direction/get_wall_normal().x < 0\
		and wall_checker_lower.is_colliding() and wall_checker_upper.is_colliding()
	if is_wall_sliding:
		velocity.y = wall_slide_speed
	else:
		velocity.y += gravity * delta
		
	#蹬墙跳功能 allow_wall_slide_jump：允许跳跃
	var allow_wall_slide_jump = is_wall_sliding or coyote_wall_slide_timer.time_left >0
	if allow_wall_slide_jump and jump_request_timer.time_left > 0:
		velocity.y = jump_speed * 0.75
		velocity.x = get_wall_normal().x * 300
		coyote_wall_slide_timer.stop()
		
	#CoyoteTime(Jump&WallSlide)
	var was_on_floor := is_on_floor()
	var was_on_wall := is_on_wall()
	
	move_and_slide()
	
	#CoyoteTime(Jump&WallSlide)
	if is_on_floor() != was_on_floor:
		if was_on_floor and not is_jumping:
			coyote_jump_timer.start()
		else:
			coyote_jump_timer.stop()
			
	#CoyoteTime(Jump&WallSlide)
	if is_on_wall() != was_on_wall:
		if was_on_wall and not is_wall_sliding:
			coyote_wall_slide_timer.start()
		else:
			coyote_wall_slide_timer.stop()	
			
	#sprite及wall_checkers翻转	
	if not is_zero_approx(direction):
		graphics.scale.x = -1 if direction < 0 else 1

	#动画控制
	if is_on_floor():
		if is_zero_approx(direction) and is_zero_approx(velocity.x):
			animation_player.play("Idle")
		else:
			animation_player.play("Run")
	elif is_wall_sliding:
		animation_player.play("WallSlide")
	else:
		animation_player.play("Jump")




func _on_hit_box_body_entered(body: Node2D) -> void:
	print(body.name)
	if body.is_aggresive == true: 
		#等待1秒
		hide()
		die_page.visible = true
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1
		timer.start()
		await timer.timeout
		timer.queue_free()

		get_tree().reload_current_scene()
	
		
func _on_front_envi_area_body_entered(body: Node2D) -> void:
	if body == tile_map_layer_front: tile_map_layer_front.modulate = Color(1, 1, 1, 0.9)
	
func _on_front_envi_area_body_exited(body: Node2D) -> void:
	if body == tile_map_layer_front: tile_map_layer_front.modulate = Color(1, 1, 1, 1)
