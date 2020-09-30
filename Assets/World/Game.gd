tool
extends Spatial
class_name Game

signal notification(message_type, message_text) # int, String

enum CameraYRotation {
	MINUS_45 = -45,
	PLUS_45 = 45,
	PLUS_135 = 135,
	MINUS_135 = -135,
}

export(bool) var in_game_preview := true

export(CameraYRotation) var viewport_1_y_rotation := CameraYRotation.MINUS_45
export(CameraYRotation) var viewport_2_y_rotation := CameraYRotation.PLUS_45
export(CameraYRotation) var viewport_3_y_rotation := CameraYRotation.PLUS_135
export(CameraYRotation) var viewport_4_y_rotation := CameraYRotation.MINUS_135

var viewport_cameras = []

var is_game_running = false

var player_start: Spatial = null
var player: Control = null
#var players := [Control]

var ai_players = []

func _ready() -> void:
	if Engine.is_editor_hint():
		_get_editor_viewports()
		return

	Global.Game = self
	player_start = Global.PlayerStart

	randomize()
	prints("[New Game]")
	Audio.play_entry_snd()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if in_game_preview:
			_update_editor_viewports()
		return

	if not is_game_running:
		start_game()

# Notification test (press N within a game session)
func _input(event: InputEvent):
	if event.is_action_pressed("debug_raise_notification"):
		emit_signal("notification", 3, "This is a test notification.")

func start_game() -> void:
	if player_start:
		player = Player.new()
		player.faction = Global.faction

		add_child(player)
		# warning-ignore:return_value_discarded
		connect("notification", player, "_on_Game_notification")

		# Assign player starter ship
		var ships = player_start.get_children()
		ships[(randi() % ships.size())].faction = player.faction

		var factions: Array = range(1, 15)
		factions.remove(factions.find(player.faction)) # remove occupied faction from array

		# Assign AI starter ships
		ai_players.resize(Global.ai_players)
		if ai_players.size() > 0: printt("ai_player", "ship")
		for ai_player in range(ai_players.size()):
			ai_players[ai_player] = factions[randi() % factions.size()] # assign random faction to AI player
			factions.remove(factions.find(ai_players[ai_player])) # remove occupied faction from array

			for ship in ships:
				if ship.faction == Global.Faction.NONE:
					ship.faction = ai_players[ai_player]
					printt(ai_players[ai_player], ship.name)
					break

		# Remove any ships left over
		for ship in ships:
			if ship.faction == Global.Faction.NONE:
				ship.queue_free()

		# Traders
		if not Global.has_traders:
			var traders := get_node("Traders")
			if traders != null:
				traders.queue_free()

		# Pirates
		if not Global.has_pirates:
			var pirates := get_node("Pirates")
			if pirates != null:
				pirates.queue_free()

		# Disasters
		if not Global.has_disasters:
			pass # TODO

	is_game_running = true

func _get_editor_viewports() -> void:
	var editor_plugin = EditorPlugin.new()
	var editor_interface = editor_plugin.get_editor_interface()

	var spatial_editor = editor_interface.get_editor_viewport().get_child(1)
	# get_child(1) HSplitContainer:10997
	#  .get_child(0) VSplitContainer:10998
	#   .get_child(0) SpatialEditorViewportContainer:10999
	#    .get_children()
	#
	# [SpatialEditorViewport:11000] => [ViewportContainer:11001] => [Viewport:11002]
	# [SpatialEditorViewport:11051] => [ViewportContainer:11052] => [Viewport:11053]
	# [SpatialEditorViewport:11081] => [ViewportContainer:11082] => [Viewport:11083]
	# [SpatialEditorViewport:11111] => [ViewportContainer:11112] => [Viewport:11113]
	for spatial_editor_viewport in spatial_editor.\
		get_child(1).\
		 get_child(0).\
		  get_child(0).\
		   get_children():

		viewport_cameras.append(spatial_editor_viewport.get_child(0).get_child(0).get_camera())

	# Realign in the order as they appear in the 3D editor when adding another one
	viewport_cameras = [
		viewport_cameras[0],
		viewport_cameras[2],
		viewport_cameras[3],
		viewport_cameras[1],
	]

func _update_editor_viewports() -> void:
	if viewport_cameras == []:
		_get_editor_viewports()

	var i = 1
	for viewport_camera in viewport_cameras:
		viewport_camera.rotation_degrees.x = -35
		viewport_camera.rotation_degrees.y = get("viewport_%s_y_rotation" % i)
		viewport_camera.rotation_degrees.z = 0
		i += 1
