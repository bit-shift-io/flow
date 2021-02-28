extends Node3D

@onready var box: CSGBox3D = get_node("CSGBox3D");

func _ready():
	#set_velocity(Vector3(0, 0, 0));
	return

func set_velocity(v: Vector3):
	var l = v.length();
	if (l <= 0):
		return;
		
	box.size.z = l;
	box.transform.origin.z = -l * 0.5;
	
	
	#var angle = atan2(v.z, v.x)  # *  Mathf.Rad2Deg; transform.rotation = Quaternion.Euler(new Vector3(0, 0, angle));
	
	transform = transform.looking_at(transform.origin + v, Vector3(0, 1, 0));
