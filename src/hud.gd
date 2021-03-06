extends Control

@onready var spawn_button = $SpawnButton
@onready var fan_button = $FanButton
@onready var debug_label = $DebugLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _process(delta):
	debug_label.text = "FPS: %d\nPROCESS: %fms" % [Performance.get_monitor(Performance.TIME_FPS), Performance.get_monitor(Performance.TIME_PROCESS) * 1000]
	debug_label.text += "\ndensity dest: %d" % [Store.players[0].density_dst]
