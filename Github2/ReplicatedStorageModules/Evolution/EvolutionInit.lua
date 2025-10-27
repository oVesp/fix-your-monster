-- Evolution/EvolutionInit.lua
-- Initialization and migration helpers for evolution system data structures

local EvolutionInit = {}

-- ===== Dependencies =====
local MonsterForms
local StatCalc

pcall(function()
	MonsterForms = require(script.Parent.Data.MonsterForms)
end)

pcall(function()
	StatCalc = require(game.ReplicatedStorage.Modules.Stats.StatCalc)
end)

-- ===== Initialization Functions =====

-- Initialize IVs for a monster (if not already present)
function EvolutionInit.InitializeIVs(monster, seed)
	if not monster then return false end
	
	-- Skip if already has IVs
	if monster.IVs and next(monster.IVs) then
		return false
	end
	
	-- Generate new IVs
	if StatCalc and StatCalc.RollIVs then
		monster.IVs = StatCalc.RollIVs(monster.Race, seed)
		return true
	end
	
	-- Fallback: generate basic IVs
	monster.IVs = {
		Hp = math.random(0, 31),
		Strength = math.random(0, 31),
		Defense = math.random(0, 31),
		Intelligence = math.random(0, 31),
		Speed = math.random(0, 31),
		Skill = math.random(0, 31)
	}
	
	return true
end

-- Initialize EVs for a monster (if not already present)
function EvolutionInit.InitializeEVs(monster)
	if not monster then return false end
	
	-- Skip if already has EVs
	if monster.EVs and next(monster.EVs) then
		return false
	end
	
	-- Initialize empty EVs
	monster.EVs = {
		Hp = 0,
		Strength = 0,
		Defense = 0,
		Intelligence = 0,
		Speed = 0,
		Skill = 0
	}
	
	return true
end

-- Initialize growth accumulator for a monster (if not already present)
function EvolutionInit.InitializeGrowthAccum(monster)
	if not monster then return false end
	
	-- Skip if already has GrowthAccum
	if monster.GrowthAccum and next(monster.GrowthAccum) then
		return false
	end
	
	-- Initialize empty growth accumulator
	monster.GrowthAccum = {
		Hp = 0,
		Strength = 0,
		Defense = 0,
		Intelligence = 0,
		Speed = 0,
		Skill = 0
	}
	
	return true
end

-- Initialize evolution attempt tracking (if not already present)
function EvolutionInit.InitializeEvolutionAttempts(monster)
	if not monster then return false end
	
	-- Skip if already has EvolutionAttempts
	if monster.EvolutionAttempts then
		return false
	end
	
	-- Initialize empty evolution attempts
	monster.EvolutionAttempts = {}
	
	return true
end

-- Initialize all evolution-related data for a monster
function EvolutionInit.InitializeAll(monster, seed)
	if not monster then return false end
	
	local initialized = false
	
	if EvolutionInit.InitializeIVs(monster, seed) then
		initialized = true
	end
	
	if EvolutionInit.InitializeEVs(monster) then
		initialized = true
	end
	
	if EvolutionInit.InitializeGrowthAccum(monster) then
		initialized = true
	end
	
	if EvolutionInit.InitializeEvolutionAttempts(monster) then
		initialized = true
	end
	
	-- Initialize BaseRaceFamily if missing
	if not monster.BaseRaceFamily and monster.Race then
		local speciesData = MonsterForms and MonsterForms[monster.Race]
		if speciesData then
			monster.BaseRaceFamily = speciesData.baseFamily
			initialized = true
		end
	end
	
	-- Initialize Stage if missing
	if not monster.Stage and monster.Race then
		local speciesData = MonsterForms and MonsterForms[monster.Race]
		if speciesData then
			monster.Stage = speciesData.stage
			initialized = true
		end
	end
	
	return initialized
end

-- ===== Migration Functions =====

-- Migrate stats from old format to new format with IV/EV/Growth separation
function EvolutionInit.MigrateStats(monster)
	if not monster or not monster.Stats then return false end
	
	-- Check if already migrated (has IVs/EVs/GrowthAccum)
	if monster.IVs or monster.EVs or monster.GrowthAccum then
		return false
	end
	
	-- Initialize data structures
	EvolutionInit.InitializeAll(monster)
	
	-- Estimate growth accumulation from current stats and base stats
	if MonsterForms and monster.Race then
		local speciesData = MonsterForms[monster.Race]
		if speciesData and speciesData.baseStats then
			local level = monster.Level or 1
			
			for stat, baseValue in pairs(speciesData.baseStats) do
				local current = monster.Stats[stat] or baseValue
				local ivBonus = 0
				local evBonus = 0
				
				-- Get IV/EV bonuses
				if StatCalc then
					if monster.IVs and monster.IVs[stat] then
						ivBonus = StatCalc.GetIVBonus(monster.IVs[stat], level)
					end
					if monster.EVs and monster.EVs[stat] then
						evBonus = StatCalc.GetEVBonus(monster.EVs[stat], level)
					end
				end
				
				-- Estimate growth: current - base - IV - EV
				local estimatedGrowth = math.max(0, current - baseValue - ivBonus - evBonus)
				
				-- Store in GrowthAccum
				if monster.GrowthAccum then
					monster.GrowthAccum[stat] = estimatedGrowth
				end
			end
		end
	end
	
	return true
