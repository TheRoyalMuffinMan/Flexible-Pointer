extends RigidBody3D

@onready var left_controller: XRController3D = $XROrigin3D/LeftController
var is_active: bool = false

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
	for t in range(0, 1, 0.1):
		points.append(quadratic_bezier(start, mid, end, t))
	return points

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_active:
		var points = []
		var start = left_controller.position
		# need to find p2 (or end)		
	
func _button_pressed(name: String):
	if name == "trigger_click":
		is_active = true
	
func _button_released(name: String):
	if name == "trigger_click":
		is_active = false
