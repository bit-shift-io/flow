#
# https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-38-fast-fluid-dynamics-simulation-gpu
#

extends Spatial

onready var fluid = preload("fluid.gd").new();

var cell_scene = load("res://cell.tscn")
onready var cell_parent = get_node(".")
var map;
var width = 10;
var height = 10;

func create_2d_array(_width, _height, scene):
	var a = []
	width = _width;
	height = _height;

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

func for_each(fn):
	for y in range(height):
		for x in range(width):
			fn.call_func(map[y][x], Vector2(x, y));
	

# Called when the node enters the scene tree for the first time.
func _ready():
	map = create_2d_array(width, height, cell_scene);
	fluid.create(width, height);
	fluid.set_for_each_fn(funcref(self, "for_each"));
	print("map generated");
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fluid.update();

