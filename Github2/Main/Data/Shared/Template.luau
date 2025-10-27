-- Updated Data Structure (Template) for New Evolution System
return {
	id = "1",
	Name = "DefaultName",
	Race = "RealitySeed",
	Stage = "Fledgeling",
	Level = 1,
	NewPlayer = true,
	Version = "2.0.0", -- Matches .ENV version
	
	-- Evolution & Move Learning Fields
	BaseRaceFamily = "Progenitor",
	Bond = 0,
	Wins = 0,
	SessionTime = 0,
	CareMistakes = 0,
	Personality = "Balanced",

	-- Stats (with proper structure)
	Stats = {
		Hp = 25, 
		Mp = 50,
		Strength = 6,
		Defense = 6,
		Skill = 8,
		Speed = 10,
		Intelligence = 15,
		Luck = 10,
		-- Aliases for compatibility
		STR = 6, DEF = 6, SKL = 8, SPD = 10, INT = 15, LCK = 10, HP = 25, MP = 50
	},
	
	-- New Evolution System Fields
	IVs = {
		Hp = 0, Strength = 0, Defense = 0, Intelligence = 0, Speed = 0, Skill = 0
	},
	EVs = {
		Hp = 0, Strength = 0, Defense = 0, Intelligence = 0, Speed = 0, Skill = 0
	},
	GrowthAccum = {
		Hp = 0, Strength = 0, Defense = 0, Intelligence = 0, Speed = 0, Skill = 0
	},
	EvolutionAttempts = {}, -- Tracks evolution attempts per level

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

