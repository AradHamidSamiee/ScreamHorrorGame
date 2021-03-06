extends KinematicBody

var mouse_sens = 0.5
var move_speed = 6.0
var footstep_rate = 0.5
var cur_step_time = 0.0

var light_turn_speed = 5.0

var key_count = 0
var dead = false

onready var raycast_interactable = $Camera/RayCastInteractable

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if dead:
		return
	if event is InputEventMouseMotion:
		rotation_degrees.y -= mouse_sens * event.relative.x
		$Camera.rotation_degrees.x -= mouse_sens * event.relative.y
		$Camera.rotation_degrees.x = clamp($Camera.rotation_degrees.x, -90, 90)

func _process(_delta):
	if Input.is_action_just_pressed("exit"):
#		get_tree().quit()
		LevelManager.load_main_menu()
	if Input.is_action_just_pressed("restart") and dead:
		get_tree().reload_current_scene()
	
	if dead:
		return
	
	if Input.is_action_just_pressed("interact"):
		if raycast_interactable.is_colliding():
			var coll = raycast_interactable.get_collider()
			if "Key" in coll.name:
				pickup_key()
				coll.queue_free()
			elif "Door" in coll.name:
				if key_count > 0:
					use_key()
					LevelManager.load_next_level()
				else:
					$CanvasLayer/DoorLocked.show()
					$CanvasLayer/DoorLocked/HideTimer.start()
					$LockSound.play()
			elif "Gate" in coll.name:
				if key_count > 0:
					use_key()
					coll.open()
				else:
					$CanvasLayer/GateLocked.show()
					$CanvasLayer/GateLocked/HideTimer.start()
					$LockSound.play()
	hide_ui_popups()
	if raycast_interactable.is_colliding():
		var coll = raycast_interactable.get_collider()
		if "Key" in coll.name:
			$CanvasLayer/PickupKey.show()
		elif "Door" in coll.name:
			$CanvasLayer/OpenDoor.show()
		elif "Gate" in coll.name:
			$CanvasLayer/OpenGate.show()
		elif "Note" in coll.name:
			$CanvasLayer/NoteDisplay.show()
			$CanvasLayer/NoteDisplay.text = coll.get_node("Label").text

func hide_ui_popups():
	$CanvasLayer/OpenDoor.hide()
	$CanvasLayer/PickupKey.hide()
	$CanvasLayer/OpenGate.hide()
	$CanvasLayer/NoteDisplay.hide()

func pickup_key():
	$KeyPickupSound.play()
	key_count += 1
	var ind = 0
	for key in $CanvasLayer/Keys.get_children():
		if ind < key_count:
			key.show()
		else:
			key.hide()
		ind += 1

func use_key():
	key_count -= 1
	var ind = 0
	for key in $CanvasLayer/Keys.get_children():
		if ind < key_count:
			key.show()
		else:
			key.hide()
		ind += 1

func _physics_process(_delta):
	if dead:
		return
	var move_vec = Vector3()
	if Input.is_action_pressed("move_forward"):
		move_vec += Vector3.FORWARD
	if Input.is_action_pressed("move_backwards"):
		move_vec += Vector3.BACK
	if Input.is_action_pressed("move_right"):
		move_vec += Vector3.RIGHT
	if Input.is_action_pressed("move_left"):
		move_vec += Vector3.LEFT
	
	if move_vec != Vector3.ZERO:
		cur_step_time += _delta
		if cur_step_time >= footstep_rate:
			cur_step_time = 0.0
			$FootstepSounds.play()

	move_vec = move_vec.normalized()
	move_vec = move_vec.rotated(Vector3.UP, rotation.y)

	move_and_slide(move_vec * move_speed, Vector3.UP)
	global_transform.origin.y = 0

func kill():
	if dead:
		return
	hide_ui_popups()
	dead = true
	$"CanvasLayer2/You Died/AnimationPlayer".play("fadein")
	$DeathSounds/AnimationPlayer.play("deathsounds")
