extends Node3D

@onready var player: CharacterBody3D = get_node("/root/baseScene/CharacterBody3D")
@onready var camera: Camera3D = get_node("/root/baseScene/CharacterBody3D/playerCamera")

const boost_max: int = 10
const boost_fill_interval: float = 0.1
const boost_fill_cd: float = 1.0
const drain_interval: float = 0.5
const max_speed: float = 5.0
const boost_force: float = 150.0

var boost_velocity: Vector3
var boost_charge: int
var can_fill: bool
var boosting: bool
# Called when the node enters the scene tree for the first time.
		
func boost():
	boosting = true
	can_fill = false
	boost_drain()
		
func boost_stop():
	boosting = false
	await get_tree().create_timer(boost_fill_cd).timeout
	if boosting == false:
		can_fill = true
		boost_fill()

func boost_drain():
	while boosting:
		boost_charge -= 1
		await get_tree().create_timer(boost_fill_interval).timeout
		
func boost_fill():
	while can_fill == true and boost_charge < 10:
		print("filling")
		boost_charge += 1
		await get_tree().create_timer(boost_fill_interval).timeout
