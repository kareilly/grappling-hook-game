extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 75

var target_velocity = Vector3.ZERO
var walk_velocity = Vector3.ZERO
var target_velocity_forward = 0
var target_velocity_right = 0

var max_ground_speed: float = 25
var air_drag: float = 500
var ground_drag: float = 150
var jump_speed = 30
var walk_accel: float = 300

var playerCamera
var mouse_dir = Vector2.ZERO

var forward = Vector3.ZERO
var look_dir = Vector3.ZERO
var walk_dir = Vector3.ZERO
var input_direction = Vector3.ZERO

var hook_range = 60
var hooking: bool = false
var ini_hook_dist
var hook_dir
var hook_pull_force: float = 240.0
var hook_velocity: Vector3
var max_hook_velocity: float = 5
var hook_lift: float
var hook_max_speed: float
var terminal_velocity: float = -70
#@onready var hook: RayCast3D = get_node("/root/baseScene/CharacterBody3D/RayCast3D")
const boosters = preload("res://boosters.gd")
var booster = boosters.new()

@onready var spawn_point: Node3D = get_node("/root/BaseScene/GameObjects/SpawnPoint")
@onready var camera: Camera3D = $PlayerCamera
@onready var hook_point: CSGSphere3D = get_node("/root/BaseScene/Hookpoint")

func _ready():
	# Initialize player
	add_child(booster)
	set_slide_on_ceiling_enabled(false)
	self.global_position = spawn_point.global_position
	target_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	hooking = false
	
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initialize booster variables
	booster.velocity = Vector3.ZERO
	booster.charge = 10
	booster.can_fill = true
	booster.boosting = false
	
# Cast a new ray from a to b and get collision values
func cast_ray(ray_origin: Vector3, ray_target: Vector3):
	# Make ray physics query
	var new_ray_collision = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
	# Return results
	return get_world_3d().direct_space_state.intersect_ray(new_ray_collision)
	
# Make a hook point with a raycast coming from the center of the camera
func cast_hook():
	var camera_centre = get_viewport().get_size()/2
	var start = camera.project_ray_origin(camera_centre)
	var ray = cast_ray(start, start + camera.project_ray_normal(camera_centre) * hook_range)
	
	if not ray.is_empty():
		hooking = true
		hook_point.global_position = ray.position
		ini_hook_dist = hook_point.global_position - global_position
		print(ray.collider.name)
	else:
		print("nope")

# ONLY call when hooking active
func check_hook_line():
	var ray = cast_ray(camera.global_position, (hook_point.global_position - camera.global_position).normalized() * ((hook_point.global_position - camera.global_position).length()))
	if not ray.is_empty():
		hooking = false
	
# Calculates hook force, edit hook scalar to change axis weights
func get_hook_velocity(direction: Vector3, force: float, delta: float):
	var hook_scalar = Vector3(1,1,1)
	# Modify to include centrifugal force
	hook_velocity = direction * force * hook_scalar * delta
	if hook_velocity.length() > max_hook_velocity:
		hook_velocity = hook_velocity.normalized() * max_hook_velocity
		
func walk():
	forward = camera.global_basis * Vector3(input_direction.x, 0, input_direction.y)
	walk_dir = Vector3(forward.x, 0, forward.z).normalized()
	if hooking:
		walk_dir -= (walk_dir.cross((hook_point.global_position - global_position).normalized()))/2
		walk_dir *= 3
	if not hooking:
		hook_point.global_position = Vector3(0,-100,0)
	
	if not is_on_floor():
		walk_accel = 50
	else:
		walk_accel = 300
	
# Player input events
func _input(event):
	# Restart the player's transform in the current level
	if event.is_action_pressed("restart"):
		_ready()
		
	# Hook input pressed
	if event.is_action_pressed("hook"):
		if hooking == false:
			print("hooking")
			cast_hook()
		else:
			hooking = false
			# Hook cooldown logic goes here
			
	# Is there any delay due to calling this before moving the camera?
	# Start boosting		
	if event.is_action_pressed("boost"):
		booster.boost()
		
	# Stop boosting
	if event.is_action_released("boost"):
		booster.boost_stop()
	
	# Move camera
	if event is InputEventMouseMotion:
		mouse_dir = event.relative
	camera.rotation.y -= mouse_dir.x * 0.01 * 0.5
	camera.rotation.x = clamp(camera.rotation.x - mouse_dir.y * 0.01 * 0.5, -1.5, 1.5)
	
	# This is old/outdated
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
	
	# Get movement inputs
	input_direction = Input.get_vector("move_left","move_right","move_forward","move_backward")
	
	# Get mouse position
	look_dir = camera.global_basis.z
	
	# Get walk velocity
	walk()
	walk_velocity = target_velocity
	walk_velocity.move_toward(walk_dir * speed * input_direction.length(), walk_accel * _delta)
	target_velocity.x = walk_velocity.x
	target_velocity.z = walk_velocity.z

	# Could refactor
	if not is_on_floor() and target_velocity.y > terminal_velocity:
		target_velocity.y = target_velocity.y - (fall_acceleration * _delta)
	
	if is_on_floor():
		target_velocity.y = 0	#avoids conservation of downwards momentum after falling onto a floor
		var horiz_vel = Vector3(target_velocity.x, 0, target_velocity.z)
		if horiz_vel.length() > max_ground_speed:
			target_velocity = target_velocity.move_toward(Vector3(target_velocity.x/horiz_vel.length(), target_velocity.y, target_velocity.z/horiz_vel.length()) * max_ground_speed, _delta * ground_drag)
			
		# Jumping while on ground
		if Input.is_action_pressed("jump"):
			target_velocity.y = jump_speed
			
	# Get hook force while hooked
	if hooking == true:
		hook_dir = hook_point.position - position
		
		# Length bounds
		if hook_dir.length() > hook_range + 10 or hook_dir.length() < 7.5/clampf((hook_dir.normalized()).dot((self.velocity).normalized()), 0.667,0.75):
			hooking = false
		print((hook_dir.normalized()).dot((self.velocity).normalized()))				
		# Break hook on broken los
		#check_hook_line()
				
		get_hook_velocity(hook_dir.normalized(),hook_pull_force,_delta)
		target_velocity += hook_velocity
		#target_velocity = target_velocity.move_toward((hook_point.global_position - global_position) *((hook_point.global_position - global_position).length() - ini_hook_dist.length()), _delta * 1000 * )
	
	# Get booster force
	if booster.boosting and booster.charge >= 0:
		print(booster.charge)
		booster.use_boost = true
		# Prioritize jump input for going straight up
		if Input.is_action_pressed("jump"):
			target_velocity += booster.force * Vector3(0,1,0) * _delta
			
		# Check for left/right movement input second
		elif input_direction.x != 0:
			target_velocity += booster.force * (camera.global_basis * Vector3(input_direction.x, 0, 0)) * _delta
			
		# Otherwise just use camera direction
		else:
			booster.use_boost = false
			#target_velocity += (booster.force) * -hook_dir.normalized() * _delta
			#target_velocity += booster.force * -camera.global_transform.basis.z.normalized() * _delta
		
	# Update player velocity
	velocity = target_velocity
	move_and_slide()
	
	# End of tick setters
	target_velocity -= booster.velocity
	speed = 14
	
