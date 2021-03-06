extends Node3D

@onready var box: CSGBox3D = get_node("CSGBox");
@onready var geom = get_node("ImmediateGeometry");
@onready var arrow: CSGBox3D = get_node("Arrow");

var pressureAsHeight = true; # show pressure as height
var velocity = Vector3(0, 0, 0);

func set_velocity(v):
	#if (v == velocity):
	#	return;
		
	#velocity = v;
	arrow.set_velocity(v);

	
func set_density(d):
	#var new_d = d; #max(d, 0.2);
	#if (new_d == box.size.y):
	#	return;
		
	#if (new_d <= 0.0):
	#	box.visible = false;
	#	return;

	#box.visible = true;
	
	if (pressureAsHeight):
		# scale y axis
		box.transform.basis.y.y = d * 0.5# .set_axis(1, box.transform.basis.get_axis(1) * new_d * 0.5)
		box.transform.origin = Vector3(0.0, d * 0.25, 0.0); # raise so bottom of box is at zero
	

func set_color(col):
	box.material_override.albedo_color = col;
	
# Called when the node enters the scene tree for the first time.
func _ready():
	box.material_override = box.material.duplicate();
	geom.transform.origin = Vector3(0.0, 0.51, 0.0); # raise above box and center
	#set_velocity(Vector3(-0.5, 0, 0)); # test
