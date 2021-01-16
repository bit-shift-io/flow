extends Spatial

var cell_scene = load("res://cell.tscn")
onready var cell_parent = get_node(".")
var map;

func create_2d_array(width, height, scene):
	var a = []

	for y in range(height):
		a.append([])
		a[y].resize(width)

		for x in range(width):
			var cell_inst = scene.instance();
			cell_inst.name = '' + str(x) + ',' + str(y);
			cell_inst.transform.origin = Vector3(x, 0, y);
			cell_parent.add_child(cell_inst);
			a[y][x] = cell_inst;

	return a


# Called when the node enters the scene tree for the first time.
func _ready():
	map = create_2d_array(10, 10, cell_scene);
	print("map generated");
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
