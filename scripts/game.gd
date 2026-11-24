extends Node
## Global game state: money, XP, items and plots. Saved to user://save.json.
## All timers use real clock time (unix seconds), so crops keep growing
## while the game is closed.

signal coins_changed(value: int)
signal gems_changed(value: int)
signal xp_changed(level: int, xp: int, needed: int)
signal leveled_up(level: int)
signal inventory_changed(item: String, amount: int)
signal plots_changed

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

var coins: int = Config.START_COINS
var gems: int = Config.START_GEMS
var level: int = Config.START_LEVEL
var xp: int = 0
var inventory: Dictionary = {}
## One entry per owned plot: {"crop": "" or crop id, "planted_at": unix time}
var plots: Array = []

var _autosave_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not load_game():
		_new_game()


func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= Config.AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()


static func now() -> float:
	return Time.get_unix_time_from_system()


func _new_game() -> void:
	coins = Config.START_COINS
	gems = Config.START_GEMS
	level = Config.START_LEVEL
	xp = 0
	inventory = {}
	plots = []
	for i in Config.START_PLOTS:
		plots.append({"crop": "", "planted_at": 0.0})


# ---------------- Money ----------------
func can_afford(amount: int) -> bool:
	return coins >= amount


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


func spend_gems(amount: int) -> bool:
	if gems < amount:
		return false
	gems -= amount
	gems_changed.emit(gems)
	return true


# ---------------- XP / levels ----------------
func xp_needed(for_level: int = level) -> int:
	var i := for_level - 1
	if i < Config.LEVEL_XP.size():
		return Config.LEVEL_XP[i]
	var last: int = Config.LEVEL_XP[Config.LEVEL_XP.size() - 1]
	return last + (i - Config.LEVEL_XP.size() + 1) * Config.LEVEL_XP_GROWTH


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(level, xp, xp_needed())


# ---------------- Items ----------------
func item_count(item: String) -> int:
	return inventory.get(item, 0)


func add_item(item: String, amount: int) -> void:
	inventory[item] = item_count(item) + amount
	inventory_changed.emit(item, inventory[item])


# ---------------- Plots ----------------
## 0 = empty, 1..stages = growing stage, stages+1 = ripe
func plot_stage(index: int) -> int:
	var p: Dictionary = plots[index]
	if p.crop == "":
		return 0
	var c: Dictionary = Config.CROPS[p.crop]
	var elapsed := now() - float(p.planted_at)
	return mini(int(elapsed / c.stage_time) + 1, c.stages + 1)


func plot_is_ripe(index: int) -> bool:
	var p: Dictionary = plots[index]
	return p.crop != "" and plot_stage(index) > Config.CROPS[p.crop].stages


func plot_time_left(index: int) -> float:
	var p: Dictionary = plots[index]
	if p.crop == "":
		return 0.0
	var c: Dictionary = Config.CROPS[p.crop]
	return maxf(0.0, float(p.planted_at) + c.stage_time * c.stages - now())


## Returns "" on success, otherwise a short error message for the player.
func plant(index: int, crop: String) -> String:
	if plots[index].crop != "":
		return "Already planted"
	var cost: int = Config.CROPS[crop].seed_cost
	if not spend_coins(cost):
		return "Not enough coins!"
	plots[index] = {"crop": crop, "planted_at": now()}
	plots_changed.emit()
	save_game()
	return ""


## Returns the amount harvested (0 if not ripe).
func harvest(index: int) -> int:
	if not plot_is_ripe(index):
		return 0
	var c: Dictionary = Config.CROPS[plots[index].crop]
	var crop: String = plots[index].crop
	plots[index] = {"crop": "", "planted_at": 0.0}
	add_item(crop, c.harvest_amount)
	add_xp(c.harvest_xp)
	plots_changed.emit()
	save_game()
	return c.harvest_amount


# ---------------- Save / load ----------------
func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"saved_at": now(),
		"coins": coins,
		"gems": gems,
		"level": level,
		"xp": xp,
		"inventory": inventory,
		"plots": plots,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != SAVE_VERSION:
		return false
	coins = int(data.get("coins", Config.START_COINS))
	gems = int(data.get("gems", Config.START_GEMS))
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	inventory = {}
	for k in data.get("inventory", {}):
		inventory[k] = int(data.inventory[k])
	plots = []
	for p in data.get("plots", []):
		plots.append({"crop": str(p.get("crop", "")), "planted_at": float(p.get("planted_at", 0.0))})
	while plots.size() < Config.START_PLOTS:
		plots.append({"crop": "", "planted_at": 0.0})
	return true


func reset_game() -> void:
	_new_game()
	save_game()
	coins_changed.emit(coins)
	gems_changed.emit(gems)
	xp_changed.emit(level, xp, xp_needed())
	plots_changed.emit()
