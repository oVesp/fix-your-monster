-- ReplicatedStorage/Modules/MoveVFX.lua
-- Mapeamento declarativo de VFX/SFX por estágio do move + fallbacks coerentes
-- Estágios: cast, travel, impact, endcast
-- Campos aceitos por estágio: effect (EmitterEffect), trail (Trail), sfxStart, sfxLoop, sfxHit, sfxEnd

local M = {}

-- Nome base por move → usado para compor os assets
-- (se você mudar o id do move, só ajuste aqui)
local NAME = {
	BasicAttack  = "BasicAttack",
	CosmicThread = "CosmicThread",
	Singularity  = "Singularity",
	VoidRay      = "VoidRay",
	WeavePulse   = "WeavePulse",
	PhotonJab    = "PhotonJab",
	StarUppercut = "StarUppercut",
	CoreBash     = "CoreBash",
	KineticSlam  = "KineticSlam",
}

-- Defaults (se um asset específico não existir)
local DEFAULTS = {
	castEffect   = "Cast_Default",     -- EmitterEffect
	impactEffect = "Impact_Default",   -- EmitterEffect
	sfxCast      = "Cast_Default",     -- SFX
	sfxImpact    = "Impact_Default",   -- SFX
	sfxEnd       = "End_Default",      -- SFX (se não existir no seu banco, pode deixar nil)
}

-- Tabela declarativa por move (só especifique o que foge do padrão)
-- Se o campo estiver ausente, o resolver monta pelos nomes convencionais (Cast_*, Impact_*, End_*)
local PACKS = {
	-- Melee simples (usa sparks leves)
	BasicAttack = {
		cast   = { effect = "Cast_BasicAttack"   },  -- sfxStart será Cast_BasicAttack
		impact = { effect = "Impact_BasicAttack" },  -- sfxHit   será Impact_BasicAttack
		endcast= { },                                 -- sfxEnd   será End_BasicAttack
	},

	CosmicThread = {
		cast   = { effect = "Cast_CosmicThread"  },
		-- travel: adicione quando tiver trilha dedicada (ex.: trail="Thread_Trail")
		impact = { effect = "Impact_CosmicThread"},
		endcast= { },
	},

	Singularity = {
		cast   = { effect = "Cast_Singularity"   },
		impact = { effect = "Impact_Singularity" },
		endcast= { },
	},

	VoidRay = {
		cast   = { effect = "Cast_VoidRay"       },
		-- opcional: travel = { trail = "Void_Beam" } -- se/quando você criar
		impact = { effect = "Impact_VoidRay"     },
		endcast= { },
	},

	WeavePulse = {
		cast   = { effect = "Cast_WeavePulse"    },
		impact = { effect = "Impact_WeavePulse"  },
	},

	PhotonJab = {
		cast   = { effect = "Cast_PhotonJab"     },
		impact = { effect = "Impact_PhotonJab"   },
	},

	StarUppercut = {
		cast   = { effect = "Cast_StarUppercut"  },
		impact = { effect = "Impact_StarUppercut"},
	},

	CoreBash = {
		cast   = { effect = "Cast_CoreBash"      },
		impact = { effect = "Impact_CoreBash"    },
	},

	KineticSlam = {
		cast   = { effect = "Cast_KineticSlam"   },
		impact = { effect = "Impact_KineticSlam" },
	},
}

-- ===== Resolver com composição automática de nomes e fallbacks =====

local function ensureStage(pkgStage, baseName)
	pkgStage = pkgStage or {}

	-- se não veio effect/trail/sfx, gerar pelos padrões
	-- EmitterEffect
	if pkgStage.effect == nil and pkgStage._noEffect ~= true then
		if pkgStage._stage == "cast" then
			pkgStage.effect = "Cast_" .. baseName
		elseif pkgStage._stage == "impact" then
			pkgStage.effect = "Impact_" .. baseName
		end
	end

	-- SFX
	if pkgStage._stage == "cast" and pkgStage.sfxStart == nil then
		pkgStage.sfxStart = "Cast_" .. baseName
	end
	if pkgStage._stage == "travel" and pkgStage.sfxLoop == nil then
		-- só define se você tiver loops; se não, pode deixar nil
		-- pkgStage.sfxLoop = "Travel_" .. baseName
	end
	if pkgStage._stage == "impact" and pkgStage.sfxHit == nil then
		pkgStage.sfxHit = "Impact_" .. baseName
	end
	if pkgStage._stage == "endcast" and pkgStage.sfxEnd == nil then
		pkgStage.sfxEnd = "End_" .. baseName
	end

	return pkgStage
end

-- checa existência superficial via Effects (opcional). Se não tiver, usa defaults.
local function applyFallbacks(stage)
	if not stage then return nil end

	-- fallback de VFX
	if stage.effect == nil and stage._stage == "cast" then
		stage.effect = DEFAULTS.castEffect
	elseif stage.effect == nil and stage._stage == "impact" then
		stage.effect = DEFAULTS.impactEffect
	end

	-- fallback de SFX
	if stage._stage == "cast" and stage.sfxStart == nil then
		stage.sfxStart = DEFAULTS.sfxCast
	elseif stage._stage == "impact" and stage.sfxHit == nil then
		stage.sfxHit = DEFAULTS.sfxImpact
	elseif stage._stage == "endcast" and stage.sfxEnd == nil then
		stage.sfxEnd = DEFAULTS.sfxEnd
	end

	return stage
end

local function buildResolved(moveId)
	local baseName = NAME[moveId] or moveId
	local src = PACKS[moveId] or {}

	-- marque estagio para o resolver saber o que compor
	local cast   = src.cast   and table.clone(src.cast)   or {}
	local travel = src.travel and table.clone(src.travel) or {}
	local impact = src.impact and table.clone(src.impact) or {}
	local endc   = src.endcast and table.clone(src.endcast) or {}

	cast._stage, travel._stage, impact._stage, endc._stage = "cast","travel","impact","endcast"

	cast   = ensureStage(cast,   baseName)
	travel = ensureStage(travel, baseName)
	impact = ensureStage(impact, baseName)
	endc   = ensureStage(endc,   baseName)

	cast   = applyFallbacks(cast)
	travel = next(travel) and travel or nil -- se estiver vazio, remove
	impact = applyFallbacks(impact)
	endc   = applyFallbacks(endc)

	return {
		cast   = cast,
		travel = travel,
		impact = impact,
		endcast= endc,
	}
end

-- API pública
function M.Resolve(moveId)
	return buildResolved(moveId)
end

return M
