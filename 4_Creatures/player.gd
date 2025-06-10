extends CharacterBody2D

enum STATE {IDLE, RUN, JUMP, ATTACK, HIT}
var current_state: STATE = STATE.IDLE
var direction = 0
var is_jumping = false
var is_attacking = false

@export var run_speed = 200
@export var jump_speed = -400
@export var acceleration = 2000
var gravity = ProjectSettings.get("physics/2d/default_gravity") as float

@export var hp = 100:
	set(value):
		if value > hp_max: hp = hp_max
		else: hp = value
		var tween = create_tween()
		tween.tween_property(texture_progress_bar, "value", 100 * hp/hp_max, 0.5)

@export var hp_max = 100:
		set(value):
			hp_max = value
			var tween = create_tween()
			tween.tween_property(texture_progress_bar, "size:x", 0.5 * value, 1)

@export var damage = 50

@onready var graphics = $Graphics
@onready var hit_box: HitBox = $HitBox
@onready var animation = $AnimationPlayer
@onready var layer_front = $"../Tilemap/TileMapLayer_front"
@onready var ui = $"../UI"
@onready var texture_progress_bar: TextureProgressBar = $"../UI/TextureProgressBar"
@onready var timers = {
		jump_request = $Timers/JumpRequest,
		jump_coyote = $Timers/JumpCoyote,
		attack_calm = $Timers/AttackCalm
	}


func _physics_process(delta: float) -> void:
	StateMachine(delta)
	
# 状态机总控制函数	
func StateMachine(delta:float) -> void:
	var next_state = current_state
	var allow_jump = is_on_floor() or timers.jump_coyote.time_left > 0

	direction = Input.get_axis("MoveLeft","MoveRight")
	
	#角色翻转
	if not is_zero_approx(direction) and !is_attacking:
		graphics.scale.x = -1 if direction < 0 else 1
		hit_box.scale.x = -1 if direction < 0 else 1
	#预指令跳跃
	if not is_on_floor() and\
	 Input.is_action_just_pressed("Jump"):
		timers.jump_request.start()
		
	match current_state:
		STATE.IDLE:
			if Input.is_action_just_pressed("Attack"):
				next_state = STATE.ATTACK
			elif allow_jump and (Input.is_action_just_pressed("Jump") or timers.jump_request.time_left > 0):
				next_state = STATE.JUMP
			elif !is_zero_approx(direction):
				next_state = STATE.RUN
				
		STATE.RUN:
			if Input.is_action_just_pressed("Attack"):
				next_state = STATE.ATTACK
			elif allow_jump and (Input.is_action_just_pressed("Jump") or timers.jump_request.time_left > 0):
				next_state = STATE.JUMP
			elif is_zero_approx(direction):
				next_state = STATE.IDLE
				
		STATE.JUMP:
			if Input.is_action_just_pressed("Attack"):
				next_state = STATE.ATTACK
			elif is_on_floor(): next_state = STATE.IDLE
			
		STATE.ATTACK:
			if timers.attack_calm.time_left == 0:
				if allow_jump and (Input.is_action_just_pressed("Jump") or timers.jump_request.time_left > 0):
					next_state = STATE.JUMP
				elif !is_zero_approx(direction):
					next_state = STATE.RUN
				elif is_zero_approx(direction):
					next_state = STATE.IDLE
		
	if next_state != current_state:
		NextState(next_state)
		print("[%s] => [%s]" % [str(current_state), str(next_state)])
		current_state = next_state
		
	StateCycle(delta)
	
	# 实现跳跃的CoyoteTime
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	if is_on_floor() != was_on_floor:
		if was_on_floor and not is_jumping:
			timers.jump_coyote.start()
			
# 各状态时循环函数	
func StateCycle(delta: float) -> void:
	match current_state:
		STATE.IDLE:
			Move(0, direction, delta)
			animation.play("idle")
		
		STATE.RUN:
			Move(run_speed, direction, delta)
			animation.play("run")
		
		STATE.JUMP:
			Move(run_speed, direction, delta)
			animation.play("jump")
			# 实现小跳功能
			if Input.is_action_just_released("Jump")\
			and velocity.y < jump_speed * 0.5: 
				velocity.y = jump_speed * 0.5

		STATE.ATTACK:
			if is_jumping: Move(run_speed, direction, delta)
			else: Move(0, direction, delta)
			animation.play("attack1")

# 状态转换时单次触发函数	
func NextState(next_state: STATE) -> void:
	match next_state:	
		STATE.JUMP:
			velocity.y = jump_speed
			timers.jump_coyote.stop()
			timers.jump_request.stop()
			is_jumping = true
			is_attacking = false
		STATE.IDLE:
			is_jumping = false
			is_attacking = false
		STATE.RUN:
			is_jumping = false
			is_attacking = false
		STATE.ATTACK:
			timers.attack_calm.start()
			timers.jump_coyote.stop()
			timers.jump_request.stop()
			is_attacking = true
			

# 移动函数
func Move(speed: int, direction: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y += gravity * delta

# 进入前景时前景透明
func _on_front_envi_area_body_entered(body: Node2D) -> void:
	print(body.name)
	if body == layer_front: 
		layer_front.modulate = Color(1, 1, 1, 0.5)

# 离开前景恢复透明度	
func _on_front_envi_area_body_exited(body: Node2D) -> void:
	if body == layer_front: layer_front.modulate = Color(1, 1, 1, 1)

# 受伤功能
func _on_hurt_box_hurt(hitbox: HitBox) -> void:
	var damage = hitbox.owner.damage
	var knock_direction: Vector2
	knock_direction.x = sign(global_position.x - hitbox.global_position.x)
	knock_direction.y = -0.3
	velocity = knock_direction * 500
	move_and_slide()
	# 屏幕抖动和闪红效果
	var screen_effects = get_node("/root/Main/ScreenEffects")
	var camera = get_node("/root/Main/Player/Camera2D")
	camera.shake(0.5)
	# 受伤音效
	var sfx = get_node("/root/Main/Audios/SFX")
	var hurt_sound = preload("res://Resources/SFXs/hurt.mp3")
	sfx.stream = hurt_sound
	sfx.play()
	if hp - damage <= 0: 
		hp = 0
		set_collision_layer_value(2, false)
		hide()
		screen_effects.dead_red()
		await get_tree().create_timer(0.5).timeout
		await get_tree().create_timer(1).timeout
		get_tree().reload_current_scene()
	else: 
		hp -= damage
		screen_effects.flash_red()
		
		
