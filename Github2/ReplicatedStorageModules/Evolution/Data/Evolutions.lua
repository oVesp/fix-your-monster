-- Evolution/Data/Evolutions.lua
-- Declarative evolution edges with gates (requirements) and weights (probability functions)
-- All stats use 1-999 scale for consistency

local Evolutions = {
	-- ===== BEAST FAMILY EVOLUTIONS =====
	Hopling = {
		{
			target = "Pugilhare",
			requiredStage = "Rookie",
			gates = {
				minStats = { Skill = 50, Speed = 45 },
				minWins = 0,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = "default" -- Use default weight calculation
		}
	},
	
	Pugilhare = {
		{
			target = "Strikeron",
			requiredStage = "Champion",
			gates = {
				minStats = { Strength = 100, Skill = 90 },
				minWins = 6,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = "default"
		}
	},
	
	Strikeron = {
		{
			target = "Monarchare",
			requiredStage = "Elder",
			gates = {
				minStats = { Strength = 180, Skill = 160 },
				minWins = 12,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = "default"
		}
	},
	
	Monarchare = {
		{
			target = "SteelBoxer",
			requiredStage = "Unique",
			gates = {
				minStats = { Strength = 250, Skill = 220 },
				minWins = 20,
				minBond = 50,
				maxCareMistakes = nil
			},
			weights = function(ctx)
				-- Custom weight for Unique evolution: requires high bond
				local strStat = ctx.stats.Strength or 0
				local sklStat = ctx.stats.Skill or 0
				local bond = ctx.bond or 0
				
				-- Normalize stats (0-1 range based on requirements)
				local strScore = math.min(1, strStat / 250)
				local sklScore = math.min(1, sklStat / 220)
				local bondScore = math.min(1, bond / 100)
				
				-- Base chance from rareness (Unique = rare)
				local baseChance = 0.25
				
				-- Weighted score: emphasize bond for final evolution
				local avgScore = (0.3 * strScore + 0.3 * sklScore + 0.4 * bondScore)
				
				-- Family compatibility bonus (same family)
				local compatBonus = (ctx.baseRaceFamily == "Beast") and 0.15 or 0
				
				return math.min(1, baseChance + 0.5 * avgScore + compatBonus)
			end
		}
	},
	
	-- ===== CONSTRUCT FAMILY EVOLUTIONS =====
	Core = {
		{
			target = "Golem",
			requiredStage = "Rookie",
			gates = {
				minStats = { Defense = 60, Strength = 40 },
				minWins = 0,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = "default"
		}
	},
	
	Golem = {
		{
			target = "Titan",
			requiredStage = "Champion",
			gates = {
				minStats = { Defense = 120, Strength = 100 },
				minWins = 5,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = "default"
		}
	},
	
	Titan = {
		{
			target = "Colossus",
			requiredStage = "Elder",
			gates = {
				minStats = { Defense = 200, Hp = 180 },
				minWins = 10,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = "default"
		}
	},
	
	Colossus = {
		{
			target = "IronColoss",
			requiredStage = "Unique",
			gates = {
				minStats = { Defense = 280, Hp = 250 },
				minWins = 18,
				minBond = 60,
				maxCareMistakes = 3
			},
			weights = function(ctx)
				-- Custom weight for Unique evolution: requires care and bond
				local defStat = ctx.stats.Defense or 0
				local hpStat = ctx.stats.Hp or 0
				local bond = ctx.bond or 0
				local careMistakes = ctx.careMistakes or 0
				
				-- Normalize stats
				local defScore = math.min(1, defStat / 280)
				local hpScore = math.min(1, hpStat / 250)
				local bondScore = math.min(1, bond / 100)
				local careScore = math.max(0, 1 - (careMistakes / 6)) -- Penalty for mistakes
				
				local baseChance = 0.2 -- Rare evolution
				local avgScore = (0.35 * defScore + 0.25 * hpScore + 0.2 * bondScore + 0.2 * careScore)
				local compatBonus = (ctx.baseRaceFamily == "Construct") and 0.15 or 0
				
				return math.min(1, baseChance + 0.5 * avgScore + compatBonus)
			end
		}
	},
	
	-- ===== PROGENITOR FAMILY EVOLUTIONS =====
	RealitySeed = {
		{
			target = "CosmicWeaver",
			requiredStage = "Champion",
			gates = {
				minStats = { Intelligence = 70, Speed = 50 },
				minWins = 0,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = function(ctx)
				-- Skip Rookie stage - direct to Champion
				local intStat = ctx.stats.Intelligence or 0
				local spdStat = ctx.stats.Speed or 0
				
				local intScore = math.min(1, intStat / 70)
				local spdScore = math.min(1, spdStat / 50)
				
				local baseChance = 0.35 -- Higher base for skipping stage
				local avgScore = (0.6 * intScore + 0.4 * spdScore)
				local compatBonus = (ctx.baseRaceFamily == "Progenitor") and 0.1 or 0
				
				return math.min(1, baseChance + 0.45 * avgScore + compatBonus)
			end
		}
	},
	
	CosmicWeaver = {
		{
			target = "VoidWalker",
			requiredStage = "Elder",
			gates = {
				minStats = { Intelligence = 150, Speed = 90 },
				minWins = 8,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = function(ctx)
				-- Offensive path: emphasizes combat and intelligence
				local intStat = ctx.stats.Intelligence or 0
				local spdStat = ctx.stats.Speed or 0
				local wins = ctx.wins or 0
				
				local intScore = math.min(1, intStat / 150)
				local spdScore = math.min(1, spdStat / 90)
				local winsScore = math.min(1, wins / 20)
				
				local baseChance = 0.3
				local avgScore = (0.45 * intScore + 0.25 * spdScore + 0.3 * winsScore)
				local compatBonus = (ctx.baseRaceFamily == "Progenitor") and 0.12 or 0
				
				return math.min(1, baseChance + 0.5 * avgScore + compatBonus)
			end
		},
		{
			target = "Architect",
			requiredStage = "Elder",
			gates = {
				minStats = { Intelligence = 160, Defense = 100 },
				minWins = 0,
				minBond = 40,
				maxCareMistakes = nil
			},
			weights = function(ctx)
				-- Defensive path: emphasizes bond and intelligence
				local intStat = ctx.stats.Intelligence or 0
				local defStat = ctx.stats.Defense or 0
				local bond = ctx.bond or 0
				
				local intScore = math.min(1, intStat / 160)
				local defScore = math.min(1, defStat / 100)
				local bondScore = math.min(1, bond / 80)
				
				local baseChance = 0.28
				local avgScore = (0.5 * intScore + 0.25 * defScore + 0.25 * bondScore)
				local compatBonus = (ctx.baseRaceFamily == "Progenitor") and 0.12 or 0
				
				return math.min(1, baseChance + 0.5 * avgScore + compatBonus)
			end
		}
	},
	
	VoidWalker = {
		{
			target = "EntropicVoid",
			requiredStage = "Unique",
			gates = {
				minStats = { Strength = 200, Intelligence = 180 },
				minWins = 15,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = function(ctx)
				-- Aggressive unique path
				local strStat = ctx.stats.Strength or 0
				local intStat = ctx.stats.Intelligence or 0
				local wins = ctx.wins or 0
				
				local strScore = math.min(1, strStat / 200)
				local intScore = math.min(1, intStat / 180)
				local winsScore = math.min(1, wins / 30)
				
				local baseChance = 0.22
				local avgScore = (0.35 * strScore + 0.35 * intScore + 0.3 * winsScore)
				local compatBonus = (ctx.baseRaceFamily == "Progenitor") and 0.15 or 0
				
				return math.min(1, baseChance + 0.5 * avgScore + compatBonus)
			end
		}
	},
	
	Architect = {
		{
			target = "PrimeConcept",
			requiredStage = "Unique",
			gates = {
				minStats = { Intelligence = 220, Skill = 150 },
				minWins = 0,
				minBond = 70,
				maxCareMistakes = 2
			},
			weights = function(ctx)
				-- Support/strategic unique path
				local intStat = ctx.stats.Intelligence or 0
				local sklStat = ctx.stats.Skill or 0
				local bond = ctx.bond or 0
				local careMistakes = ctx.careMistakes or 0
				
				local intScore = math.min(1, intStat / 220)
				local sklScore = math.min(1, sklStat / 150)
				local bondScore = math.min(1, bond / 100)
				local careScore = math.max(0, 1 - (careMistakes / 4))
				
				local baseChance = 0.18
				local avgScore = (0.4 * intScore + 0.25 * sklScore + 0.2 * bondScore + 0.15 * careScore)
				local compatBonus = (ctx.baseRaceFamily == "Progenitor") and 0.15 or 0
				
				return math.min(1, baseChance + 0.5 * avgScore + compatBonus)
			end
		}
	},
	
	-- ===== RAPTOR FAMILY EVOLUTIONS =====
	Dino = {
		{
			target = "Beast",
			requiredStage = "Champion",
			gates = {
				minStats = { Strength = 110, Defense = 80 },
				minWins = 5,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = "default"
		}
	},
	
	Beast = {
		{
			target = "Dragon",
			requiredStage = "Elder",
			gates = {
				minStats = { Strength = 190, Intelligence = 120 },
				minWins = 10,
				minBond = 0,
				maxCareMistakes = nil
			},
			weights = "default"
		}
	},
	
	Dragon = {
		{
			target = "NetherDragon",
			requiredStage = "Unique",
			gates = {
				minStats = { Strength = 260, Intelligence = 200 },
				minWins = 18,
				minBond = 55,
				maxCareMistakes = nil
			},
			weights = function(ctx)
				-- Balanced unique evolution
				local strStat = ctx.stats.Strength or 0
				local intStat = ctx.stats.Intelligence or 0
				local bond = ctx.bond or 0
				
				local strScore = math.min(1, strStat / 260)
				local intScore = math.min(1, intStat / 200)
				local bondScore = math.min(1, bond / 100)
				
				local baseChance = 0.23
				local avgScore = (0.35 * strScore + 0.35 * intScore + 0.3 * bondScore)
				local compatBonus = (ctx.baseRaceFamily == "Raptor") and 0.15 or 0
				
				return math.min(1, baseChance + 0.5 * avgScore + compatBonus)
			end
		}
	}
}

return Evolutions
