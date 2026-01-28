extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 75

var stomped = false
var target_velocity = Vector3.ZERO
var walk_velocity = Vector3.ZERO
var target_velocity_forward = 0
var target_velocity_right = 0
var max_ground_speed: float = 25
var drag: float = 1000
var jump_speed = 30
var playerCamera
var mouse_dir = Vector2.ZERO
var walk_accel: float = 300
var ground_drag: float = 150
var look_dir = Vector3.ZERO

var hook_range = 1000
var hooking: bool = false
var ini_hook_dist
var hook_dir
var hook_pull_force: float = 4
var hook_velocity: Vector3
var hook_lift: float
var hook_max_speed: float
var terminal_velocity: float = -70
#@onready var hook: RayCast3D = get_node("/root/baseScene/CharacterBody3D/RayCast3D")
const boosters = preload("res://boosters.gd")
var booster = boosters.new()

@onready var spawn_point: Node3D = get_node("/root/baseScene/gameObjects/spawnPoint")
@onready var camera: Camera3D = $playerCamera
@onready var hook_point: CSGSphere3D = get_node("/root/baseScene/hookpoint")

func _ready():
	add_child(booster)
	set_slide_on_ceiling_enabled(false)
	self.global_position = spawn_point.global_position
	target_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	hooking = false
	stomped = false
	
	#boosters
	booster.boost_velocity = Vector3.ZERO
	booster.boost_charge = 10
	booster.can_fill = true
	booster.boosting = false

func jump_boost_timer():
	await get_tree().create_timer(0.15).timeout
	stomped = false
	
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
	var hook_scalar = Vector3(1,1,1)
	hook_velocity = direction * force * hook_scalar
		
func _input(event):
	if event.is_action_pressed("restart"):
		_ready()
		
	if event.is_action_pressed("hook"): #is_action_pressed("hook"):
		if hooking == false:
			print("hooked")
			hook_collision()
		else:
			hooking = false
			
	if event.is_action_pressed("boost"):
		"boosting"
		booster.boost()
	if event.is_action_released("boost"):
		"stopped boosting"
		booster.boost_stop()
		
	if event is InputEventMouseMotion:
		mouse_dir = event.relative
	camera.rotation.y -= mouse_dir.x * 0.01 * 0.5
	camera.rotation.x = clamp(camera.rotation.x - mouse_dir.y * 0.01 * 0.5, -1.5, 1.5)
	
#	player movement physics process (order is essential):
#		1. get directional input vector: direction (wasd)
#		2. is the player using a hook?
#			y) set hook point outside of map, set walk accel and speed accordingly
#			n) lower walk accel
#		3. set target of the target velocity based on movement input
#		4. get vector of the camera's direction: look_dir
#		5. check if the player stomped last pass: if false, reset jump_speed to 30
#		6. if dash is pressed: get dash velocity and add to target velocity (in dir of camera)
#		7. is the player on the floor?
#			n) apply gravity/fall acceleration
#			y) perform the following:
#				I) set horiz_vel to target velocity (on x & z) 
#					- if above max ground speed, move_toward() max ground speed
#				II) if the player stomped last pass, raise jump vel and set jump_boost_timer()
#				III) if jump input is pressed, add jump speed to target velocity
#		8. if the player is using a hook, do hook velocity calculations
#		9. set velocity to target_velocity, run move_and_slide()

func _physics_process(_delta) -> void:
	var direction = Vector3.ZERO	#direction of player movement
	direction = Input.get_vector("move_left","move_right","move_forward","move_backward")
	look_dir = camera.global_basis.z

	var forward: Vector3 = camera.global_basis * Vector3(direction.x, 0, direction.y)
	var walk_dir: Vector3 = Vector3(forward.x, 0, forward.z).normalized()
	
	if hooking:
		walk_dir -= (walk_dir.cross((hook_point.global_position - global_position).normalized()))/2
		walk_dir *= 3
	if not hooking:
		hook_point.global_position = Vector3(0,-100,0)
	
	if not is_on_floor():
		walk_accel = 50
	else:
		walk_accel = 300
	#print("vi = ", walk_velocity)

	walk_velocity = target_velocity.move_toward(walk_dir * speed * direction.length(), walk_accel * _delta)
	#print("vf = ", walk_velocity)
	target_velocity.x = walk_velocity.x
	target_velocity.z = walk_velocity.z
	
	if stomped == false:
		jump_speed = 30
		
	if not is_on_floor() and target_velocity.y > terminal_velocity:
		target_velocity.y = target_velocity.y - (fall_acceleration * _delta)
		
		if stomped == false:
			if Input.is_action_just_pressed("stomp"):
				target_velocity.y -= 40
				stomped = true
				
	if is_on_floor():
		target_velocity.y = 0	#avoids conservation of downwards momentum after falling onto a floor
		var horiz_vel = Vector3(target_velocity.x, 0, target_velocity.z)
		if horiz_vel.length() > max_ground_speed:
			target_velocity = target_velocity.move_toward(Vector3(target_velocity.x/horiz_vel.length(), target_velocity.y, target_velocity.z/horiz_vel.length()) * max_ground_speed, _delta * ground_drag)
			
		if stomped == true:
			jump_speed = 50
			jump_boost_timer()
			
		if Input.is_action_pressed("jump"):
			target_velocity.y = jump_speed
			jump_speed = 30
			

	if hooking == true:
		hook_dir = hook_point.position - position
		hook_force(hook_dir.normalized(),hook_pull_force)
		if not hook_dir.length() < 60 or hook_dir.length() < 5:
				hooking = false
	
		target_velocity += hook_velocity
		print(hook_velocity)
		print(hook_velocity.length())
		#target_velocity = target_velocity.move_toward((hook_point.global_position - global_position) *((hook_point.global_position - global_position).length() - ini_hook_dist.length()), _delta * 1000 * )
	
	if booster.boosting and booster.boost_charge >= 0:
		print(booster.boost_charge)
		target_velocity += booster.boost_force * -camera.global_transform.basis.z.normalized() * _delta
		
	velocity = target_velocity
	
	move_and_slide()
	
	target_velocity -= booster.boost_velocity
	speed = 14
	
