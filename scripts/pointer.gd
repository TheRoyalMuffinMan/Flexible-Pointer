extends RigidBody3D

# Constants
const TORSO_OFFSET: Vector3 = Vector3(0, -0.2, 0)
const DEFAULT_COLOR: Color = Color(0, 0.35, 1, 1)
const UPDATED_COLOR: Color = Color(0.95, 0, 0.04, 1)
const BUTTON_GREEN: Color = Color(0.22, 0.55, 0, 1)
const SPHERE_RADIUS: float = 0.05
const SPHERE_HEIGHT: float = 0.10
const ALTERING_SPEED: float = 2.5
const DISTANCE_BETWEEN: float = 1
const MAX_POINTS: float = 50
const MIN_INDEX: int = 1
const T_END: float = 1.0
const CAM_HEIGHT: float = 20
const MARKER_HEIGHT: float = 4

# On Ready Declarations
@onready var camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController
@onready var point_zero: XRController3D = $XROrigin3D/LeftController
@onready var point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo
@onready var original_point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo
@onready var left_button: Button = get_node("../CalibrationScreen/CanvasLayer/Content/LeftButton")
@onready var right_button: Button = get_node("../CalibrationScreen/CanvasLayer/Content/RightButton")
@onready var map_camera: Camera3D = get_node("../MapCamera/Camera3D")
@onready var player_marker: MeshInstance3D = get_node("../PlayerMarker")
@onready var teleport_marker: MeshInstance3D = get_node("../TeleportMarker")
@onready var start_pos: Vector3 = self.global_position

# Instance Declarations
var n_points: int = 0
var sphere_meshes: Array[MeshInstance3D] = []
var point_one: MeshInstance3D = null
var right_controller_origin: Vector3 = Vector3.ZERO
var t_incrementor: float = 0.2
var left_calib_dist: float = 0.0
var right_calib_dist: float = 0.0
var show_pointer: bool = false
var altering_curve: bool = false
var extend_pointer: bool = false
var teleport: int = 0

func _ready():
	for i in range(self.MAX_POINTS):
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var sphere_mesh: SphereMesh = SphereMesh.new()
		var material: StandardMaterial3D = StandardMaterial3D.new()
		var area3D: Area3D = Area3D.new()
		var collision_shape: CollisionShape3D = CollisionShape3D.new()
		var sphere_shape: SphereShape3D = SphereShape3D.new()
		
		# Setting up collisions
		sphere_shape.radius = self.SPHERE_RADIUS
		collision_shape.shape = sphere_shape
		area3D.add_child(collision_shape)
		
		material.albedo_color = self.DEFAULT_COLOR
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		
		sphere_mesh.radius = self.SPHERE_RADIUS
		sphere_mesh.height = self.SPHERE_HEIGHT
		mesh_instance.visible = false
		mesh_instance.mesh = sphere_mesh
		mesh_instance.material_override = material
		mesh_instance.add_child(area3D)
		
		self.left_controller.add_child(mesh_instance)
		self.sphere_meshes.append(mesh_instance)

# Generate a bezier point utilizing linear interpolation
func quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	var q0: Vector3 = p0.lerp(p1, t)
	var q1: Vector3 = p1.lerp(p2, t)
	var bezier_point: Vector3 = q0.lerp(q1, t)
	return bezier_point

# Computes average distance between all the points that would be generated
# Runtime: O(T_END / incrementor)
func average_distance(p0: Vector3, p1: Vector3, p2: Vector3, incrementor: float) -> float:
	var prev_point: Vector3 = p0
	var distance: float = 0.0
	var t: float = incrementor
	var total_points: int = 1
	
	while t <= self.T_END - incrementor:
		var new_point: Vector3 = quadratic_bezier(p0, p1, p2, t)
		distance += prev_point.distance_to(new_point)
		prev_point = new_point
		total_points += 1
		t += incrementor
		
	return distance / total_points

# This performs a binary search between the range (0.0, 1.0) to find a 
# incrementor that will produce points within a given distance (maximized).
# Total Runtime: O(log(-ε) * O(T_END / mid))
func approximate_incrementor(p0: Vector3, p1: Vector3, p2: Vector3, max_distance: float) -> float:
	var low: float = 0.0
	var high: float = 1.0
	var epsilon: float = 0.0001
	
	# Stop interation once the difference becomes less than epsilon
	while (high - low) > epsilon:
		var mid: float = (low + high) / 2.0
		var distance: float = average_distance(p0, p1, p2, mid)
		# Old way to approximate average
		# var bezier_point: Vector3 = quadratic_bezier(p0, p1, p2, mid)
		# var distance: float = p0.distance_to(bezier_point)
		
		if distance < max_distance:
			low = mid
		else:
			high = mid
	
	return (low + high) / 2.0

