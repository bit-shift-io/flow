#
# NOTES:
# the camera looks down with +x being right, and +z being down
# the fluid sim we have 0, 0 in the bottom left of the screen
# which is also the way the cells are mapped out
# 
# note that i denotes x axis, and j denotes y axis
#

extends Node

var cells;

func create_2d_instance(width, height, scene, parent):
	var a = []
	var hw = width / 2;
	var hh = height / 2;
	
	for z in range(height):
		a.append([])
		a[z].resize(width)

		for x in range(width):
			var cell_inst = scene.instance();
			cell_inst.name = '' + str(x) + ',' + str(z);
			
			# convert grid space to world space
			cell_inst.transform.origin = Vector3(x - hw + 0.5, 0, -(z - hh + 0.5));
			
			parent.add_child(cell_inst);
			a[z][x] = cell_inst;

	return a;
			
func init(cell_scene, cell_parent):
	var N = Store.fluid_sim.N
	var size = N + 2
	cells = create_2d_instance(size, size, cell_scene, cell_parent);
	
func world_to_grid_space(pos: Vector3):
	# convert world space to grid space
	var size = Store.fluid_sim.size
	var hs = size / 2
	var mx = (pos.x + hs)
	var my = (-pos.z + hs)
	return Vector2(mx, my)
	
		
func draw_velocity():
	var N = Store.fluid_sim.N
	var h = 1.0 / N
	var velocityScale = 10.0;

	for i in range(1, N + 1):
		for j in range(1, N + 1):			
			var cell = cells[j][i];
			var vel = Store.fluid_sim.get_velocity(i, j)
			var u_val = vel.x
			var v_val = vel.y
			
			cell.set_velocity(Vector3(u_val * velocityScale, 0, -v_val * velocityScale));
	
func draw_density():
	var N = Store.fluid_sim.N
	var h = 1.0 / N
	for i in range(1, N + 1):
		for j in range(1, N + 1):
			var d00 = Store.fluid_sim.get_density(i, j);
			#var d01 = dens[i][j + 1]
			#var d10 = dens[i + 1][j]
			#var d11 = dens[i + 1][j + 1]

			var cell = cells[j][i];
			cell.set_density(d00);
			
			#glColor3f(d00, d00, d00)
			#glVertex2f(x, y)
			#glColor3f(d10, d10, d10)
			#glVertex2f(x + h, y)
			#glColor3f(d11, d11, d11)
			#glVertex2f(x + h, y + h)
			#glColor3f(d01, d01, d01)
			#glVertex2f(x, y + h)
