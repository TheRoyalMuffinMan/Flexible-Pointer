extends Node3D

var time = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Keeps track of time for the trig functions
	time = time + delta
	
	# Move the piller in a cyclic fashion 
	$Pliller.position.z = -7.5*cos(time*deg_to_rad(60))
	