# Generates points on quadratic bezier
func generate_points(p0: Vector3, p1: Vector3, p2: Vector3) -> Array[Vector3]:
	self.n_points = 0
	var points: Array[Vector3] = [p0]
	var incrementor: float = min(
		approximate_incrementor(p0, p1, p2, self.DISTANCE_BETWEEN),
		self.t_incrementor
	)
	var t: float = incrementor
	while t <= self.T_END - incrementor:
		points.append(quadratic_bezier(p0, p1, p2, t))
		t += incrementor
	self.n_points = len(points)
	
	return points

# Alters the avaliable sphere meshes to mimic to points produced by the
# quadratic bezier
func alter_meshes(points) -> void:
	for i in range(self.n_points):
		self.sphere_meshes[i].visible = true
		self.sphere_meshes[i].global_position = points[i]
	
	for i in range(self.n_points, len(self.sphere_meshes)):
		self.sphere_meshes[i].visible = false
		self.sphere_meshes[i].global_position = Vector3.ZERO

# Alters the length of the entire pointer by using the distance of the right 
# controller to the user's torso
func alter_length(controller: XRController3D, delta: float) -> void:
	if self.n_points == self.MAX_POINTS:
		return
	
	var start: Vector3 = self.camera.global_position + self.TORSO_OFFSET
	var end: Vector3 = controller.global_position
	var current_distance: float = start.distance_to(end)
	var percentage: float = current_distance / self.left_calib_dist	
	if self.original_point_two == self.point_two:
		self.point_two = self.point_two.duplicate()
		self.left_controller.add_child(self.point_two)
		self.original_point_two.visible = false
	
	var direction: int = 1 if percentage >= 0.50 else -1
	var p0: Vector3 = self.sphere_meshes[self.n_points - 1].global_position
	var p1: Vector3 = self.point_two.global_position
	var direction_vector: Vector3 = p1 - p0
	self.point_two.global_position += (direction_vector * direction) * self.ALTERING_SPEED * delta

# Selects a sphere using the distance of the right controller to the user's torso
func select_sphere(controller: XRController3D) -> MeshInstance3D:
	var start: Vector3 = self.camera.global_position + self.TORSO_OFFSET
	var end: Vector3 = controller.global_position
	var current_distance: float = start.distance_to(end)
	var percentage: float = current_distance / self.right_calib_dist
	var computed_index: int = round(percentage * (self.n_points - 1)) + 1
	
	# Ignore the 0th index (start indexing at 1 as the minimum)
	var index: int = clamp(computed_index, self.MIN_INDEX, self.n_points - 1)
	return self.sphere_meshes[index]

# Performs highlighting on all the points relative to the point
# the controller is close to
func highlight_all(controller: XRController3D) -> void:
	var sphere: MeshInstance3D = select_sphere(controller)
	for i in range(self.n_points):
		if self.sphere_meshes[i] == sphere:
			sphere.material_override.albedo_color = self.UPDATED_COLOR
		else:
			self.sphere_meshes[i].material_override.albedo_color = self.DEFAULT_COLOR

# Allows to the user to manipulative the curve by mimic the changing
# vectors on the controller
func alter_curve(sphere: MeshInstance3D) -> void:
	var diff: Vector3 = self.right_controller.global_position - self.right_controller_origin
	self.right_controller_origin = self.right_controller.global_position
	sphere.global_position += diff * self.ALTERING_SPEED
	sphere.material_override.albedo_color = self.UPDATED_COLOR

