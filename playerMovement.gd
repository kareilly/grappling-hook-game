extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 60

var stomped = false
var target_velocity = Vector3.ZERO
var target_target_velocity = Vector3.ZERO
var target_velocity_forward = 0
var target_velocity_right = 0
var max_ground_speed: float = 25
var drag: float = 5
var jump_speed = 30
var dash_speed: float = 60
var playerCamera
var mouse_dir = Vector2.ZERO
var walk_accel: float = 400
var ground_drag: float = 150
var dash_velocity = Vector3.ZERO
var look_dir = Vector3.ZERO

var hook_range = 1000
var hooking: bool = false
var ini_hook_dist
var hook_dir
var hook_pull_force: float = 4
var hook_velocity: Vector3

#@onready var hook: RayCast3D = get_node("/root/baseScene/CharacterBody3D/RayCast3D")
@onready var camera: Camera3D = $playerCamera
@onready var hook_point: CSGSphere3D = get_node("/root/baseScene/hookpoint")

func jump_boost_timer():
	await get_tree().create_timer(0.15).timeout
	stomped = false
	
func dash_timer():
	await get_tree().create_timer(0.1).timeout
	
func hook_collision():
	var centre = get_viewport().get_size()/2
	
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + camera.project_ray_normal(centre) * hook_range
	
	var new_ray_collision = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var ray_collision = get_world_3d().direct_space_state.intersect_ray(new_ray_collision)
	
	if not ray_collision.is_empty():
		hooking = true
		hook_point.global_position = ray_collision.position
		ini_hook_dist = hook_point.global_position - global_position
		print(ray_collision.collider.name)
	else:
		print("nope")
		
func hook_force(direction: Vector3, force: float):
	hook_velocity = direction * force * Vector3(1,0.6,1)
		
func _input(event):
	if event.is_action_pressed("hook"): #is_action_pressed("hook"):
		if hooking == false:
			print("hooked")
			hook_collision()
		else:
			hooking = false
			
	if event is InputEventMouseMotion:
		mouse_dir = event.relative
	camera.rotation.y -= mouse_dir.x * 0.01 * 0.5
	camera.rotation.x = clamp(camera.rotation.x - mouse_dir.y * 0.01 * 0.5, -1.5, 1.5)
	
func _physics_process(delta):
	var direction = Vector3.ZERO
	
	direction = Input.get_vector("move_left","move_right","move_forward","move_backward")

	if not hooking:
		hook_point.global_position = Vector3(0,-100,0)
		walk_accel = 400
		speed = 14
		
	if hooking or not is_on_floor():
		walk_accel = 150
		speed = 14
		#$Pivot.basis = Basis.looking_at(direction)
	var _forward: Vector3 = camera.global_transform.basis * Vector3(direction.x, 0, direction.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	
	target_target_velocity = target_velocity.move_toward(walk_dir * speed * direction.length(), walk_accel * delta)
	target_velocity.x = target_target_velocity.x
	target_velocity.z = target_target_velocity.z
	#camera.global_transform.basis * Vector3(direction.x, 0, direction.y)
	look_dir = camera.global_transform.basis.z
	
	if stomped == false:
		jump_speed = 30
	
	if Input.is_action_just_pressed("dash"):
		dash_velocity = dash_speed * -look_dir
		target_velocity += dash_velocity
		
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

		if stomped == false:
			if Input.is_action_just_pressed("stomp"):
				target_velocity.y -= 40
				stomped = true
				
	if is_on_floor():
		var horiz_vel = Vector3(target_velocity.x, 0, target_velocity.z)
		if horiz_vel.length() > max_ground_speed:
			target_velocity = target_velocity.move_toward(Vector3(target_velocity.x/horiz_vel.length(), 0, target_velocity.z/horiz_vel.length()) * max_ground_speed, delta * ground_drag)
			
		if stomped == true:
			jump_speed = 40
			jump_boost_timer()
			
		if Input.is_action_pressed("jump"):
			target_velocity.y = jump_speed
			jump_speed = 30
			

	if hooking == true:
		hook_dir = hook_point.position - position
		hook_force(hook_dir.normalized(),hook_pull_force)
		if hook_dir.length() < 15:
			if hook_dir.length() < 5:
				hooking = false
			hook_pull_force = 3
		else:
			hook_pull_force = 3.5

		if position.y > hook_point.position.y:
			if target_velocity.y < 0:
				hooking = false
		target_velocity += hook_velocity
		#target_velocity = target_velocity.move_toward((hook_point.global_position - global_position) *((hook_point.global_position - global_position).length() - ini_hook_dist.length()), delta * 1000 * )
	
	velocity = target_velocity
	move_and_slide()
	speed = 14
	
