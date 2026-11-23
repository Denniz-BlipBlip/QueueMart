extends Node2D

@export_dir var customers_folder: String = ""
@export var customer_scenes: Array[PackedScene] = []
@export var customers_parent: Node2D
@export var shop_zones_parent: Node2D
@export var waypoints_parent: Node2D
@export var queue: Node2D
@export var cashier_point: Node2D
@export var exit_point: Node2D
@export var spawn_zone: CollisionShape2D
@export var min_interval: float = 3.0
@export var max_interval: float = 7.0
@export var max_customers: int = 15
@export var min_stops: int = 2
@export var max_stops: int = 5
@export var spawn_jitter: float = 6.0
@export var spawn_on_start: bool = true

var timer: Timer
var scene_pool: Array[PackedScene] = []

func _ready():
	_load_pool()
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_on_timer)
	add_child(timer)
	if spawn_on_start:
		_on_timer.call_deferred()
	else:
		_restart_timer()

func _load_pool():
	scene_pool.clear()
	for scene in customer_scenes:
		if scene:
			scene_pool.append(scene)
	if customers_folder == "":
		return
	var dir = DirAccess.open(customers_folder)
	if not dir:
		push_warning("Spawner: cannot open folder '%s'." % customers_folder)
		return
	for file_name in dir.get_files():
		var clean_name = file_name.trim_suffix(".remap")
		if clean_name.ends_with(".tscn"):
			var loaded = load(customers_folder.path_join(clean_name))
			if loaded is PackedScene:
				scene_pool.append(loaded)

func _queue_ok() -> bool:
	return queue != null and queue.has_method("join")

func _restart_timer():
	timer.start(randf_range(min_interval, max_interval))

func _config_ok() -> bool:
	var ok = true
	if queue and not queue.has_method("join"):
		push_warning("Spawner: the Queue node has no checkout_queue.gd attached, so customers cannot line up.")
	if not queue:
		push_warning("Spawner: Queue is not set, so customers will not line up.")
	if scene_pool.is_empty():
		push_warning("Spawner: no customer scenes found. Set Customers Folder or Customer Scenes.")
		ok = false
	if not customers_parent:
		push_warning("Spawner: Customers Parent is not set.")
		ok = false
	if not exit_point:
		push_warning("Spawner: Exit Point is not set.")
		ok = false
	return ok

func _on_timer():
	if _config_ok() and customers_parent.get_child_count() < max_customers:
		_spawn()
	_restart_timer()

func _spawn():
	var scene = scene_pool.pick_random()
	var customer = scene.instantiate()
	if not ("exit_position" in customer):
		push_warning("Spawner: '%s' has no customer.gd on its root node." % scene.resource_path)
		customer.queue_free()
		return
	customers_parent.add_child(customer)
	customer.global_position = _spawn_position()
	customer.exit_position = exit_point.global_position
	customer.queue = queue if _queue_ok() else null
	var points = _build_route()
	if points.is_empty() and not _queue_ok():
		customer.leave()
	else:
		customer.start_route(points)

func _build_route() -> Array[Vector2]:
	var points: Array[Vector2] = []
	var stops = randi_range(min_stops, maxi(min_stops, max_stops))
	var zones = _get_zones()
	if not zones.is_empty():
		for i in stops:
			points.append(_point_in_zone(_pick_zone(zones)))
	elif waypoints_parent and waypoints_parent.get_child_count() > 0:
		var markers = waypoints_parent.get_children()
		markers.shuffle()
		for i in mini(stops, markers.size()):
			points.append(markers[i].global_position)
	if cashier_point and not _queue_ok():
		points.append(cashier_point.global_position)
	return points

func _get_zones() -> Array:
	var zones = []
	if shop_zones_parent:
		for node in shop_zones_parent.find_children("*", "CollisionShape2D", true, false):
			if node.shape is RectangleShape2D:
				zones.append(node)
	return zones

func _pick_zone(zones: Array) -> CollisionShape2D:
	var total = 0.0
	for zone in zones:
		total += zone.shape.size.x * zone.shape.size.y
	var roll = randf() * total
	for zone in zones:
		roll -= zone.shape.size.x * zone.shape.size.y
		if roll <= 0.0:
			return zone
	return zones.back()

func _point_in_zone(zone: CollisionShape2D) -> Vector2:
	var half = zone.shape.size / 2.0
	var local_point = Vector2(randf_range(-half.x, half.x), randf_range(-half.y, half.y))
	return zone.global_transform * local_point

func _spawn_position() -> Vector2:
	if spawn_zone and spawn_zone.shape is RectangleShape2D:
		return _point_in_zone(spawn_zone)
	var offset = Vector2(randf_range(-spawn_jitter, spawn_jitter), randf_range(-spawn_jitter, spawn_jitter))
	return global_position + offset
