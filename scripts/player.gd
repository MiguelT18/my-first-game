extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $Steve/AnimationPlayer
@onready var model: Node3D = $Steve
@onready var camera_pivot: Node3D = $CameraPivot

# Intenta encontrar el Skeleton3D automáticamente
@onready var skeleton: Skeleton3D = find_skeleton()

const SPEED = 5.0
const JUMP_VELOCITY = 4
var MOUSE_SENSITIVITY := 0.003
var rotation_x := 0.0

# Factores de rotación
var model_pitch_factor := 0.3  # Inclinación del modelo completo
var spine_rotation_factor := 0.2
var neck_rotation_factor := 0.3
var head_rotation_factor := 0.4

# Huesos
var spine_bones := ["mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2"]
var neck_bone := "mixamorig_Neck"
var head_bone := "mixamorig_Head"
var spine_bone_ids := []
var neck_bone_id := -1
var head_bone_id := -1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_bones()

func find_skeleton() -> Skeleton3D:
	# Busca recursivamente el Skeleton3D en el modelo
	return find_skeleton_recursive(model)

func find_skeleton_recursive(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		print("✓ Skeleton3D encontrado en: ", node.get_path())
		return node
	
	for child in node.get_children():
		var result = find_skeleton_recursive(child)
		if result:
			return result
	
	return null

func setup_bones():
	if not skeleton:
		print("✗ ERROR: No se encontró Skeleton3D en el modelo")
		print("Estructura del modelo:")
		debug_print_structure(model, 0)
		return
	
	print("=== Configurando huesos ===")
	
	for bone_name in spine_bones:
		var bone_id = skeleton.find_bone(bone_name)
		if bone_id != -1:
			spine_bone_ids.append(bone_id)
			print("✓ Columna: ", bone_name, " (ID: ", bone_id, ")")
		else:
			print("✗ No encontrado: ", bone_name)
	
	neck_bone_id = skeleton.find_bone(neck_bone)
	if neck_bone_id != -1:
		print("✓ Cuello: ", neck_bone, " (ID: ", neck_bone_id, ")")
	else:
		print("✗ No encontrado: ", neck_bone)
	
	head_bone_id = skeleton.find_bone(head_bone)
	if head_bone_id != -1:
		print("✓ Cabeza: ", head_bone, " (ID: ", head_bone_id, ")")
	else:
		print("✗ No encontrado: ", head_bone)
	
	var total_bones = spine_bone_ids.size()
	if neck_bone_id != -1:
		total_bones += 1
	if head_bone_id != -1:
		total_bones += 1
	
	print("=== Total: ", total_bones, " huesos configurados ===")

func debug_print_structure(node: Node, indent: int):
	var spaces = ""
	for i in range(indent):
		spaces += "  "
	print(spaces, "- ", node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		debug_print_structure(child, indent + 1)

func _unhandled_input(event: InputEvent) -> void:
	handle_mouse_look(event)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_animations()
	handle_jump()
	handle_movement()
	move_and_slide()
	
	# Aplicar inclinación del modelo
	update_model_pitch()
	
	# Aplicar rotación de huesos (DESPUÉS de las animaciones)
	update_bone_rotations()

func handle_mouse_look(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotation_x = clamp(
			rotation_x - event.relative.y * MOUSE_SENSITIVITY,
			deg_to_rad(-80),
			deg_to_rad(80)
		)
		camera_pivot.rotation.x = rotation_x

func update_model_pitch() -> void:
	# Inclinación suave del modelo completo
	model.rotation.x = lerp(model.rotation.x, rotation_x * model_pitch_factor, 0.3)

func update_bone_rotations() -> void:
	if not skeleton:
		return
	
	# La rotación restante se distribuye en los huesos
	var remaining_rotation = rotation_x * (1.0 - model_pitch_factor)
	
	# Rotar columna
	for bone_id in spine_bone_ids:
		rotate_bone(bone_id, remaining_rotation * spine_rotation_factor)
	
	# Rotar cuello
	if neck_bone_id != -1:
		rotate_bone(neck_bone_id, remaining_rotation * neck_rotation_factor)
	
	# Rotar cabeza
	if head_bone_id != -1:
		rotate_bone(head_bone_id, remaining_rotation * head_rotation_factor)

func rotate_bone(bone_id: int, angle: float) -> void:
	# Obtener la pose base de la animación
	var current_pose := skeleton.get_bone_pose_rotation(bone_id)
	
	# Crear rotación adicional
	var additional_rotation := Quaternion(Vector3.RIGHT, angle)
	
	# Combinar: primero la animación, luego la rotación adicional
	var final_rotation := current_pose * additional_rotation
	
	# Aplicar
	skeleton.set_bone_pose_rotation(bone_id, final_rotation)

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
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

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
