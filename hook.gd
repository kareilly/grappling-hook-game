extends Camera3D

var hook_range = 1000

@export var hooking: bool = false

@onready var camera: Camera3D = get_node("/root/baseScene/CharacterBody3D/playerCamera")
@onready var hook: RayCast3D = get_node("/root/baseScene/CharacterBody3D/RayCast3D")
@onready var hook_point: CSGSphere3D = get_node("/root/baseScene/hookpoint")

func _Input(event):
	if event.is_action_pressed("hook"): #is_action_pressed("hook"):
		hook_collision()

func hook_collision():
	var centre = get_viewport().get_size()/2
	
	var ray_origin = camera.project_ray_origin(centre)
	var ray_end = ray_origin + project_ray_normal(centre) * hook_range
	
	var new_ray_collision = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var ray_collision = get_world_3d().direct_space_state.intersect_ray(new_ray_collision)
	
	if not ray_collision.is_empty():
		print(ray_collision.collider.name)
	else:
		print("nope")
		
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _physics_process(_delta):
	
	if Input.is_action_pressed("hook"):
		hooking = true
		
	else:
		hooking = false

	if hooking == true:
		if hook.is_colliding():
			var origin = camera.global_position
			var collision_point = hook.get_collision_point()
			var distance = origin.distance_to(collision_point)
			hook_point.position = origin

		else:
			hooking = false

		
	
