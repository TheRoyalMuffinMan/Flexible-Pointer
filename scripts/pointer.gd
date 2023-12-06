extends RigidBody3D

@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var point_two: MeshInstance3D = $XROrigin3D/LeftController/PointTwo
var is_active: bool = false
var point_incrementation = 0.1
var midpoint: Vector3 = Vector3.ZERO
var distance: int = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func quadratic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var r = q0.lerp(q1, t)
	return r
	
func generate_points(start, mid, end):
	var points = Array() 
	for t in range(0.1, 1 + point_incrementation, point_incrementation):
		points.append(quadratic_bezier(start, mid, end, t))
	return points

func alter_meshes(points):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_active:
		var start = left_controller.global_position
		var end = point_two.global_position
		var mid = (start + end) / 2.0
		var points = generate_points(start, mid, end)
		print(start, mid, end)
		print(points)
	
func _button_pressed(name: String):
	if name == "trigger_click":
		is_active = true
		midpoint
		# Build/move meshes here for the given points on the first iteration
	
func _button_released(name: String):
	if name == "trigger_click":
		is_active = false
		# set meshes to invisible
