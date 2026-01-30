extends Node

@onready var boost_pickups: Node = get_node("/root/BaseScene/GameObjects/Pickups/BoostPickups")

class boostPickup extends Area3D:
	
	const fill_percent: float = 0.5
	const cooldown: int = 60
	const size: float = 2.5
	
	func _init(parent: Node3D) -> void:
		
		var BPShape: CollisionShape3D = CollisionShape3D.new()
		var BPMesh: MeshInstance3D = MeshInstance3D.new()
		
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = size
		
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = size
		sphere_mesh.height = size * 2
		
		BPShape.shape = sphere_shape
		BPMesh.mesh = sphere_mesh
		
		self.add_child(BPShape)
		self.add_child(BPMesh)
		
	func _process(delta: float) -> void:
		pass
		
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for bp in boost_pickups.get_children():
		print(bp.name)
		bp.add_child(boostPickup.new(bp))
