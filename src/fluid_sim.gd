extends Node

# set this to false and you will get the old solver
# set it to true and we get the experimental fabian solver
var using_fab_solver = true;

var solver = FluidSolverFab.new() if using_fab_solver else FluidSolver.new();
var u: FloatArray
var u_prev: FloatArray
var v: FloatArray
var v_prev: FloatArray


var dens: FloatArray
var dens_prev: FloatArray

var dens_2: FloatArray
var dens_prev_2: FloatArray

var N = 15
var size = N + 2

var dt = 2 # rate of simulation
var diff = 0.0
var visc = 0.0
var force = 5.0
	
var density_viscosity = 0.01 # how fast the density causes changes in velocity field

# i = x, j = y
func IX(i,j):
	return ((i)+(N+2)*(j));
	
func clear_data():
	u.set_all(0.0);
	u_prev.set_all(0.0);
	v.set_all(0.0);
	v_prev.set_all(0.0);
	dens.set_all(0.0);
	dens_prev.set_all(0.0);
	dens_2.set_all(0.0);
	dens_prev_2.set_all(0.0);
	
func clear_prev_velocity():
	u_prev.set_all(0.0);
	v_prev.set_all(0.0);
	
func set_velocity(xy: Vector2, vel: Vector2):
	var x = int(xy.x)
	var y = int(xy.y)
	u.set_value(IX(x,y), vel.x)
	v.set_value(IX(x,y), vel.y)
	
func set_prev_velocity(xy: Vector2, vel: Vector2):
	var x = int(xy.x)
	var y = int(xy.y)
	u_prev.set_value(IX(x,y), vel.x)
	v_prev.set_value(IX(x,y), vel.y)
	
#func set_prev_velocity(x: int, y: int, v: Vector2):
#	u_prev.set_value(IX(x,y), v.x)
#	v_prev.set_value(IX(x,y), v.y)
	
func set_prev_density(x: int, y: int, v: float):
	dens_prev.set_value(IX(x,y), v)
	
func set_prev_density_2(x: int, y: int, v: float):
	dens_prev_2.set_value(IX(x,y), v)
	
func get_velocity(x: int, y: int):
	var v_val = v.get_value(IX(x,y)) 
	var u_val = u.get_value(IX(x,y))
	return Vector2(u_val, v_val)
	
func get_density(x: int, y: int):
	return dens.get_value(IX(x,y));
	
func get_density_2(x: int, y: int):
	return dens_2.get_value(IX(x,y));
	
func clear_prev_density():
	dens_prev.set_all(0.0);
	
func clear_prev_density_2():
	dens_prev_2.set_all(0.0);

func create_arr(width, height):
	var sz = width * height;
	var p : FloatArray = FloatArray.new();
	p.resize(sz);
	p.set_all(0.0);
	return p;
	
	
func apply_density_to_velocity_step(delta):
	apply_density_to_velocity_step_internal(dens, delta)
	apply_density_to_velocity_step_internal(dens_2, delta)
	
	
func apply_density_to_velocity_step_internal(density, delta):
	# density wants to move from high pressure (Density) to low
	# so update the velocity field based on the density fields
	for y in range(1, N):
		for x in range(1, N):
			
			# get density of current cell and the cell
			# in each direction
			var d = density.get_value(IX(x,y));
			var d_up = density.get_value(IX(x,y - 1));
			var d_down = density.get_value(IX(x,y + 1));
			var d_left = density.get_value(IX(x - 1,y));
			var d_right = density.get_value(IX(x + 1,y));
			
			#if (d!=0):
			#	print_debug("yo");
				
			# compute a delta between each cell density
			var dd_left = d_left - d;
			var dd_right = d - d_right;
			
			var dd_up = d_up - d;
			var dd_down = d - d_down;
			
			# merge the directional deltas into a single force/direction
			var du = dd_left + dd_right;
			var dv = dd_up + dd_down;
			
			# add to the existing force field
			# we should add an "add_value" function
			var existing_u = u.get_value(IX(x,y))
			var existing_v = v.get_value(IX(x,y))
			
			var new_u = existing_u + (du * density_viscosity * delta * dt);
			var new_v = existing_v + (dv * density_viscosity * delta * dt);
			
			u.set_value(IX(x,y), new_u)
			v.set_value(IX(x,y), new_v)
			pass;
			
	return;
	
func velocity_step(delta):
	solver.velocity_step(N, u, v, u_prev, v_prev, visc, delta * dt)
	
func density_step(delta):
	solver.density_step(N, dens, dens_prev, u, v, diff, delta * dt)
	
func density_step_2(delta):
	solver.density_step(N, dens_2, dens_prev_2, u, v, diff, delta * dt)
	
func init(width, height):
	# only support square for now
	height = width
	N = width
	size = N + 2
	
	u = create_arr(size, size);
	u_prev = create_arr(size, size);
	v = create_arr(size, size);
	v_prev = create_arr(size, size);
	dens = create_arr(size, size);
	dens_prev = create_arr(size, size);
	dens_2 = create_arr(size, size);
	dens_prev_2 = create_arr(size, size);

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
