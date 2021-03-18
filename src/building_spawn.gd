extends Node3D

var needs_rotation_when_building = false


var team: int = 0
var rate: int = 10

var life = 10.0

func _ready():
	set_process(false)

func spawn(xform):
	global_transform = xform
	set_process(true)

func _process(delta):
	var gs = Store.fluid_sim_renderer.world_to_grid_space(global_transform.origin)
	
	if (team == 0):
		Store.fluid_sim.set_prev_density(gs.x, gs.y, delta * rate)
	else:
		Store.fluid_sim.set_prev_density_2(gs.x, gs.y, delta * rate)


	if (Store.buildings_are_temporary):
		life -= delta
		if (life <= 0):
			self.queue_free();
