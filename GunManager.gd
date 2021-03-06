extends Spatial
signal ammo_change

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var movement = Vector3()
export var health = 100

const animationStates = {
	"Idle":{"Pistol":"PistolIdle","Shotgun":"ShotgunIdle"},
	"Reload":{"Pistol":"PistolReload","Shotgun":"ShotgunReload"},
	"Walk":{"Pistol":"PistolWalk","Shotgun":"ShotgunWalk"},
}

var reloading = false
var play_walk_anim = false
var current_weapon = "Pistol"
var current_state = "Idle"
var anim_state = ""
var current_animation = animationStates[current_state][current_weapon]
var can_shoot = true
var guns_enabled = true
var transitioning_between_weapons = false

var pistol_clip = 15
export var max_pistol_clip = 15
export var pistol_low_ammo = 5
export var pistol_ammo = 20
export var max_pistol_ammo = 20

const pistol_cooldown_length = 0.4
const pistol_reload_length = 1
const pistol_equip_length = 1

var shotgun_clip = 3
export var shotgun_low_ammo = 1
export var max_shotgun_clip = 3
export var shotgun_ammo = 50
export var max_shotgun_ammo = 50

const shotgun_cooldown_length = 0.7
const shotgun_reload_length = 0.8
const shotgun_equip_length = 1

func updateAmmoHud():
	if current_weapon == "Shotgun":
		emit_signal("ammo_change",shotgun_ammo,shotgun_clip,shotgun_low_ammo)
	elif current_weapon == "Pistol":
		emit_signal("ammo_change",pistol_ammo,pistol_clip,pistol_low_ammo)


func _on_PistolTimer_timeout():
	can_shoot = true
	anim_state = ""

func _on_ShotgunTimer_timeout():
	can_shoot = true
	anim_state = ""

func _on_HitSoundDelay_timeout():
	$Gun/Hit.play()

func shootPistol():
	print("Pistol Shooting")
	var target = $RayCast.get_collider()
	if(can_shoot == true and pistol_clip > 0):
		animationHandler("Cooldown")
		pistol_clip = clamp(pistol_clip - 1,0,max_pistol_clip)
		updateAmmoHud()
		$Gun/Shot.play()
		if(target != null and target.name == "EnemyHitDetector"):
			target.get_parent_spatial().get_parent().hit(34,-get_node("../PlayerCamera").global_transform.basis.z*10)
			$Timers/HitSoundDelay.start(0.11)
	elif pistol_clip == 0:
		if $Gun/NoAmmo.playing == false and can_shoot == true:
			$Gun/NoAmmo.play()

func shootShotgun():
	var target = $RayCast.get_collider()
	if(can_shoot== true and shotgun_clip > 0):
		animationHandler("Cooldown")
		shotgun_clip = clamp(shotgun_clip - 1,0,max_shotgun_clip)
		updateAmmoHud()
		$Shotgun/Shot.play()
		$"../../../".velocity += $"../".global_transform.basis.z * -45
		if(target != null and target.name == "EnemyHitDetector"):
			target.get_parent_spatial().get_parent().hit(100,-get_node("../PlayerCamera").global_transform.basis.z*28)
			$Timers/HitSoundDelay.start(0.15)
	elif shotgun_clip == 0:
		if $Shotgun/NoAmmo.playing == false and can_shoot == true:
			$Shotgun/NoAmmo.play()

func reloadPistol():
	if(pistol_ammo>0 and pistol_clip != max_pistol_clip and reloading == false and can_shoot == true):
		$Timers/PistolReloadTimer.start(pistol_reload_length)
		$Gun/Reload.play()
		animationHandler("Reload")
		reloading = true

func reloadShotgun():
	if(shotgun_ammo>0 and shotgun_clip != max_shotgun_clip and reloading == false and can_shoot == true):
		$Timers/ShotgunReloadTimer.start(shotgun_reload_length)
		$Shotgun/Reload.play()
		animationHandler("Reload")
		shotgun_clip = clamp(shotgun_clip + 1, 0, max_shotgun_clip)
		shotgun_ammo -= 1
		updateAmmoHud()
		reloading = true
	
func _on_PistolReloadTimer_timeout():
	if pistol_ammo > 0:
		var new_ammo = clamp(pistol_ammo - (max_pistol_clip - pistol_clip),0.0,max_pistol_ammo)
		pistol_clip = clamp(pistol_ammo,0.0,max_pistol_clip)
		pistol_ammo = clamp(new_ammo,0,max_pistol_ammo)
		updateAmmoHud()
	reloading = false

func _on_ShotgunReload_timeout():
	reloading = false

