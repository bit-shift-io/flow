#
# Game globals
#

extends Node

var players = []
var fluid_sim
var fluid_sim_renderer
var buildings = []
var game
var map # map root node

# experimenting with temporary buildings to make things feel more "fluid"
var buildings_are_temporary = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
