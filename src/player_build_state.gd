extends Node

var player
var name = "player_build_state"

var building
var rotating_building = false

func enter():
	building = player.fan_building_template.instance()
	player.cursor.add_child(building)
	pass

func exit():
	if (building):
		player.cursor.remove_child(building)
		building.queue_free()
		building = null
		player.hud.fan_button.pressed = false
		
	pass


func input(event):
	if event is InputEventMouseMotion:
		player.update_cursor_transform()
		
		if (building && rotating_building):
			#var dir = cursor.transform.origin - building.transform.origin
			building.transform = building.transform.looking_at(player.cursor.transform.origin, Vector3(0, 1, 0))
	
	if Input.is_action_pressed("left_click"):
		if (building && rotating_building):
			confirm_building_rotation()
			return
			
		if (building):
			confirm_building_position()
			return
			
	# abort!
	if Input.is_action_pressed("right_click"):
		player.set_state(player.prev_state)
		
func process(delta):
	pass
	

func confirm_building_position():
	var xform = building.global_transform
	rotating_building = true
	player.cursor.remove_child(building)
	Store.map.add_child(building)
	building.transform = xform
	
func confirm_building_rotation():
	player.hud.fan_button.pressed = false
	var xform = building.global_transform
	Store.buildings.append(building)
	building.spawn(xform)
	building = null
	rotating_building = false
	player.set_state(player.prev_state)

