extends RigidBody3D

# Constants
const TORSO_OFFSET: Vector3 = Vector3(0, -0.2, 0)
const DEFAULT_COLOR: Color = Color(1, 1, 1, 1)
const UPDATED_COLOR: Color = Color(0.95, 0, 0.04, 1)
const SPHERE_RADIUS: float = 0.05
const SPHERE_HEIGHT: float = 0.10
const ALTERING_SPEED: float = 2.5
const DISTANCE_BETWEEN: float = 0.30
const MAX_POINTS: float = 50
const MIN_INDEX: int = 1
const T_END: float = 1.0

# On Ready Declarations
@onready var camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController
@onready var point_zero: XRController3D = $XROrigin3D/LeftController
@onready var point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo
@onready var original_point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo

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

func _ready():
	for i in range(self.MAX_POINTS):
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var sphere_mesh: SphereMesh = SphereMesh.new()
		var material: StandardMaterial3D = StandardMaterial3D.new()
		
		material.albedo_color = self.DEFAULT_COLOR
		sphere_mesh.radius = self.SPHERE_RADIUS
		sphere_mesh.height = self.SPHERE_HEIGHT
		mesh_instance.visible = false
		mesh_instance.mesh = sphere_mesh
		mesh_instance.material_override = material
		mesh_instance.global_position = Vector3.ZERO
		
		self.left_controller.add_child(mesh_instance)
		self.sphere_meshes.append(mesh_instance)

# Generate a bezier point utilizing linear interpolation
func quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float) -> Vector3:
	var q0: Vector3 = p0.lerp(p1, t)
	var q1: Vector3 = p1.lerp(p2, t)
	var bezier_point: Vector3 = q0.lerp(q1, t)
	return bezier_point

# This performs a binary search between the range (0.0, 1.0) to find a 
# incrementor that will produce points within a given distance (maximized).
func approximate_incrementor(p0: Vector3, p1: Vector3, p2: Vector3, max_distance: float) -> float:
	var low: float = 0.0
	var high: float = 1.0
	var epsilon: float = 0.0001
	
	# Stop interation once the difference becomes less than epsilon
	while (high - low) > epsilon:
		var mid: float = (low + high) / 2.0
		var bezier_point: Vector3 = quadratic_bezier(p0, p1, p2, mid)
		var distance: float = p0.distance_to(bezier_point)
		
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
	
	# If in the "grey area" (0.30 < p < 0.70), don't expand or retract
	if percentage < 0.70 and percentage > 0.30:
		return
	
	if self.original_point_two == self.point_two:
		self.point_two = self.point_two.duplicate()
		self.left_controller.add_child(self.point_two)
		self.original_point_two.visible = false
	
	var direction: int = 1 if percentage >= 0.70 else -1
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
	alter_meshes(generate_points(start, mid, end))	
	alter_length(self.left_controller, delta)

func _on_left_controller_button_pressed(name: String) -> void:
	if name == "trigger_click":
		self.show_pointer = true
	
	# Left Calibration
	if name == "ax_button" and self.left_calib_dist == 0.0:
		var start: Vector3 = self.camera.global_position + self.TORSO_OFFSET
		var end: Vector3 = self.left_controller.global_position
		self.left_calib_dist = start.distance_to(end)

func _on_left_controller_button_released(name: String) -> void:
	# Trigger cleanup
	if name == "trigger_click":
		
		# Delete the duplicated point_two if it doesn't equal
		# the original point_two
		if self.original_point_two != self.point_two:
			self.left_controller.remove_child(self.point_two)
			self.point_two = self.original_point_two
			self.point_two.visible = true
		
		self.left_controller.remove_child(self.point_one)
		for i in range(self.n_points):
			self.sphere_meshes[i].visible = false
		
		self.point_one = null
		self.point_two.visible = false
		self.show_pointer = false
			
func _on_right_controller_button_pressed(name: String) -> void:
	# Point selection after calibration
	if name == "grip_click" and self.right_calib_dist != 0.0 and self.point_two.visible:
		self.altering_curve = true
		self.right_controller_origin = self.right_controller.global_position
	
	# Right calibration
	if name == "ax_button" and self.right_calib_dist == 0.0:
		var start: Vector3 = self.camera.global_position + self.TORSO_OFFSET
		var end: Vector3 = self.right_controller.global_position
		self.right_calib_dist = start.distance_to(end)

func _on_right_controller_button_released(name: String) -> void:
	if name == "grip_click" and self.right_calib_dist != 0.0 and self.point_two.visible:
		self.altering_curve = false
