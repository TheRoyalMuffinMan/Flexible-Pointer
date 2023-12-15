extends RigidBody3D

@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo
@onready var previous_point_two: MeshInstance3D = point_two
var torso_offset: Vector3 = Vector3(0, -0.2, 0)
var point_one: MeshInstance3D = null
var right_controller_origin: Vector3 = Vector3.ZERO
var default_color: Color = Color(1, 1, 1, 1)
var updated_color: Color = Color(0.95, 0, 0.04, 1)
var calibration_distance: float = 0.0
var altering_curve: bool = false
var altering_point_two: bool = false
var t_end: float = 1.0
var t_incrementor: float = 0.2
var sphere_meshes: Array[MeshInstance3D] = []
var sphere_radius: float = 0.05
var sphere_height: float = 0.10
var altering_speed: float = 2.5
var distance_between: float = 0.3
var n_spheres: int = 50
var n_points: int = 0

func _ready():
	for i in range(n_spheres):
		var mesh_instance = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		var material = StandardMaterial3D.new()
		
		material.albedo_color = default_color
		sphere_mesh.radius = sphere_radius
		sphere_mesh.height = sphere_height
		mesh_instance.visible = false
		mesh_instance.mesh = sphere_mesh
		mesh_instance.material_override = material
		mesh_instance.global_position = Vector3.ZERO
		
		left_controller.add_child(mesh_instance)
		sphere_meshes.append(mesh_instance)

func quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var bezier_point = q0.lerp(q1, t)
	return bezier_point

# This performs a binary search between the range (0.0, 1.0) to find a 
# incrementor that will produce points within max distance.
func approximate_incrementor(p0: Vector3, p1: Vector3, p2: Vector3, max_distance: float):
	var low = 0.0
	var high = 1.0
	var epsilon = 0.0001
	
	# Stop interation once the difference becomes less than epsilon
	while (high - low) > epsilon:
		var mid = (low + high) / 2.0
		var bezier_point = quadratic_bezier(p0, p1, p2, mid)
		var distance = p0.distance_to(bezier_point)
		
		if distance < max_distance:
			low = mid
		else:
			high = mid
			
	return (low + high) / 2.0
	
func generate_points(p0: Vector3, p1: Vector3, p2: Vector3):
	n_points = 0
	var points = [p0]
	var incrementor = min(
		approximate_incrementor(p0, p1, p2, distance_between),
		t_incrementor
	)
	var t = incrementor
	while t <= t_end - incrementor:
		points.append(quadratic_bezier(p0, p1, p2, t))
		t += incrementor
	n_points = len(points)
	return points

func alter_meshes(points):
	for i in range(n_points):
		sphere_meshes[i].visible = true
		sphere_meshes[i].global_position = points[i]
	
	for i in range(n_points, len(sphere_meshes)):
		sphere_meshes[i].visible = false
		sphere_meshes[i].global_position = Vector3.ZERO

func select_sphere(controller: XRController3D):
	var ratio = calibration_distance / n_points
	var start = $XROrigin3D/XRCamera3D.global_position + torso_offset
	var end = controller.global_position
	var current_distance = start.distance_squared_to(end)
	var percentage = current_distance / calibration_distance
	var computed_index = round(percentage * (n_points - 1)) + 1
	var index = clamp(computed_index, 1, n_points - 1)
	return sphere_meshes[index]

func highlight_one(sphere: MeshInstance3D):
	for i in range(n_points):
		if sphere_meshes[i] == sphere:
			sphere.material_override.albedo_color = updated_color
		else:
			sphere_meshes[i].material_override.albedo_color = default_color	

func highlight_all(controller: XRController3D):
	var sphere = select_sphere(controller)
	highlight_one(sphere)

func alter_curve(delta: float, sphere: MeshInstance3D):
	var diff = $XROrigin3D/RightController.global_position - right_controller_origin
	right_controller_origin = $XROrigin3D/RightController.global_position
	sphere.global_position += diff * altering_speed
	sphere.material_override.albedo_color = updated_color
	
func _process(delta: float):
	if point_two.visible:
		if calibration_distance != 0.0:
			if point_one != null:
				highlight_one(point_one)
			else:
				highlight_all($XROrigin3D/RightController)
		
		if altering_curve:
			if point_one == null:
				point_one = select_sphere($XROrigin3D/RightController).duplicate()
				left_controller.add_child(point_one)
				
			alter_curve(delta, point_one)
			
		var start = left_controller.global_position
		var end = point_two.global_position
		var mid = (start + end) / 2.0
		if point_one != null:
			mid = point_one.global_position
			
		alter_meshes(generate_points(start, mid, end))
		
		if altering_point_two:
			var dir_vector = end - sphere_meshes[n_points - 1].global_position
			point_two.global_position += dir_vector * altering_speed * delta

func _on_left_controller_button_pressed(name: String):
	if name == "trigger_click":
		point_two.visible = true
	
	if name == "ax_button":
		if previous_point_two == point_two:
			point_two = point_two.duplicate()
			left_controller.add_child(point_two)
			previous_point_two.visible = false
		altering_point_two = true

func _on_left_controller_button_released(name: String):
	if name == "trigger_click":
		if previous_point_two != point_two:
			left_controller.remove_child(point_two)
			point_two = previous_point_two
			point_two.visible = true
		
		point_two.visible = false
		left_controller.remove_child(point_one)
		point_one = null
		for i in range(n_points):
			sphere_meshes[i].visible = false
	
	if name == "ax_button":
		altering_point_two = false
			
func _on_right_controller_button_pressed(name: String):
	if name == "grip_click" and calibration_distance != 0.0 and point_two.visible:
		altering_curve = true
		right_controller_origin = $XROrigin3D/RightController.global_position
	
	if name == "ax_button" and calibration_distance == 0.0:
		# Begin right calibration
		var start = $XROrigin3D/XRCamera3D.global_position
		var end = $XROrigin3D/RightController.global_position
		calibration_distance = start.distance_squared_to(end)

func _on_right_controller_button_released(name: String):
	if name == "grip_click" and calibration_distance != 0.0 and point_two.visible:
		altering_curve = false