func animationHandler(anim):
	if anim_state == "":
		if current_weapon == "Pistol":
			if anim == "Running":
				$Gun/AnimationPlayer.play("Gun|WalkCycle",0.01,1)
			elif anim == "Cooldown":
				$Timers/PistolTimer.start(pistol_cooldown_length)
				can_shoot = false
				anim_state = "Shooting"
				$Gun/AnimationPlayer.play("Gun|Fire")
				$Gun/MuzzleParticles.emitting = true
				$Gun/ShellParticles.emitting = true
			elif anim == "Reload":
				$Timers/PistolTimer.start(pistol_reload_length)
				can_shoot = false
				anim_state = "Reloading"
				$Gun/AnimationPlayer.play("Gun|Reload",0.1,1)
			else:
				$Gun/AnimationPlayer.play("Gun|Idle",0.1,1.2)
		elif current_weapon == "Shotgun":
			if anim == "Running":
				$Shotgun/AnimationPlayer.play("Shotgun|ShotgunWalk",0.01,1.7)
			elif anim == "Cooldown":
				$Timers/ShotgunTimer.start(shotgun_cooldown_length)
				can_shoot = false
				anim_state = "ReloadInProgress"
				$Shotgun/AnimationPlayer.play("Shotgun|Reload",0.08,-3,true)
			elif anim == "Reload":
				$Timers/ShotgunTimer.start(shotgun_reload_length)
				can_shoot = false
				anim_state = "ReloadInProgress"
				$Shotgun/AnimationPlayer.play("Shotgun|Reload",0.1,2.5)
			elif anim == "Equip":
				$Timers/ShotgunTimer.start(shotgun_equip_length)
			else:
				$Shotgun/AnimationPlayer.play("Shotgun|ShotgunIdle",0.1,0.4)
	elif anim_state == "Reloading":
		pass

func hideWeapon(weapon):
	if weapon == "Pistol":
		$Gun.hide()
	if weapon == "Shotgun":
		$Shotgun.hide()

func showWeapon(weapon):
	if weapon == "Pistol":
		$Gun.show()
	if weapon == "Shotgun":
		$Shotgun.show()

func switchWeapons(new_weapon):
	if reloading == false and anim_state == "" and transitioning_between_weapons == false and new_weapon != current_weapon:
		if new_weapon == "Pistol":
			hideWeapon(current_weapon)
			$Gun.transform.origin.y = get_node("../EquipPos").transform.origin.y
			$Timers/EquipTimer.start()
			transitioning_between_weapons = true
			showWeapon(new_weapon)
			current_weapon = "Pistol"
			updateAmmoHud()
		elif new_weapon == "Shotgun":
			hideWeapon(current_weapon)
			$Shotgun.transform.origin.y = get_node("../EquipPos").transform.origin.y
			$Timers/EquipTimer.start()
			transitioning_between_weapons = true
			showWeapon(new_weapon)
			current_weapon = "Shotgun"
			updateAmmoHud()

func _on_EquipTimer_timeout():
	transitioning_between_weapons = false
	if current_weapon == "Shotgun":
		$Shotgun.transform.origin.y = get_node("../HoldingPos").transform.origin.y
	elif current_weapon == "Pistol":
		$Gun.transform.origin.y = get_node("../HoldingPos").transform.origin.y


func interpolate_weapon_equip(delta):
	if current_weapon == "Shotgun":
		$Shotgun.transform.origin.y = lerp(get_node("../EquipPos").transform.origin.y,get_node("../HoldingPos").transform.origin.y,5*(0.2-$Timers/EquipTimer.time_left))
	elif current_weapon == "Pistol":
		$Gun.transform.origin.y = lerp(get_node("../EquipPos").transform.origin.y,get_node("../HoldingPos").transform.origin.y,5*(0.2-$Timers/EquipTimer.time_left))

func gunHandler(action,animation="Idle"):
	if action == "Shoot":
		if current_weapon == "Pistol":
			shootPistol()
		elif current_weapon == "Shotgun":
			shootShotgun()
	elif action == "Reload":
		if current_weapon == "Pistol":
			reloadPistol()
		elif current_weapon == "Shotgun":
			reloadShotgun()
	

func get_keyboard_input():
	if(Input.is_key_pressed(KEY_R)):
		gunHandler("Reload")
	if(Input.is_action_just_pressed("ui_1")):
		switchWeapons("Pistol")
	if(Input.is_action_just_pressed("ui_2")):
		switchWeapons("Shotgun")

# Called when the node enters the scene tree for the first time.
func _ready():
	switchWeapons("Pistol")
	$Shotgun.hide()
	updateAmmoHud()

func _physics_process(delta):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		if health > 0 and guns_enabled == true:
			show()
			if transitioning_between_weapons == false:
				get_keyboard_input()
			play_walk_anim = false
			if movement.x != 0 or movement.z != 0:
				play_walk_anim = true
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				if transitioning_between_weapons == false:
					gunHandler("Shoot")
			elif play_walk_anim:
				animationHandler("Running")
			elif $"../../../".air_time > 0.1:
				animationHandler("Running")
			else:
				animationHandler("Idle")
			if transitioning_between_weapons == true:
				interpolate_weapon_equip(delta)
		else:
			hide()



