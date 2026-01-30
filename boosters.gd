extends Node3D

@onready var player: CharacterBody3D = get_node("/root/BaseScene/Player")
@onready var camera: Camera3D = get_node("/root/BaseScene/Player/PlayerCamera")

const max_charge: int = 10
const fill_interval: float = 0.1
const fill_cd: float = 1.0
const drain_interval: float = 0.5
const max_speed: float = 5.0
const force: float = 150.0

var velocity: Vector3
var charge: int
var can_fill: bool
var boosting: bool
# Called when the node enters the scene tree for the first time.
		
func boost():
	boosting = true
	can_fill = false
	boost_drain()
		
func boost_stop():
	boosting = false
	await get_tree().create_timer(fill_cd).timeout
	if boosting == false:
		can_fill = true
		boost_fill()

func boost_drain():
	while boosting:
		charge -= 1
		await get_tree().create_timer(fill_interval).timeout
		
func boost_fill():
	while can_fill == true and charge < max_charge:
		print("filling")
		charge += 1
		await get_tree().create_timer(fill_interval).timeout
