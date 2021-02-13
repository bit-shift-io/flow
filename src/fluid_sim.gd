extends Node

var solver = FluidSolver.new();
var u: FloatArray
var u_prev: FloatArray
var v: FloatArray
var v_prev: FloatArray
var dens: FloatArray
var dens_prev: FloatArray


var N = 15
var size = N + 2

var dt = 2 # rate of simulation
var diff = 0.0
var visc = 0.0
var force = 5.0
	

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
	
func get_velocity(x: int, y: int):
	var v_val = v.get_value(IX(x,y)) 
	var u_val = u.get_value(IX(x,y))
	return Vector2(u_val, v_val)
	
func get_density(x: int, y: int):
	return dens.get_value(IX(x,y));
	
func clear_prev_density():
	dens_prev.set_all(0.0);

func create_arr(width, height):
	var sz = width * height;
	var p : FloatArray = FloatArray.new();
	p.resize(sz);
	p.set_all(0.0);
	return p;
	
func velocity_step(delta):
	solver.velocity_step(N, u, v, u_prev, v_prev, visc, delta * dt)
	
func density_step(delta):
	solver.density_step(N, dens, dens_prev, u, v, diff, delta * dt)
	
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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
