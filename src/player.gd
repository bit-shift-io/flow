extends Node

@onready var cursor = get_node("Cursor");


var omx = 0.0
var omy = 0.0
var mx = 0.0
var my = 0.0
var mouse_down = [false, false]
var force = 5.0
var source = 100.0
var dvel = true

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true);


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

	
func _input(event):
	if event is InputEventMouseMotion:
		var camera = get_viewport().get_camera()
		var position2D = get_viewport().get_mouse_position()
		var dropPlane  = Plane(Vector3(0, 1, 0), 0);
		var position3D = dropPlane.intersects_ray(camera.project_ray_origin(position2D),camera.project_ray_normal(position2D))
		#print(position3D)
		if (position3D):
			cursor.transform.origin = position3D;
			
		omx = mx
		omy = my
		
		# convert world space to grid space
		var size = Store.fluid_sim.size
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
		Store.fluid_sim.clear_data();
		
	if Input.is_action_just_pressed("velocity"):
		dvel = !dvel;
		

func get_from_UI():
	Store.fluid_sim.clear_prev_velocity()
	Store.fluid_sim.clear_prev_density()

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
		
		Store.fluid_sim.set_prev_velocity(i, j, Vector2(fx, fy))
		
	if mouse_down[1]:
		Store.fluid_sim.set_prev_density(i, j, source)
	
