extends Node3D

@export var max_speed:= 2.5
@export var dead_zone := 0.2

@export var smooth_turn_speed:= 45.0
@export var smooth_turn_dead_zone := 0.2

var input_vector:= Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	# Forward translation
	if self.input_vector.y > self.dead_zone || self.input_vector.y < -self.dead_zone:
		var movement_vector = Vector3(0, 0, max_speed * -self.input_vector.y * delta)
		self.position += movement_vector.rotated(Vector3.UP, $XROrigin3D/XRCamera3D.global_rotation.y)

	# Smooth turn
	if self.input_vector.x > self.smooth_turn_dead_zone || self.input_vector.x < -self.smooth_turn_dead_zone:

		# move to the position of the camera
		self.translate($XROrigin3D/XRCamera3D.position)

		# rotate about the camera's position
		self.rotate(Vector3.UP, deg_to_rad(smooth_turn_speed) * -self.input_vector.x * delta)

		# reverse the translation to move back to the original position
		self.translate($XROrigin3D/XRCamera3D.position * -1)

func process_input(input_name: String, input_value: Vector2):
	if input_name == "primary":
		input_vector = input_value
