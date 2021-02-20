#
# NOTES:
# the camera looks down with +x being right, and +z being down
# the fluid sim we have 0, 0 in the bottom left of the screen
# which is also the way the cells are mapped out
# 
# note that i denotes x axis, and j denotes y axis
#

extends Node

var drawVel = false; # draw the velocty with out the velocty field disapating
var uniformForce = Vector2(0.0, 0.0); # initial uniform force
var cell_scene = load("res://cell.tscn")
@onready var base: CSGBox3D = $"Base" #get_node("Base");
			
var collision_rate = 10

func _ready():
	Store.game = self
	Store.map = self
	
	var N = 15
	var size = N + 2
	base.size.x = float(size) + 1.0;
	base.size.z = float(size) + 1.0;

	Store.fluid_sim = load("res://fluid_sim.gd").new();
	Store.fluid_sim.init(N, N)
	
	Store.fluid_sim_renderer = load("res://fluid_sim_renderer.gd").new();
	Store.fluid_sim_renderer.init(cell_scene, Store.map);
	
	var player = load("res://player.tscn").instance();
	Store.players.append(player)
	add_child(player)
	
	# uniform force field for testing
	#u.set_all(uniformForce.y);
	#v.set_all(uniformForce.x);



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for p in Store.players:
		p.process(delta)
		
	Store.fluid_sim.velocity_step(delta)
	
	# move each team density through the velocity field
	Store.fluid_sim.density_step(delta)
	Store.fluid_sim.density_step_2(delta)
	
	# resolve collision of colours
	resolve_collisions(delta)
	
	# draw density
	var dvel = Store.players[0].dvel
	if dvel:
		Store.fluid_sim_renderer.draw_velocity();

	Store.fluid_sim_renderer.draw_density();
	
	# clear density and velocity ready for next frame
	Store.fluid_sim.clear_prev_velocity()
	Store.fluid_sim.clear_prev_density()
	Store.fluid_sim.clear_prev_density_2()
	
# TODO: move to C++?
func resolve_collisions(delta):
	var N = Store.fluid_sim.N
	for x in range(1, N + 1):
		for y in range(1, N + 1):
			var d1 = Store.fluid_sim.get_density(x, y);
			var d2 = Store.fluid_sim.get_density_2(x, y);
			
			# no collision occured
			if (d1 <= 0 || d2 <= 0):
				continue
				
			# what equation are we going to use?
			#greater_then(x, y, d1, d2, delta)
			erode(x, y, d1, d2, delta)
			
# greater wins
# notes: might need a rate of conversion to allow
# players to try to push density and colour into each other
func greater_then(x, y, d1, d2, delta):
	#var diff = d2 - d1
	#diff = diff * delta * collision_rate
	
	if (d1 > d2): # diff > 0
		Store.fluid_sim.dens.set_value(Store.fluid_sim.IX(x,y), d1 + d2)
		Store.fluid_sim.dens_2.set_value(Store.fluid_sim.IX(x,y), 0)
	
	if (d2 > d1): # diff < 0
		Store.fluid_sim.dens.set_value(Store.fluid_sim.IX(x,y), 0)
		Store.fluid_sim.dens_2.set_value(Store.fluid_sim.IX(x,y), d1 + d2)
		
# erode/disolve each other equally
# notes: should this happen over time?
func erode(x, y, d1, d2, delta):
	var diff = d2 - d1
	diff = diff * delta * collision_rate
	
	if (d2 > d1): # d2 > d1
		Store.fluid_sim.dens.set_value(Store.fluid_sim.IX(x,y), d1 - diff)
		Store.fluid_sim.dens_2.set_value(Store.fluid_sim.IX(x,y), d2 + diff)
	
	if (d1 > d2): # d1 > d2
		Store.fluid_sim.dens.set_value(Store.fluid_sim.IX(x,y), d1 - diff)
		Store.fluid_sim.dens_2.set_value(Store.fluid_sim.IX(x,y), d2 + diff)
			
				
