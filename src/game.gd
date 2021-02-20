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
	Store.fluid_sim.density_step(delta)
	Store.fluid_sim.density_step_2(delta)
	
	var dvel = Store.players[0].dvel
	if dvel:
		Store.fluid_sim_renderer.draw_velocity();

	Store.fluid_sim_renderer.draw_density();
	
