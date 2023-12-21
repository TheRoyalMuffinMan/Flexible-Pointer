extends MeshInstance3D

const ALTERING_SPEED: float = 20

@onready var previous_position: Vector3 = self.position
var intersecting: bool = false

# Executed once per frame (core logic)
func _process(delta: float) -> void:
	if intersecting:
		var direction_vector: Vector3 = self.previous_position - self.position
		self.position += direction_vector  * ALTERING_SPEED * delta
	else:
		self.previous_position = self.position

func _on_area_3d_body_entered(body):
	print(self)
	self.intersecting = true

func _on_area_3d_body_exited(body):
	self.intersecting = false
