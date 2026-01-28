extends CSGBox3D

var start: Vector3
var end: Vector3

@export var hooking: bool = false

@onready var player: CharacterBody3D = get_node("/root/baseScene/CharacterBody3D")
@onready var camera: Camera3D = get_node("/root/baseScene/CharacterBody3D/playerCamera")
@onready var hook_point: CSGSphere3D = get_node("/root/baseScene/hookpoint")
@onready var hook_line: CSGBox3D = get_node("/root/baseScene/hookline")

func _ready():
	hook_line.visible = false
	
func _physics_process(_delta):
	start = Vector3(player.global_position.x, player.global_position.y, player.global_position.z - 0.5)
	end = hook_point.global_position
	hook_line.global_position = start + (end - start)/2
	if player.hooking == true:
		hook_line.look_at(end)
		hook_line.scale.z = (end - start).length() * 5
		hook_line.visible = true
	else:
		hook_line.visible = false
		

		
	
