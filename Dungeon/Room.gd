class_name MSTDungeonRoom
extends RigidBody2D


# Used to test that the body didn't move over consecutive frames.
const CONSECUTIVE_MAX_EQUALITIES := 10

# Radius of the circle in which we randomly place the room.
@export var radius := 600*6
# Interval to generate a random width and height for the room, in tiles.
@export var room_size := Vector2(10, 15)

var size := Vector2.ZERO

var _level: TileMap = null
var _rng: RandomNumberGenerator = null
var _previous_xform := Transform2D()
var _consecutive_equalities := 0

var area := 0.0
var _iter_index := 0

@onready var threshold = 155
@onready var groupNode = $Group

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var added = false

func addRoom():
	added = true
	remove_child($CollisionShape2D)

func setup(rng: RandomNumberGenerator, level: TileMap) -> void:
	_rng = rng
	_level = level


func _ready() -> void:
	position = MSTDungeonClass.get_rng_point_in_ellipse(_rng, radius,radius/3)
	var w := _rng.randi_range(room_size.x, room_size.y)
	var h := _rng.randi_range(room_size.x, room_size.y)
	area = w * h
	size = Vector2(w, h)
	collision_shape.shape.extents = _level.map_to_local(size) / 2
	
	if area<threshold:
		groupNode.name = "TreasureGroup"
	else:
		groupNode.name = "EnemyGroup"


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if freeze_mode == RigidBody2D.FREEZE_MODE_STATIC:
		return

	if MSTDungeonClass.is_approx_equal(_previous_xform.origin, state.transform.origin):
		_consecutive_equalities += 1

	if _consecutive_equalities > CONSECUTIVE_MAX_EQUALITIES:
		set_deferred("mode", RigidBody2D.FREEZE_MODE_STATIC)
		call_deferred("emit_signal", "sleeping_state_changed")
	_previous_xform = state.transform

func _iter_init(_arg) -> bool:
	_iter_index = 0
	return _iter_is_running()

func _iter_next(_arg) -> bool:
	_iter_index += 1
	return _iter_is_running()

func _iter_get(_arg) -> Vector2:
	var width := size.x
	var offset := MSTDungeonClass.index_to_xy(width, _iter_index)
	return _level.local_to_map(position) as Vector2 - size / 2 + offset

func _iter_is_running() -> bool:
	return _iter_index < area

