extends RigidBody3D

@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo
@onready var point_two_origin: Vector3 = point_two.global_position
var is_active: bool = false
var t_start: float = 0.0
var t_end: float = 1.0
var t_incrementor: float = 0.1
var midpoint: Vector3 = Vector3.ZERO
var sphere_meshes: Array[MeshInstance3D] = []
var sphere_radius: float = 0.05
var sphere_height: float = 0.10

# Called when the node enters the scene tree for the first time.
func _ready():
	var t = t_start
	while t <= t_end:
		var mesh_instance = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = sphere_radius
		sphere_mesh.height = sphere_height
		mesh_instance.visible = false
		mesh_instance.mesh = sphere_mesh
		mesh_instance.global_position = Vector3.ZERO
		add_child(mesh_instance)
		
		sphere_meshes.append(mesh_instance)
		t += t_incrementor

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

func _process(delta):
	if point_two.visible:
		var start = left_controller.global_position
		var end = point_two.global_position
		var mid = (start + end) / 2.0
		var points = generate_points(start, mid, end)
		alter_meshes(points)
	
func _button_pressed(name: String):
	if name == "trigger_click":
		point_two.visible = true
	
func _button_released(name: String):
	if name == "trigger_click":
		point_two.visible = false
		for i in range(len(sphere_meshes)):
			sphere_meshes[i].visible = false
