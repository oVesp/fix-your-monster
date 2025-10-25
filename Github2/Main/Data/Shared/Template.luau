-- Updated Data Structure (Template)
return {
	id = "1",
	Name = "DefaultName",
	Race = "RealitySeed",
	Stage = "Fledgeling",
	Level = 1,
	NewPlayer = true,
	-- Evolution & Move Learning Fields
	BaseRaceFamily = "Progenitor",
	Bond = 0,
	Wins = 0,
	SessionTime = 0,
	CareMistakes = 0,
	Personality = "Unpredictable",

	-- Stats (with proper structure)
	Stats = {
		Hp = 100, 
		Mp = 100,
		Strength = 10, STR = 10,
		Defense = 10, DEF = 10,
		Skill = 10, SKL = 10,
		Speed = 10, SPD = 10,
		Intelligence = 10, INT = 10,
		Luck = 10, LCK = 10
	},

	-- Move System
	Moves = {
		{ move = { id = "BasicAttack", name = "Basic Attack", rarity = "Amateur" }, rarity = "Amateur" }
	},
	LearnedMoves = {},
	MoveProgress = {}, -- Tracks training progress for move unlocks

	-- History & Metadata
	History = {"RealitySeed"},
	Appearance = {}
}

