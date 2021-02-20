extends Node

var player
var name = "player_default_state"

var omx = 0.0
var omy = 0.0
var mx = 0.0
var my = 0.0
var mouse_down = [false, false]
var force = 5.0
var source = 100.0
var dvel = true
var density_dst = 0

func enter():
	pass

func exit():
	pass

	
func input(event):
	if event is InputEventMouseMotion:
		player.update_cursor_transform()
			
		omx = mx
		omy = my
		
		var gs = Store.fluid_sim_renderer.world_to_grid_space(player.cursor.transform.origin)
		mx = gs.x
		my = gs.y
		
	mouse_down[0] = false;
	if Input.is_action_pressed("left_click"):
		mouse_down[0] = true;
		
	mouse_down[1] = false;
	if Input.is_action_pressed("right_click"):
		mouse_down[1] = true;
		
	if Input.is_action_just_pressed("clear"):
		Store.fluid_sim.clear_data();
		
	if Input.is_action_just_pressed("velocity"):
		dvel = !dvel;
		
	if Input.is_action_just_pressed("toggle_density"):
		density_dst = (density_dst + 1) % 2
		
	pass
		

func process(delta):
	#Store.fluid_sim.clear_prev_velocity()
	#Store.fluid_sim.clear_prev_density()
	#Store.fluid_sim.clear_prev_density_2()

	if not mouse_down[0] and not mouse_down[1]:
		return

	# map mouse pos to grid space
	var i = int(mx);
	var j = int(my);

	var N = Store.fluid_sim.N
	if i < 1 or i > N or j < 1 or j > N:
		return

	if mouse_down[0]:
		# clamp here to stop force going to high on low fps
		var fx = force * clamp(mx - omx, -1, 1);
		var fy = force * clamp(my - omy, -1, 1);
		
		if (fx != 0 || fy != 0):
			print("force:" + str(fx) + "," + str(fy) + " @ " + str(i) + "," + str(j));
		
		Store.fluid_sim.set_prev_velocity(Vector2(i, j), Vector2(fx, fy))
		
	if mouse_down[1]:
		if (density_dst == 0):
			Store.fluid_sim.set_prev_density(i, j, source)
		else:
			Store.fluid_sim.set_prev_density_2(i, j, source)
