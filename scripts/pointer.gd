extends RigidBody3D

@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo
var is_active: bool = false
var point_incrementation = 0.1
var midpoint: Vector3 = Vector3.ZERO
var distance: int = 10
var sphere_meshes: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var t = 0
	while t <= 1:
		var mesh_instance = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.05
		sphere_mesh.height = 0.10
		mesh_instance.visible = false
		mesh_instance.mesh = sphere_mesh
		mesh_instance.global_position = Vector3.ZERO
		add_child(mesh_instance)
		
		sphere_meshes.append(mesh_instance)
		t += point_incrementation

func quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r
	
func generate_points(start, mid, end):
	var points = Array() 
	var t = 0
	while t <= 1:
		points.append(quadratic_bezier(start, mid, end, t))
		t += point_incrementation
	return points
	

func alter_meshes(points):
	for i in range(len(sphere_meshes)):
		sphere_meshes[i].visible = true
		sphere_meshes[i].global_position = points[i]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_active:
		var start = left_controller.global_position
		var end = point_two.global_position
		var mid = (start + end) / 2.0
		var points = generate_points(start, mid, end)
		alter_meshes(points)
	
func _button_pressed(name: String):
	if name == "trigger_click":
		is_active = true
	
func _button_released(name: String):
	if name == "trigger_click":
		is_active = false
		for i in range(len(sphere_meshes)):
			sphere_meshes[i].visible = false
