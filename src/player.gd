extends Node

@onready var turbine_building_template = load("res://building_turbine.tscn")

# something wrong with the spawn causing the map to go white! TODO:
@onready var spawn_building_template = load("res://building_spawn.tscn")

@onready var cursor = $Cursor
@onready var hud = $HUD

var omx = 0.0
var omy = 0.0
var mx = 0.0
var my = 0.0
var mouse_down = [false, false]
var force = 5.0
var source = 100.0
var dvel = true

var use_3d_hud = false; # bbuggy atm due to gdscript bugs

var density_dst = 0

@onready var states = [
	load("res://player_default_state.gd").new(),
	load("res://player_build_state.gd").new()
]
var current_state
var prev_state

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true);
	
	#spawn_building_template = load("res://building_spawn.tscn")
	
	hud.fan_button.connect("pressed", Callable(self, "on_turbine_pressed"))
	hud.spawn_button.connect("pressed", Callable(self, "on_spawn_pressed"))
	if (use_3d_hud):
		hud.set_visible(false);

	for s in states:
		s.player = self
		
	if (states.size() > 0):
		set_state(states[0])

func set_state(s):
	prev_state = current_state
	current_state = s
	if (prev_state):
		prev_state.exit()
		
	current_state.enter()
	
func find_state(n):
	for s in states:
		if (s.name == n):
			return s

func process(delta):
	if (current_state):
		current_state.process(delta)
	
func update_cursor_transform():
	var camera = get_viewport().get_camera()
	var position2D = get_viewport().get_mouse_position()
	var dropPlane  = Plane(Vector3(0, 1, 0), 0);
	var position3D = dropPlane.intersects_ray(camera.project_ray_origin(position2D),camera.project_ray_normal(position2D))
	if (position3D):
		cursor.transform.origin = position3D;
		
			
func _input(event):
	if (current_state):
		current_state.input(event)
	

func on_turbine_pressed():
	var s = find_state("player_build_state")
	s.building_template = turbine_building_template
	s.hud_button = hud.fan_button
	set_state(s)
	
func on_spawn_pressed():
	var s = find_state("player_build_state")
	s.building_template = spawn_building_template
	s.hud_button = hud.spawn_button
	set_state(s)
	
