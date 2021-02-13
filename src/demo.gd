#
# NOTES:
# the camera looks down with +x being right, and +z being down
# the fluid sim we have 0, 0 in the bottom left of the screen
# which is also the way the cells are mapped out
# 
# note that i denotes x axis, and j denotes y axis
#

extends Node

@onready var camera = get_node("Camera");
@onready var cursor = get_node("Cursor");


var fluid_sim = preload("res://fluid_sim.gd").new();

var drawVel = false; # draw the velocty with out the velocty field disapating
var uniformForce = Vector2(0.0, 0.0); # initial uniform force

var N = 15
var size = N + 2

var dt = 2 # rate of simulation
var diff = 0.0
var visc = 0.0
var force = 5.0
var source = 100.0
var dvel = true

var omx = 0.0
var omy = 0.0
var mx = 0.0
var my = 0.0
var mouse_down = [false, false]

var cell_scene = load("res://cell.tscn")

@onready var cell_parent = $"." #get_node(".")

var cells;

@onready var base: CSGBox3D = $"Base" #get_node("Base");
	
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
			
func _input(event):
	if event is InputEventMouseMotion:
		var position2D = get_viewport().get_mouse_position()
		var dropPlane  = Plane(Vector3(0, 1, 0), 0);
		var position3D = dropPlane.intersects_ray(camera.project_ray_origin(position2D),camera.project_ray_normal(position2D))
		#print(position3D)
		if (position3D):
			cursor.transform.origin = position3D;
			
		omx = mx
		omy = my
		
		# convert world space to grid space
		var hs = size / 2;
		mx = (cursor.transform.origin.x + hs);
		my = (-cursor.transform.origin.z + hs); 
		#print("Mouse at: ", str(mx), ",", str(my))
	
	mouse_down[0] = false;
	if Input.is_action_pressed("left_click"):
		mouse_down[0] = true;
		
	mouse_down[1] = false;
	if Input.is_action_pressed("right_click"):
		mouse_down[1] = true;
		
	if Input.is_action_just_pressed("clear"):
		fluid_sim.clear_data();
		
	if Input.is_action_just_pressed("velocity"):
		dvel = !dvel;
		
	
func _ready():
	set_process_input(true);
	base.size.x = float(size) + 1.0;
	base.size.z = float(size) + 1.0;
	cells = create_2d_instance(size, size, cell_scene, cell_parent);
	
	fluid_sim.init(N, N)
	
	# uniform force field for testing
	#u.set_all(uniformForce.y);
	#v.set_all(uniformForce.x);


func get_from_UI():
	fluid_sim.clear_prev_velocity()
	fluid_sim.clear_prev_density()

	if not mouse_down[0] and not mouse_down[1]:
		return

	# map mouse pos to grid space
	var i = int(mx);
	var j = int(my);

	if i < 1 or i > N or j < 1 or j > N:
		return

	if mouse_down[0]:
		# clamp here to stop force going to high on low fps
		var fx = force * clamp(mx - omx, -1, 1);
		var fy = force * clamp(my - omy, -1, 1);
		
		if (fx != 0 || fy != 0):
			print("force:" + str(fx) + "," + str(fy) + " @ " + str(i) + "," + str(j));
		
		fluid_sim.set_prev_velocity(i, j, Vector2(fx, fy))
		
	if mouse_down[1]:
		fluid_sim.set_prev_density(i, j, source)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Draw into velocity for easy debugging
	if (drawVel):
		get_from_UI()
	else:
		get_from_UI()
		fluid_sim.velocity_step(delta)
	
	fluid_sim.density_step(delta)
	
	# TODO: move drawing code to a Fluid_sim_renderer ?
	if dvel:
		draw_velocity();

	draw_density();
	
	
func draw_velocity():
	var h = 1.0 / N
	var velocityScale = 10.0;

	for i in range(1, N + 1):
		for j in range(1, N + 1):			
			var cell = cells[j][i];
			var vel = fluid_sim.get_velocity(i, j)
			var u_val = vel.x
			var v_val = vel.y
			
			cell.set_velocity(Vector3(u_val * velocityScale, 0, -v_val * velocityScale));
	
func draw_density():
	var h = 1.0 / N
	for i in range(1, N + 1):
		for j in range(1, N + 1):
			var d00 = fluid_sim.get_density(i, j);
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
