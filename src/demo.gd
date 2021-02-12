extends Node

@onready var camera = get_node("Camera");
@onready var cursor = get_node("Cursor");

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

func create_arr(width, height):
	var sz = width * height;
	var p : FloatArray = FloatArray.new();
	p.resize(sz);
	p.set_all(0.0);
	return p;
	
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
			
# Start with two grids.
# One that contains the density values from the previous time step and one that
# will contain the new values. For each grid cell of the latter we trace the
# cell's center position backwards through the velocity field. We then linearly
# interpolate from the grid of previous density values and assign this value to
# the current grid cell.

var solver = FluidSolver.new();
var u = create_arr(size, size);
var u_prev = create_arr(size, size);
var v = create_arr(size, size);
var v_prev = create_arr(size, size);
var dens = create_arr(size, size);
var dens_prev = create_arr(size, size);
	
func clear_data():
	"""clear_data."""
	
	u.set_all(0.0);
	u_prev.set_all(0.0);
	v.set_all(0.0);
	v_prev.set_all(0.0);
	dens.set_all(0.0);
	dens_prev.set_all(0.0);

			
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
		clear_data();
		
	if Input.is_action_just_pressed("velocity"):
		dvel = !dvel;
		
		
	
func _ready():
	set_process_input(true);
	base.size.x = float(size) + 1.0;
	base.size.z = float(size) + 1.0;
	cells = create_2d_instance(size, size, cell_scene, cell_parent);
	
	# uniform force field for testing
	u.set_all(uniformForce.y);
	v.set_all(uniformForce.x);



func IX(i,j):
	return ((i)+(N+2)*(j));

func get_from_UI(d: FloatArray, u: FloatArray, v: FloatArray):
	"""get_from_UI."""

	u_prev.set_all(0.0);
	v_prev.set_all(0.0);
	dens_prev.set_all(0.0);

	if not mouse_down[0] and not mouse_down[1]:
		return

	# map mouse pos to grid space
	var i = int(my);
	var j = int(mx);

	if i < 1 or i > N or j < 1 or j > N:
		return

	if mouse_down[0]:
		# clamp here to stop force going to high on low fps
		var fx = force * clamp(mx - omx, -1, 1);
		var fy = force * clamp(my - omy, -1, 1);
		
		if (fx != 0 || fy != 0):
			print("force:" + str(fx) + "," + str(fy) + " @ " + str(i) + "," + str(j));
		
		u_prev.set_value(IX(i,j), fy)
		v_prev.set_value(IX(i,j), fx)
		
	if mouse_down[1]:
		dens_prev.set_value(IX(i,j), source)


func velocity_step(delta):
	solver.velocity_step(N, u, v, u_prev, v_prev, visc, delta * dt)
	
func density_step(delta):
	solver.density_step(N, dens, dens_prev, u, v, diff, delta * dt)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Draw into velocity for easy debugging
	if (drawVel):
		get_from_UI(dens_prev, u, v)
	else:
		get_from_UI(dens_prev, u_prev, v_prev)
		velocity_step(delta)
	
	density_step(delta)
	
	if dvel:
		draw_velocity();

	draw_density();
	
	
func draw_velocity():
	"""draw_velocity."""

	var h = 1.0 / N
	var velocityScale = 10.0;

	for i in range(1, N + 1):
		var x = (i - 0.5) * h
		for j in range(1, N + 1):
			var y = (j - 0.5) * h;
			
			var cell = cells[i][j];
			var v_val = v.get_value(IX(i,j)); 
			var u_val = u.get_value(IX(i,j));
			
			#if (v_val != 0.0):
			#	print("we got v vel:", v_val);
				
			#if (u_val != 0.0):
			#	print("we got u vel:", u_val);
			
			# this should be Vector3(u_val, 0, v_val)... we have something flipped wrong?!
			cell.set_velocity(Vector3(v_val * velocityScale, 0, -u_val * velocityScale));
	
func draw_density():
	"""draw_density."""

	var h = 1.0 / N

	for i in range(1, N + 1):
		var x = (i - 0.5) * h
		for j in range(1, N + 1):
			var y = (j - 0.5) * h
			
			
			var d00 = dens.get_value(IX(i,j));
			#var d01 = dens[i][j + 1]
			#var d10 = dens[i + 1][j]
			#var d11 = dens[i + 1][j + 1]

			#if (d00 > 0.0):
			#	print("we got density:", d00 * colourScale);
				
			var cell = cells[i][j];
			cell.set_density(d00);
			
			#glColor3f(d00, d00, d00)
			#glVertex2f(x, y)
			#glColor3f(d10, d10, d10)
			#glVertex2f(x + h, y)
			#glColor3f(d11, d11, d11)
			#glVertex2f(x + h, y + h)
			#glColor3f(d01, d01, d01)
			#glVertex2f(x, y + h)
