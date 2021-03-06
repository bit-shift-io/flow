extends Node3D

var needs_rotation_when_building = true

@export 
var team: int = 0

@export 
var rate: int = 20

func _ready():
	# hack because export isnt working in gdscript yet!
	if (String(name).ends_with("0")):
		team = 0;
	else:
		team = 1
	pass # Replace with function body.

func _process(delta):
	if (!Store.fluid_sim_renderer):
		return;
		
	if (!is_visible_in_tree()):
		return;
		
	var gs = Store.fluid_sim_renderer.world_to_grid_space(global_transform.origin)
	
	if (team == 0):
		Store.fluid_sim.set_prev_density(gs.x, gs.y, delta * rate)
	else:
		Store.fluid_sim.set_prev_density_2(gs.x, gs.y, delta * rate)
