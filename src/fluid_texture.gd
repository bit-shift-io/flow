#
# Emulate a texture - a 2d array basically
#

extends Node

var data;
var width;
var height;

func create(_width, _height):
	data = []
	width = _width;
	height = _height;

	for y in range(height):
		data.append([])
		data[y].resize(width)

		for x in range(width):
			data[y][x] = Vector3(0, 0, 0);

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
