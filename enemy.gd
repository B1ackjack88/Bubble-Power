extends Area2D
class_name Enemy

var invincible = false
var player
@export var weaponType : PackedScene

var playerAlive: bool = true
var weapon : Weapon
enum states {READY, APPROACH, RETREAT, PREPARE, RECOVER, PLAYER_DEAD}
var ai_state = states.READY
@export var enemyStats = {"health": 2,"moveSpeed": 250,"range": 800, "recoveryTime":2, "prepareTime":1}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignals.died.connect(_on_player_death)
	player = get_node("../Player")
	weapon = weaponType.instantiate()
	var modifier = StaticStats.regular_enemy_modifiers
	enemyStats["heath"] = enemyStats["health"] + modifier[Enums.ENT_STATS.HEALTH]
	enemyStats["moveSpeed"] = enemyStats["moveSpeed"] + modifier[Enums.ENT_STATS.MOVE_SPEED]
	add_child(weapon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move(delta)
	if Input.is_action_pressed("p1_shoot"):
		pass
		# debug_damage()a

func takeDamage(damage: float) -> void:
	if invincible:
		return
	invincible = true
	$invincibleDelay.start()
	enemyStats["health"] = enemyStats["health"] - damage
	if (enemyStats["health"] <= 0):
		die()
		
func die() -> void:
	GlobalSignals.enemyKilled.emit()
	queue_free()

func debug_damage() -> void:
	weapon.attack(Vector2(player.position.x - position.x, player.position.y - position.y))

func startPrepareTimer():
	if($prepareTime.is_stopped()):
		$prepareTime.start(enemyStats["prepareTime"])


func move(delta: float) -> void:
	match ai_state:
		states.READY:
			var player_location = Vector2(player.position.x - position.x, player.position.y - position.y)
			if player_location.length() < enemyStats["range"]/2:
				ai_state = states.RETREAT
				if($maxRetreatTime.is_stopped()):
					$maxRetreatTime.start()
			elif player_location.length() > enemyStats["range"]:
				ai_state = states.APPROACH
			else:
				ai_state = states.PREPARE
				startPrepareTimer()
		states.APPROACH:
			var direction = Vector2(player.position.x - position.x, player.position.y - position.y)
			direction = direction/direction.length()
			direction = direction * enemyStats["moveSpeed"] * delta
			position.x += direction.x
			position.y += direction.y
			var player_location = Vector2(player.position.x - position.x, player.position.y - position.y)
			if player_location.length() < enemyStats["range"]:
				ai_state = states.PREPARE
				startPrepareTimer()
		states.RETREAT:
			var direction = Vector2(player.position.x - position.x, player.position.y - position.y)
			direction = direction/direction.length()
			direction = direction * enemyStats["moveSpeed"] * delta * -1
			position.x += direction.x
			position.y += direction.y
			var player_location = Vector2(player.position.x - position.x, player.position.y - position.y)
			if player_location.length() > enemyStats["range"]:
				ai_state = states.APPROACH
			elif player_location.length() > enemyStats["range"]:
				ai_state = states.PREPARE
				startPrepareTimer()
	
func _on_invincible_delay_timeout() -> void:
	invincible = false


func _on_body_entered(body: Node2D) -> void:
	takeDamage(body.damage)
	body.collided()


func _on_recover_time_timeout() -> void:
	ai_state = states.READY


func _on_prepare_time_timeout() -> void:
	weapon.attack(Vector2(player.position.x - position.x, player.position.y - position.y))
	$recoverTime.start(enemyStats["recoveryTime"])


func _on_max_retreat_time_timeout() -> void:
	if ai_state == states.RETREAT:
		ai_state = states.PREPARE
		startPrepareTimer()

func _on_player_death() -> void:
	playerAlive = false
	ai_state = states.PLAYER_DEAD
	$prepareTime.stop()
	$recoverTime.stop()
	$maxRetreatTime.stop()
	
