-- Evolution/Data/MonsterForms.lua
-- Declarative species/form definitions with base stats, growth patterns, and learnsets
-- All stats use 1-999 scale for consistency

local MonsterForms = {
	-- ===== BEAST FAMILY =====
	Hopling = {
		displayName = "Hopling",
		stage = "Fledgeling",
		baseFamily = "Beast",
		isSummonable = true,
		baseStats = { Hp = 30, Strength = 10, Defense = 8, Intelligence = 5, Speed = 12, Skill = 10 },
		growthDice = { Hp = "d6", Strength = "d4", Defense = "d4", Intelligence = "d3", Speed = "d6", Skill = "d6" },
		growthMult = { Hp = 1.0, Strength = 1.0, Defense = 1.0, Intelligence = 1.0, Speed = 1.0, Skill = 1.0 },
		learnset = {
			[3] = { "PhotonJab" },
			[7] = { "FeintDash" },
			[12] = { "GuardUp" }
		}
	},
	
	Pugilhare = {
		displayName = "Pugilhare",
		stage = "Rookie",
		baseFamily = "Beast",
		isSummonable = false,
		baseStats = { Hp = 60, Strength = 25, Defense = 18, Intelligence = 12, Speed = 28, Skill = 26 },
		growthDice = { Hp = "d8", Strength = "d6", Defense = "d5", Intelligence = "d4", Speed = "d8", Skill = "d8" },
		growthMult = { Hp = 1.1, Strength = 1.05, Defense = 1.0, Intelligence = 1.0, Speed = 1.1, Skill = 1.1 },
		learnset = {
			[15] = { "PhotonBarrage" },
			[20] = { "StarUppercut" },
			[28] = { "GuardBreak" }
		}
	},
	
	Strikeron = {
		displayName = "Strikeron",
		stage = "Champion",
		baseFamily = "Beast",
		isSummonable = false,
		baseStats = { Hp = 120, Strength = 55, Defense = 40, Intelligence = 28, Speed = 58, Skill = 55 },
		growthDice = { Hp = "d10", Strength = "d8", Defense = "d6", Intelligence = "d5", Speed = "d10", Skill = "d10" },
		growthMult = { Hp = 1.2, Strength = 1.15, Defense = 1.05, Intelligence = 1.0, Speed = 1.15, Skill = 1.15 },
		learnset = {
			[32] = { "GravityWell" },
			[40] = { "VoidStep" },
			[48] = { "TemporalRift" }
		}
	},
	
	Monarchare = {
		displayName = "Monarchare",
		stage = "Elder",
		baseFamily = "Beast",
		isSummonable = false,
		baseStats = { Hp = 200, Strength = 100, Defense = 75, Intelligence = 55, Speed = 105, Skill = 100 },
		growthDice = { Hp = "d12", Strength = "d10", Defense = "d8", Intelligence = "d6", Speed = "d12", Skill = "d12" },
		growthMult = { Hp = 1.3, Strength = 1.25, Defense = 1.1, Intelligence = 1.05, Speed = 1.25, Skill = 1.25 },
		learnset = {
			[55] = { "TemporalRift" },
			[65] = { "CelestialCombo" }
		}
	},
	
	SteelBoxer = {
		displayName = "Steel Boxer",
		stage = "Unique",
		baseFamily = "Beast",
		isSummonable = false,
		baseStats = { Hp = 280, Strength = 150, Defense = 110, Intelligence = 80, Speed = 145, Skill = 140 },
		growthDice = { Hp = "d12+2", Strength = "d12", Defense = "d10", Intelligence = "d8", Speed = "d12+2", Skill = "d12+2" },
		growthMult = { Hp = 1.4, Strength = 1.35, Defense = 1.2, Intelligence = 1.1, Speed = 1.35, Skill = 1.35 },
		learnset = {
			[70] = { "CelestialCombo" }
		}
	},
	
	-- ===== CONSTRUCT FAMILY =====
	Core = {
		displayName = "Core",
		stage = "Fledgeling",
		baseFamily = "Construct",
		isSummonable = true,
		baseStats = { Hp = 40, Strength = 12, Defense = 15, Intelligence = 8, Speed = 6, Skill = 8 },
		growthDice = { Hp = "d8", Strength = "d5", Defense = "d6", Intelligence = "d4", Speed = "d3", Skill = "d4" },
		growthMult = { Hp = 1.1, Strength = 1.0, Defense = 1.1, Intelligence = 1.0, Speed = 0.9, Skill = 1.0 },
		learnset = {
			[3] = { "CoreBash" },
			[8] = { "BasicAttack" }
		}
	},
	
	Golem = {
		displayName = "Golem",
		stage = "Rookie",
		baseFamily = "Construct",
		isSummonable = false,
		baseStats = { Hp = 80, Strength = 30, Defense = 38, Intelligence = 18, Speed = 14, Skill = 20 },
		growthDice = { Hp = "d10", Strength = "d7", Defense = "d8", Intelligence = "d5", Speed = "d4", Skill = "d6" },
		growthMult = { Hp = 1.2, Strength = 1.05, Defense = 1.2, Intelligence = 1.0, Speed = 0.9, Skill = 1.05 },
		learnset = {
			[16] = { "KineticSlam" },
			[22] = { "Overcrank" },
			[30] = { "NanoSwarm" }
		}
	},
	
	Titan = {
		displayName = "Titan",
		stage = "Champion",
		baseFamily = "Construct",
		isSummonable = false,
		baseStats = { Hp = 160, Strength = 65, Defense = 80, Intelligence = 40, Speed = 30, Skill = 45 },
		growthDice = { Hp = "d12", Strength = "d9", Defense = "d10", Intelligence = "d6", Speed = "d5", Skill = "d8" },
		growthMult = { Hp = 1.3, Strength = 1.1, Defense = 1.3, Intelligence = 1.05, Speed = 0.95, Skill = 1.1 },
		learnset = {
			[35] = { "Hyperdrive" },
			[42] = { "MagneticVortex" }
		}
	},
	
	Colossus = {
		displayName = "Colossus",
		stage = "Elder",
		baseFamily = "Construct",
		isSummonable = false,
		baseStats = { Hp = 280, Strength = 120, Defense = 150, Intelligence = 70, Speed = 50, Skill = 80 },
		growthDice = { Hp = "d12+4", Strength = "d10", Defense = "d12", Intelligence = "d8", Speed = "d6", Skill = "d10" },
		growthMult = { Hp = 1.5, Strength = 1.15, Defense = 1.4, Intelligence = 1.1, Speed = 1.0, Skill = 1.15 },
		learnset = {
			[50] = { "PlasmaDischarge" },
			[60] = { "QuantumSlip" }
		}
	},
	
	IronColoss = {
		displayName = "Iron Coloss",
		stage = "Unique",
		baseFamily = "Construct",
		isSummonable = false,
		baseStats = { Hp = 400, Strength = 180, Defense = 220, Intelligence = 100, Speed = 70, Skill = 120 },
		growthDice = { Hp = "d12+6", Strength = "d12", Defense = "d12+4", Intelligence = "d10", Speed = "d8", Skill = "d12" },
		growthMult = { Hp = 1.6, Strength = 1.25, Defense = 1.5, Intelligence = 1.15, Speed = 1.05, Skill = 1.2 },
		learnset = {
			[75] = { "QuantumSlip" }
		}
	},
	
	-- ===== PROGENITOR FAMILY =====
	RealitySeed = {
		displayName = "Reality Seed",
		stage = "Fledgeling",
		baseFamily = "Progenitor",
		isSummonable = true,
		baseStats = { Hp = 25, Strength = 6, Defense = 6, Intelligence = 15, Speed = 10, Skill = 8 },
		growthDice = { Hp = "d5", Strength = "d3", Defense = "d3", Intelligence = "d6", Speed = "d5", Skill = "d4" },
		growthMult = { Hp = 0.9, Strength = 0.9, Defense = 0.9, Intelligence = 1.2, Speed = 1.0, Skill = 1.0 },
		learnset = {
			[3] = { "WeavePulse" },
			[9] = { "CosmicThread" }
		}
	},
	
	CosmicWeaver = {
		displayName = "Cosmic Weaver",
		stage = "Champion",
		baseFamily = "Progenitor",
		isSummonable = false,
		baseStats = { Hp = 100, Strength = 30, Defense = 35, Intelligence = 90, Speed = 55, Skill = 50 },
		growthDice = { Hp = "d8", Strength = "d5", Defense = "d6", Intelligence = "d12", Speed = "d8", Skill = "d7" },
		growthMult = { Hp = 1.1, Strength = 1.0, Defense = 1.05, Intelligence = 1.4, Speed = 1.15, Skill = 1.1 },
		learnset = {
			[25] = { "VoidRay" },
			[32] = { "WarpLance" },
			[40] = { "Singularity" },
			[50] = { "GenesisBeam" }
		}
	},
	
	VoidWalker = {
		displayName = "Void Walker",
		stage = "Elder",
		baseFamily = "Progenitor",
		isSummonable = false,
		baseStats = { Hp = 180, Strength = 80, Defense = 70, Intelligence = 160, Speed = 100, Skill = 90 },
		growthDice = { Hp = "d10", Strength = "d8", Defense = "d8", Intelligence = "d12+4", Speed = "d10", Skill = "d10" },
		growthMult = { Hp = 1.2, Strength = 1.15, Defense = 1.1, Intelligence = 1.5, Speed = 1.25, Skill = 1.2 },
		learnset = {
			[55] = { "VoidStep" },
			[65] = { "RealityShift" }
		}
	},
	
	Architect = {
		displayName = "Architect",
		stage = "Elder",
		baseFamily = "Progenitor",
		isSummonable = false,
		baseStats = { Hp = 200, Strength = 60, Defense = 90, Intelligence = 180, Speed = 85, Skill = 110 },
		growthDice = { Hp = "d10+2", Strength = "d6", Defense = "d9", Intelligence = "d12+6", Speed = "d9", Skill = "d12" },
		growthMult = { Hp = 1.3, Strength = 1.05, Defense = 1.2, Intelligence = 1.6, Speed = 1.2, Skill = 1.3 },
		learnset = {
			[55] = { "ArchitectShield" },
			[62] = { "ChronoBreak" },
			[70] = { "GenesisBeam" }
		}
	},
	
	PrimeConcept = {
		displayName = "Prime Concept",
		stage = "Unique",
		baseFamily = "Progenitor",
		isSummonable = false,
		baseStats = { Hp = 280, Strength = 90, Defense = 130, Intelligence = 260, Speed = 120, Skill = 160 },
		growthDice = { Hp = "d12+2", Strength = "d8", Defense = "d10+2", Intelligence = "d12+10", Speed = "d12", Skill = "d12+4" },
		growthMult = { Hp = 1.4, Strength = 1.1, Defense = 1.3, Intelligence = 1.8, Speed = 1.3, Skill = 1.4 },
		learnset = {
			[75] = { "PrimeConceptOverload" },
			[80] = { "RealityShift" }
		}
	},
	
	EntropicVoid = {
		displayName = "Entropic Void",
		stage = "Unique",
		baseFamily = "Progenitor",
		isSummonable = false,
		baseStats = { Hp = 260, Strength = 140, Defense = 110, Intelligence = 240, Speed = 150, Skill = 140 },
		growthDice = { Hp = "d12", Strength = "d10+2", Defense = "d10", Intelligence = "d12+8", Speed = "d12+4", Skill = "d12+2" },
		growthMult = { Hp = 1.35, Strength = 1.3, Defense = 1.2, Intelligence = 1.7, Speed = 1.4, Skill = 1.35 },
		learnset = {
			[75] = { "RealityShift" },
			[82] = { "VoidWing" }
		}
	},
	
	-- ===== RAPTOR FAMILY =====
	Dino = {
		displayName = "Dino",
		stage = "Rookie",
		baseFamily = "Raptor",
		isSummonable = false,
		baseStats = { Hp = 70, Strength = 32, Defense = 22, Intelligence = 15, Speed = 28, Skill = 24 },
		growthDice = { Hp = "d9", Strength = "d7", Defense = "d5", Intelligence = "d4", Speed = "d7", Skill = "d6" },
		growthMult = { Hp = 1.15, Strength = 1.1, Defense = 1.0, Intelligence = 1.0, Speed = 1.1, Skill = 1.05 },
		learnset = {
			[14] = { "Crush" },
			[18] = { "Roar" },
			[25] = { "TailSwipe" }
		}
	},
	
	Beast = {
		displayName = "Beast",
		stage = "Champion",
		baseFamily = "Raptor",
		isSummonable = false,
		baseStats = { Hp = 140, Strength = 70, Defense = 50, Intelligence = 35, Speed = 60, Skill = 55 },
		growthDice = { Hp = "d11", Strength = "d9", Defense = "d7", Intelligence = "d5", Speed = "d9", Skill = "d8" },
		growthMult = { Hp = 1.25, Strength = 1.2, Defense = 1.1, Intelligence = 1.05, Speed = 1.15, Skill = 1.1 },
		learnset = {
			[30] = { "Pounce" },
			[38] = { "SavageClaw" },
			[45] = { "Intimidate" }
		}
	},
	
	Dragon = {
		displayName = "Dragon",
		stage = "Elder",
		baseFamily = "Raptor",
		isSummonable = false,
		baseStats = { Hp = 240, Strength = 130, Defense = 90, Intelligence = 110, Speed = 100, Skill = 95 },
		growthDice = { Hp = "d12+2", Strength = "d11", Defense = "d9", Intelligence = "d10", Speed = "d10", Skill = "d10" },
		growthMult = { Hp = 1.35, Strength = 1.3, Defense = 1.2, Intelligence = 1.25, Speed = 1.2, Skill = 1.15 },
		learnset = {
			[52] = { "FlameBreath" },
			[60] = { "WingBuffet" }
		}
	},
	
	NetherDragon = {
		displayName = "Nether Dragon",
		stage = "Unique",
		baseFamily = "Raptor",
		isSummonable = false,
		baseStats = { Hp = 340, Strength = 190, Defense = 140, Intelligence = 180, Speed = 145, Skill = 140 },
		growthDice = { Hp = "d12+4", Strength = "d12+2", Defense = "d11", Intelligence = "d12+2", Speed = "d12", Skill = "d11" },
		growthMult = { Hp = 1.45, Strength = 1.4, Defense = 1.3, Intelligence = 1.4, Speed = 1.3, Skill = 1.25 },
		learnset = {
			[70] = { "NetherFlame" },
			[78] = { "VoidWing" },
			[85] = { "AbyssRoar" }
		}
	}
}

return MonsterForms