# Executed once per frame (core logic)
func _process(delta: float) -> void:
	if self.global_position.y < -10:
		self.global_position = start_pos
	
	self.map_camera.global_position.x = self.global_position.x
	self.map_camera.global_position.z = self.global_position.z
	self.map_camera.global_position.y = self.global_position.y + CAM_HEIGHT
	
	self.player_marker.global_position.x = self.global_position.x
	self.player_marker.global_position.z = self.global_position.z
	self.player_marker.global_position.y = self.global_position.y + MARKER_HEIGHT
	
	self.teleport_marker.global_position.x = self.point_two.global_position.x
	self.teleport_marker.global_position.z = self.point_two.global_position.z
	self.teleport_marker.global_position.y = self.point_two.global_position.y + MARKER_HEIGHT
	
	var menu: MeshInstance3D = self.camera.find_child("SpatialMenu")
	if self.left_calib_dist != 0.0 and self.right_calib_dist != 0.0 and menu != null:
		self.camera.remove_child(menu)
	
	# Need to hold the trigger and finish calibration to use pointer
	if not self.show_pointer or self.left_calib_dist == 0.0 or self.right_calib_dist == 0.0:
		return
		
	if self.point_one == null:
		highlight_all(right_controller)
	
	if self.altering_curve:
		if self.point_one == null:
			self.point_one = select_sphere(self.right_controller).duplicate()
			self.left_controller.add_child(self.point_one)
		alter_curve(self.point_one)
		
	var start: Vector3 = self.point_zero.global_position
	var end: Vector3 = self.point_two.global_position
	var mid: Vector3 = (start + end) / 2.0
	if self.point_one != null:
		mid = self.point_one.global_position
	
	self.point_two.visible = true
	self.teleport_marker.visible = true
	alter_meshes(generate_points(start, mid, end))
	if self.extend_pointer:
		alter_length(self.left_controller, delta)

func _on_left_controller_button_pressed(name: String) -> void:
	if name == "trigger_click" and self.left_calib_dist != 0.0 and self.right_calib_dist != 0.0:
		self.show_pointer = true
	
	if name == "grip_click" and self.left_calib_dist != 0.0 and self.point_two.visible:
		self.extend_pointer = true
	
	# Left Calibration
	if name == "ax_button" and self.left_calib_dist == 0.0:
		self.left_button.get_theme_stylebox("normal").bg_color = self.BUTTON_GREEN
		var start: Vector3 = self.camera.global_position + self.TORSO_OFFSET
		var end: Vector3 = self.left_controller.global_position
		self.left_calib_dist = start.distance_to(end)

func _on_left_controller_button_released(name: String) -> void:
	# Trigger cleanup
	if name == "trigger_click" and self.left_calib_dist != 0.0 and self.right_calib_dist != 0.0:
		var is_overlapping: bool = point_two.get_child(0).has_overlapping_bodies()
		for i in range(self.n_points):
			var area3D: Area3D = self.sphere_meshes[i].get_child(0)
			is_overlapping = area3D.has_overlapping_bodies()
		
		if not is_overlapping:
			self.global_position = self.point_two.global_position
		
		# Delete the duplicated point_two if it doesn't equal
		# the original point_two
		if self.original_point_two != self.point_two:
			self.left_controller.remove_child(self.point_two)
			self.point_two = self.original_point_two
			self.point_two.visible = true
		
		if self.point_one:
			self.left_controller.remove_child(self.point_one)
		for i in range(self.n_points):
			self.sphere_meshes[i].visible = false
		
		self.point_one = null
		self.point_two.visible = false
		self.teleport_marker.visible = false
		self.show_pointer = false
	
	if name == "grip_click" and self.left_calib_dist != 0.0 and self.point_two.visible:
		self.extend_pointer = false

func _on_right_controller_button_pressed(name: String) -> void:
	# Point selection after calibration
	if name == "grip_click" and self.right_calib_dist != 0.0 and self.point_two.visible:
		self.altering_curve = true
		self.right_controller_origin = self.right_controller.global_position
	
	# Right calibration
	if name == "ax_button" and self.right_calib_dist == 0.0:
		self.right_button.get_theme_stylebox("normal").bg_color = self.BUTTON_GREEN
		var start: Vector3 = self.camera.global_position + self.TORSO_OFFSET
		var end: Vector3 = self.right_controller.global_position
		self.right_calib_dist = start.distance_to(end)

func _on_right_controller_button_released(name: String) -> void:
	# Point release after calibration
	if name == "grip_click" and self.right_calib_dist != 0.0 and self.point_two.visible:
		self.altering_curve = false

func _on_node_3d_tutorial_done(new_pos):
	start_pos = new_pos
	#TODO: Adjust number teloports 

func _on_node_3d_on_top():
	self.global_position.y = self.global_position.y - 4
