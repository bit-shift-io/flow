extends Spatial

onready var box = get_node("CSGBox");
onready var geom = get_node("ImmediateGeometry");

var velocity = Vector3(0, 0, 0);

func set_velocity(v):
	if (v == velocity):
		return;
		
	velocity = v;
	geom.clear();
	geom.begin(Mesh.PRIMITIVE_LINES, null);
	geom.add_vertex(Vector3(0,0,0));
	geom.add_vertex(velocity);
	geom.end();

func set_color(col):
	box.material_override.albedo_color = col;
	
# Called when the node enters the scene tree for the first time.
func _ready():
	box.material_override = box.material.duplicate();
	geom.transform.origin = Vector3(0.0, 0.51, 0.0); # raise above box and center
	#set_velocity(Vector3(-0.5, 0, 0)); # test
