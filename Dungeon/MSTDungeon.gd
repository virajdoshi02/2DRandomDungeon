extends Node2D

signal rooms_placed

const Room := preload("Room.tscn")

@export var max_rooms := 60 / 4


@export var reconnection_factor := 0.025 * 0

var _rng := RandomNumberGenerator.new()
var roomArr := []
var corridorArr := []
var _path: AStar2D = null
var _sleeping_rooms := 0
var _mean_room_area := 0.0
var _draw_extra := []

var treasureRooms:int = 0

@onready var rooms: Node2D = $Rooms
@onready var level: TileMap = $Level
@onready var minLeaves = 3
@onready var errorText = $CanvasLayer/ErrorText

func _ready() -> void:
	_rng.randomize()
	_generate()

func getDistanceBtwPoints(p1:int,p2:int,astar:AStar2D)->float:
	var path = astar.get_id_path(p1,p2)
	match(path):
		[var a]:
			return 0
		[var a,var b]:
			return astar.get_point_position(a).distance_to(astar.get_point_position(b))
		_: 
			var dist = 0
			var a:int
			var b:int
			for i in range(len(path)):
				if i==0:
					continue
				a = path[i-1]
				b = path[i]
				dist+= astar.get_point_position(a).distance_to(astar.get_point_position(b))
			return dist

func _on_Room_sleeping_state_changed(room: MSTDungeonRoom) -> void:
	room.modulate = Color.YELLOW
	_sleeping_rooms += 1
	if _sleeping_rooms < max_rooms:
		return

	var main_rooms := []
	var main_rooms_positions := []
	for child_room in rooms.get_children():
		if _is_main_room(child_room):
			main_rooms.push_back(child_room)
			main_rooms_positions.push_back(child_room.position)
			child_room.modulate = Color.RED

	_path = MSTDungeonClass.mst(main_rooms_positions)
	
	var maxDist:float = 0
	var maxPoints = []
	queue_redraw()
	await get_tree().create_timer(1).timeout
	for point1_id in _path.get_point_ids():
		for point2_id in _path.get_point_ids():
			var dist = getDistanceBtwPoints(point1_id,point2_id,_path)
			if (dist>maxDist):
				maxDist = dist
				maxPoints = [point1_id,point2_id]
			
			if (
				point1_id != point2_id
				and not _path.are_points_connected(point1_id, point2_id)
				and _rng.randf() < reconnection_factor
			):
				_path.connect_points(point1_id, point2_id)
				_draw_extra.push_back(
					[_path.get_point_position(point1_id), _path.get_point_position(point2_id)]
				)
	_path.connect_points(maxPoints[0], maxPoints[1])
	var p1 = _path.get_point_position(maxPoints[0])
	var p2 = _path.get_point_position(maxPoints[1])
	_draw_extra.push_back([p1, p2])
#
	queue_redraw()
	for child_room in main_rooms:
		_add_room(child_room)
	_add_corridors()
	
	var leafCount = 0
	for node in _path.get_point_ids():
		if _path.get_point_connections(node).size()==1:
			leafCount+=1
	if leafCount< minLeaves-2:
		errorText.text = "Has less than "+str(minLeaves-2)+" leaves"
	elif  not (1<=treasureRooms and treasureRooms<4):
		errorText.text = "Wrong number of treasure rooms"
	else:
		set_process(false)
		rooms_placed.emit()


func _process(_delta: float) -> void:
	level.clear_layer(0)
	for room in rooms.get_children():
		for offset in room as MSTDungeonRoom:
			level.set_cell(0, offset, 0, Vector2i.ZERO, 0)


func _draw() -> void:
	if _path == null:
		return

	for point1_id in _path.get_point_ids():
		var point1_position := _path.get_point_position(point1_id)
		for point2_id in _path.get_point_connections(point1_id):
			var point2_position := _path.get_point_position(point2_id)
			draw_line(point1_position, point2_position, Color.RED, 20)

	if not _draw_extra.is_empty():
		for pair in _draw_extra:
			draw_line(pair[0], pair[1], Color.GREEN, 20)

func _generate() -> void:
	for _i in range(max_rooms):
		var room := Room.instantiate()
		room.sleeping_state_changed.connect(_on_Room_sleeping_state_changed.bind(room))
		room.setup(_rng, level)
		rooms.add_child(room)
		_mean_room_area += room.area
	_mean_room_area /= rooms.get_child_count()

	await rooms_placed
	
	rooms.queue_free()
	
	level.clear_layer(0)
	for room in roomArr:
		level.set_cells_terrain_connect(0, room.keys(), 0, room.values()[0])
	for corridor in corridorArr:
		level.set_cells_terrain_connect(1, corridor.keys(), 0, 2, false)

func _add_room(room: MSTDungeonRoom) -> void:
	if room.added:
		return
	var _data = {}
	var val
	match(room.groupNode.name):
		"TreasureGroup":
			val = 0
			if not room.added:
				treasureRooms+=1
		"EnemyGroup":
			val = 1
	room.addRoom()
	for offset in room:
		_data[offset] = val
	roomArr.append(_data)
	print()

func _add_corridors():
	var connected := {}
	for point1_id in _path.get_point_ids():
		for point2_id in _path.get_point_connections(point1_id):
			var point1 := _path.get_point_position(point1_id)
			var point2 := _path.get_point_position(point2_id)
			if Vector2(point1_id, point2_id) in connected:
				continue

			point1 = level.local_to_map(point1)
			point2 = level.local_to_map(point2)
			_add_corridor(point1.x, point2.x, point1.y, Vector2.AXIS_X)
			_add_corridor(point1.y, point2.y, point2.x, Vector2.AXIS_Y)
			connected[Vector2(point1_id, point2_id)] = null
			connected[Vector2(point2_id, point1_id)] = null

func _add_corridor(start: int, end: int, constant: int, axis: int) -> void:
	var _data:={}
	var t = mini(start, end)
	while t <= maxi(start, end):
		var point := Vector2.ZERO
		match axis:
			Vector2.AXIS_X:
				point = Vector2(t, constant)
			Vector2.AXIS_Y:
				point = Vector2(constant, t)
		t += 1
		for room in rooms.get_children():
			if _is_main_room(room):
				continue
			var top_left: Vector2 = level.local_to_map(room.position) as Vector2 - floor(room.size / 2)
			var bottom_right: Vector2 = level.local_to_map(room.position) as Vector2 + floor(room.size / 2)
			if (top_left.x <= point.x and point.x < bottom_right.x and top_left.y <= point.y and point.y < bottom_right.y):
				_add_room(room)
		_data[point] = null
	corridorArr.append(_data)


func _is_main_room(room: MSTDungeonRoom) -> bool:
	var arr = rooms.get_children()
	arr.sort_custom(
		func(a,b):
			if a.area<b.area:
				return true
			return false)
	var elt = arr[int(0.55*arr.size())]
	return room.area > elt.area


func _on_button_pressed():
	get_tree().reload_current_scene()
