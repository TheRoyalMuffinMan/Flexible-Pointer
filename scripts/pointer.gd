extends RigidBody3D

@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo
var right_controller_origin: Vector3 = Vector3.ZERO
var default_color: Color = Color(1, 1, 1, 1)
var updated_color: Color = Color(0.95, 0, 0.04, 1)
var calibration_distance: float = 0.0
var altering_curve: bool = false
var t_incrementor: float = 0.2
var t_start: float = 0.0
var t_end: float = 1.0 - t_incrementor
var sphere_meshes: Array[MeshInstance3D] = []
var sphere_radius: float = 0.05
var sphere_height: float = 0.10
var point_one: MeshInstance3D = null
var selected_sphere: MeshInstance3D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var t = t_start
	while t <= t_end:
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
		t += t_incrementor
		
	point_one = sphere_meshes[len(sphere_meshes) / 2]

func quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var bezier_point = q0.lerp(q1, t)
	return bezier_point
	
func generate_points(start, mid, end):
	var points = Array() 
	var t = t_start
	while t <= t_end:
		points.append(quadratic_bezier(start, mid, end, t))
		t += t_incrementor
	return points

func alter_meshes(points):
	for i in range(len(sphere_meshes)):
		sphere_meshes[i].visible = true
		sphere_meshes[i].global_position = points[i]

func select_sphere(controller: XRController3D):
	var ratio = calibration_distance / len(sphere_meshes)
	var start = $XROrigin3D.global_position
	var end = controller.global_position
	var current_distance = start.distance_squared_to(end)
	
	var sphere = null
	var running_dist = ratio
	for i in range(len(sphere_meshes)):
		if running_dist - ratio < current_distance and current_distance <= running_dist:
			sphere = sphere_meshes[i]
			
		running_dist += ratio
	
	if sphere == null:
		sphere = sphere_meshes[len(sphere_meshes) - 1]
	
	return sphere

func highlight_one(sphere: MeshInstance3D):
	for i in range(len(sphere_meshes)):
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
	sphere.global_position += diff
	
func _process(delta: float):
	if calibration_distance != 0.0:
		if selected_sphere != null:
			highlight_one(selected_sphere)
		else:
			highlight_all($XROrigin3D/RightController)
	
	if altering_curve:
		if selected_sphere == null:
			selected_sphere = select_sphere($XROrigin3D/RightController).duplicate()
			left_controller.add_child(selected_sphere)
			point_one = selected_sphere
			
		alter_curve(delta, selected_sphere)
	
	if point_two.visible:
		var start = left_controller.global_position
		var mid = point_one.global_position
		var end = point_two.global_position
		alter_meshes(generate_points(start, mid, end))

func _on_left_controller_button_pressed(name: String):
	if name == "trigger_click":
		point_two.visible = true

func _on_left_controller_button_released(name: String):
	if name == "trigger_click":
		point_two.visible = false
		selected_sphere = null
		for i in range(len(sphere_meshes)):
			sphere_meshes[i].visible = false
			
func _on_right_controller_button_pressed(name: String):
	if name == "grip_click" and calibration_distance != 0.0:
		altering_curve = true
		right_controller_origin = $XROrigin3D/RightController.global_position
		if selected_sphere: selected_sphere.visible = true
	
	if name == "ax_button" and calibration_distance == 0.0:
		# Begin calibration
		var start = $XROrigin3D.global_position
		var end = $XROrigin3D/RightController.global_position
		calibration_distance = start.distance_squared_to(end)

func _on_right_controller_button_released(name: String):
	if name == "grip_click" and calibration_distance != 0.0:
		altering_curve = false
		selected_sphere.visible = false
