extends Node
## ALL game numbers live here. Change a value, save, and press Play.
## (Times are in seconds, prices in coins unless the name says "gems".)

# ---------- Starting values ----------
const START_COINS := 100
const START_GEMS := 5
const START_LEVEL := 1
const START_PLOTS := 3

# ---------- Crops ----------
# seed_cost: coins to plant one plot
# stage_time: seconds per growth stage
# stages: number of growth stages before it is ripe
# harvest_amount: items you get per plot
# harvest_xp: XP you get per harvest
const CROPS := {
	"wheat": {
		"name": "Wheat",
		"seed_cost": 5,
		"stage_time": 5.0,
		"stages": 3,
		"harvest_amount": 3,
		"harvest_xp": 1,
	},
}

# ---------- Plots ----------
const PLOT_BASE_PRICE := 20      # price of the 4th plot
const PLOT_PRICE_MULTIPLIER := 1.5 # each new plot costs 1.5x the previous one
const MAX_PLOTS := 12

# ---------- Levels ----------
# XP needed to go from level N to N+1 (index 0 = level 1).
# After the end of the list, each level needs LEVEL_XP_GROWTH more than the last.
const LEVEL_XP := [10, 25, 45, 70, 100, 140, 190, 250]
const LEVEL_XP_GROWTH := 60

# ---------- Camera ----------
const CAMERA_ZOOM_MIN := 9.0    # closest
const CAMERA_ZOOM_MAX := 28.0   # farthest
const CAMERA_ZOOM_START := 15.0
const CAMERA_PAN_LIMIT := 14.0  # how far you can drag away from the farm center

# ---------- Saving ----------
const AUTOSAVE_INTERVAL := 5.0
