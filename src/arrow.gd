extends Node3D

@onready var box: CSGBox3D = get_node("CSGBox3D");

func _ready():
	set_velocity(Vector3(0, 0, 0));

func set_velocity(v: Vector3):
	var l = v.length();
	box.size.z = l;
	box.transform.origin.z = -l * 0.5;
	
	transform = transform.looking_at(transform.origin + v, Vector3(0, 1, 0));
