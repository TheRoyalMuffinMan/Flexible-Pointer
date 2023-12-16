extends Node3D
signal tutorialDone(new_pos)
signal onTop

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_body_entered(body):
	if body.name == "Player":
		tutorialDone.emit($thirdPlat/Area3D.global_position)


func _on_top_warning_body_entered(body):
	if body.name == "Player":
		onTop.emit()
