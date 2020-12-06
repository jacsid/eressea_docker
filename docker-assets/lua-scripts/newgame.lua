require("config")
require("eressea")
require("tools/build-e3")

-- script build-e3 calls functions in module eressea; but without module name
-- don't how to solve this; but is fully operational
free_game = eressea.free_game

-- first we have to create an empty game data file
-- reason: only when a game is loaded, the random seed is initialized correctly
eressea.free_game()
eressea.write_game(get_turn() .. ".dat")

-- load game data in order to seed initialized
eressea.free_game()
eressea.read_game(get_turn() .. ".dat")
local w = os.getenv("ERESSEA_MAP_WIDTH")
if not w then  
    w = 80
end
local h = os.getenv("ERESSEA_MAP_HEIGHT")
if not h then
    h = 40
end
local pl = plane.create(0, -w/2, -h/2, w+1, h+1)
build(pl)
fill(pl, w, h)

-- save new world
eressea.write_game(get_turn() .. ".dat")
