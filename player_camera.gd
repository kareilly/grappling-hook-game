extends Camera3D 

@export var sensitivity = 1.0
var mouse_dir = Vector2.ZERO
var camera_rotation = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		mouse_dir = event.relative
	rotate_y(mouse_dir.x * 0.01 * -0.5)
	rotate_object_local(Vector3(1,0,0),mouse_dir.y * 0.01 * -0.5)

	transform = transform.orthonormalized()
	
	get_viewport().warp_mouse(get_viewport().size / 2)