end

-- Migrate from old Races module format to new MonsterForms format
function EvolutionInit.MigrateFromRaces(monster)
	if not monster or not monster.Race then return false end
	
	local changed = false
	
	-- Update BaseRaceFamily if using old format
	if not monster.BaseRaceFamily then
		-- Try to get from new MonsterForms
		if MonsterForms then
			local speciesData = MonsterForms[monster.Race]
			if speciesData and speciesData.baseFamily then
				monster.BaseRaceFamily = speciesData.baseFamily
				changed = true
			end
		end
		
		-- Fallback to Races module
		if not monster.BaseRaceFamily then
			local ok, Races = pcall(function() 
				return require(game.ReplicatedStorage.Modules.Races) 
			end)
			if ok and Races and Races.GetBaseRaceFamily then
				local family = Races:GetBaseRaceFamily(monster.Race)
				if family then
					monster.BaseRaceFamily = family
					changed = true
				end
			end
		end
	end
	
	-- Update Stage if missing
	if not monster.Stage then
		-- Try to get from new MonsterForms
		if MonsterForms then
			local speciesData = MonsterForms[monster.Race]
			if speciesData and speciesData.stage then
				monster.Stage = speciesData.stage
				changed = true
			end
		end
		
		-- Fallback to Races module
		if not monster.Stage then
			local ok, Races = pcall(function() 
				return require(game.ReplicatedStorage.Modules.Races) 
			end)
			if ok and Races and Races.GetStage then
				local stage = Races:GetStage(monster.Race)
				if stage then
					monster.Stage = stage
					changed = true
				end
			end
		end
	end
	
	return changed
end

-- Full migration: convert old monster data to new format
function EvolutionInit.FullMigration(monster, seed)
	if not monster then return false end
	
	local changed = false
	
	-- 1. Initialize evolution data structures
	if EvolutionInit.InitializeAll(monster, seed) then
		changed = true
	end
	
	-- 2. Migrate stats
	if EvolutionInit.MigrateStats(monster) then
		changed = true
	end
	
	-- 3. Migrate from old Races format
	if EvolutionInit.MigrateFromRaces(monster) then
		changed = true
	end
	
	-- 4. Initialize History if missing
	if not monster.History then
		monster.History = { monster.Race }
		changed = true
	end
	
	if changed then
		print(string.format("[EvolutionInit] Migrated monster data for %s (Race: %s, Level: %d)", 
			tostring(monster.Name or "Unknown"), 
			tostring(monster.Race), 
			monster.Level or 1))
	end
	
	return changed
end

-- ===== Validation Functions =====

-- Validate monster data has all required fields for new system
function EvolutionInit.Validate(monster)
	if not monster then
		return false, { "Monster data is nil" }
	end
	
	local errors = {}
	
	-- Check required fields
	if not monster.Race then
		table.insert(errors, "Missing Race")
	end
	
	if not monster.Stats then
		table.insert(errors, "Missing Stats")
	end
	
	if not monster.Level then
		table.insert(errors, "Missing Level")
	end
	
	-- Check evolution system fields
	if not monster.IVs then
		table.insert(errors, "Missing IVs (use InitializeIVs)")
	end
	
	if not monster.EVs then
		table.insert(errors, "Missing EVs (use InitializeEVs)")
	end
	
	if not monster.GrowthAccum then
		table.insert(errors, "Missing GrowthAccum (use InitializeGrowthAccum)")
	end
	
	if not monster.EvolutionAttempts then
		table.insert(errors, "Missing EvolutionAttempts (use InitializeEvolutionAttempts)")
	end
	
	if not monster.BaseRaceFamily then
		table.insert(errors, "Missing BaseRaceFamily")
	end
	
	if not monster.Stage then
		table.insert(errors, "Missing Stage")
	end
	
	return #errors == 0, errors
end

-- ===== Utility Functions =====

-- Get seed for deterministic IV generation
function EvolutionInit.GetSeedFromUserId(userId, raceIndex)
	-- Generate deterministic seed from userId and race index
	raceIndex = raceIndex or 1
	return userId * 1000 + raceIndex
end

return EvolutionInit
