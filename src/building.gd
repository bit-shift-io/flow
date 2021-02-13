extends Node3D


var force = 1

@onready var box: CSGBox3D = $CSGBox3D2;


func _ready():
	set_process(false)

func spawn(xform):
	global_transform = xform
	set_process(true)

func _process(delta):
	var gs = Store.map_node.world_to_grid_space(global_transform.origin)
	var vel = global_transform.basis.z
	# TODO: needs work!
	Store.fluid_sim.set_velocity(gs, Vector2(vel.x, vel.z) * force)
	pass
