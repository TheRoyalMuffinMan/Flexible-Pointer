extends Node3D

var time = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time = time + delta
	$WithPath.position.x = 7.5*cos(time*deg_to_rad(60))
	$WithPath.position.z = 7.5*cos(time*deg_to_rad(60))
	
	$AgainstPath.position.x = 7.5*cos(time*deg_to_rad(60))
	$AgainstPath.position.z = 7.5*sin(time*deg_to_rad(60))
	
	$SideSide1.position.x = 4*cos(time*deg_to_rad(80))
	$SideSide2.position.x = -4*cos(time*deg_to_rad(80))
