extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $Steve/AnimationPlayer
@onready var model: Node3D = $Steve
@onready var camera_pivot: Node3D = $CameraPivot

var MOUSE_SENSITIVITY := 0.003
const JUMP_VELOCITY = 4
const RUN_SPEED := 5.0
const SPRINT_SPEED := 8.0
const ACCELERATION := 10.0
const DECELERATION := 12.0

var current_speed := 0.0
var rotation_x := 0.0
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	handle_mouse_look(event)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_animations()
	handle_jump()
	handle_movement()
	move_and_slide()

func handle_mouse_look(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotation_x = clamp(
			rotation_x - event.relative.y * MOUSE_SENSITIVITY,
			deg_to_rad(-80),
			deg_to_rad(80)
		)
		camera_pivot.rotation.x = rotation_x

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func is_moving() -> bool:
	return Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up").length() > 0

func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		play_if_not("pistol-jump-run")

func handle_movement() -> void:
	var input_dir := Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		var is_sprinting := Input.is_action_just_pressed("ui_shift") and Input.is_action_just_pressed("ui_up")
		if is_sprinting:
			print(is_sprinting)
		velocity.x = direction.x * RUN_SPEED
		velocity.z = direction.z * RUN_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, RUN_SPEED)
		velocity.z = move_toward(velocity.z, 0, RUN_SPEED)

func handle_animations() -> void:
	if not is_on_floor():
		return
	
	if Input.is_action_pressed("ui_up"):
		play_if_not("pistol-run")
	elif Input.is_action_pressed("ui_down"):
		play_if_not("pistol-walk-backwards")
	elif Input.is_action_pressed("ui_left"):
		play_if_not("pistol-strafe-left")
	elif Input.is_action_pressed("ui_right"):
		play_if_not("pistol-strafe-right")
	else:
		play_if_not("pistol-idle")

func play_if_not(anim_name: String) -> void:
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
