extends Node3D

var needs_rotation_when_building = true
var force = 5
var life = 10.0

@onready var box: CSGBox3D = $CSGBox3D2;

func _ready():
	set_process(false)

func spawn(xform):
	global_transform = xform
	set_process(true)

func _process(delta):
	var gs = Store.fluid_sim_renderer.world_to_grid_space(global_transform.origin)
	var vel = global_transform.basis.z
	# TODO: needs work!
	if (Store.fluid_sim.using_fab_solver):
		Store.fluid_sim.set_prev_velocity(gs, Vector2(-vel.x, vel.z) * force * delta)
	else:
		Store.fluid_sim.set_velocity(gs, Vector2(-vel.x, vel.z) * force * delta)
	
	if (Store.buildings_are_temporary):
		life -= delta
		if (life <= 0):
			self.queue_free();
