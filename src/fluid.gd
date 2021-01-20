extends Node

var fluidFunctions = preload("fluid_functions.gd").new();
var FluidTexture = preload("fluid_texture.gd");

var for_each_fn; # funcref
var width;
var height;

var texture_velocity;
var texture_density;
var texture_divergence;
var texture_pressure;
var texture_vorticity;
var texture_velocity_offsets;
var texture_pressure_offsets;

# Slab operations (eg. render targets shaders are run on)
var boundaries;

func create(_width, _height):
	width = _width;
	height = _height;
	
	texture_velocity = FluidTexture.new().create(width, height);
	texture_density = FluidTexture.new().create(width, height);
	texture_divergence = FluidTexture.new().create(width, height);
	texture_pressure = FluidTexture.new().create(width, height);
	texture_vorticity = FluidTexture.new().create(width, height);
	texture_velocity_offsets = FluidTexture.new().create(width, height);
	texture_pressure_offsets = FluidTexture.new().create(width, height);
	
	boundaries = FluidTexture.new().create(width, height);
	
	
	
func set_for_each_fn(fn):
	for_each_fn = fn;
	
# Declare member variables here. Examples:

# Update solves the incompressible Navier-Stokes equations for a single 
# time step.  It consists of four main steps:
#
# 1. Add Impulse
# 2. Advect
# 3. Apply Vorticity Confinement
# 4. Diffuse (if viscosity > 0)
# 5. Project (computes divergence-free velocity from divergent field).
#
# 1. Advect: pulls the velocity and Ink fields forward along the velocity
#            field.  This results in a divergent field, which must be 
#            corrected in step 4.
# 2. Add Impulse: simply add an impulse to the velocity (and optionally,Ink)
#    field where the user has clicked and dragged the mouse.
# 3. Apply Vorticity Confinement: computes the amount of vorticity in the 
#            flow, and applies a small impulse to account for vorticity lost 
#            to numerical dissipation.
# 4. Diffuse: viscosity causes the diffusion of velocity.  This step solves
#             a poisson problem: (I - nu*dt*Laplacian)u' = u.
# 5. Project: In this step, we correct the divergence of the velocity field
#             as follows.
#        a.  Compute the divergence of the velocity field, div(u)
#        b.  Solve the Poisson equation, Laplacian(p) = div(u), for p using 
#            Jacobi iteration.
#        c.  Now that we have p, compute the divergence free velocity:
#            u = gradient(p)
func update():
	for_each_fn.call_func(funcref(self, "advect"));
	
	#advect();
	add_impulse();
	apply_vorticity_confinement();
	diffuse();
	compute_divergence();
	compute_pressure_disturbance();
	subtract_p_gradient_from_u();
	
	
func advect(cell, coords):
	# Advect velocity (velocity advects itself, resulting in a divergent
	# velocity field.  Later, correct this divergence).
	fluidFunctions.boundary(boundaries, coords, -1, texture_offsets, texture_velocity);
	#
	
	
	
func add_impulse():
	print("add impulse");
	
	
func apply_vorticity_confinement():
	print("fluid_apply_vorticity_confinement");
	
	
func diffuse():
	print("fluid_diffuse");
	
	
func compute_divergence():
	print("compute_divergence");
	
	
func compute_pressure_disturbance():
	print("compute_pressure_disturbance");
	
	
func subtract_p_gradient_from_u():
	print("subtract_p_gradient_from_u");
	

	
	
