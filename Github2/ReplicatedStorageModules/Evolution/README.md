# Evolution & Unlock System

This is a centralized, modular evolution system for the monster game following Digimon/PoE-style branching and convergent evolution trees.

## Architecture

The system is organized into the following modules:

```
ReplicatedStorageModules/
├── Evolution/
│   ├── EvolutionTree.lua          # Core evolution API
│   ├── EvolutionInit.lua          # Data initialization and migration
│   ├── Data/
│   │   ├── MonsterForms.lua       # Species definitions (stats, growth, learnsets)
│   │   └── Evolutions.lua         # Evolution edges (gates, weights)
│   └── Tests/
│       └── EvolutionTreeTests.lua # Test suite
└── Stats/
    └── StatCalc.lua               # Stat calculation (IV/EV, growth, recalc)
```

## Core Concepts

### Species & Forms

Each monster species is defined in `MonsterForms.lua` with:
- **Base stats**: Starting values for Hp, Strength, Defense, Intelligence, Speed, Skill
- **Growth dice**: Dice notation for level-up gains (e.g., "d6", "d8+2")
- **Growth multipliers**: Species-specific stat multipliers
- **Learnset**: Moves learned at specific levels
- **Stage & Family**: Classification for evolution requirements

### Evolution System

Evolutions are defined as edges between species in `Evolutions.lua`:
- **Gates**: Hard requirements (min stats, wins, bond, care mistakes)
- **Weights**: Probability calculation (default or custom function)
- **Stage requirements**: Must match target species stage

### Stat System

Stats are calculated from multiple sources:
- **Base stats**: From species definition
- **IVs (Individual Values)**: 0-31 per stat, fixed per monster
- **EVs (Effort Values)**: 0-252 per stat, earned through training/combat
- **Growth accumulator**: Dice rolls accumulated over levels
- **Multipliers**: Species-specific growth multipliers

Formula: `Stat = (Base + IV_bonus + EV_bonus + Growth) * Multiplier`

### Evolution Attempt System

- **1 attempt per level**: Monsters can only attempt evolution once per level
- **Automatic reset**: Attempting flag resets when leveling up
- **Probability-based**: Success depends on meeting gates and rolling weight threshold

## API Reference

### EvolutionTree API

```lua
local EvolutionTree = require(game.ReplicatedStorage.Modules.Evolution.EvolutionTree)

-- Check if monster can evolve
local canEvolve = EvolutionTree.CanEvolve(monster)

-- Get all valid evolution options with weights
local options = EvolutionTree.GetEvolutionOptions(monster)
-- Returns: { {target, gatesOk, weight, meta}, ... }

-- Attempt evolution (rolls probability)
local result = EvolutionTree.AttemptEvolve(monster)
-- Returns: { ok, evolvedTo, failed, roll, successChance, dist }

-- Apply evolution effects
local result = EvolutionTree.ApplyEvolution(monster, targetSpecies)
-- Returns: { oldSpecies, newSpecies, deltas, newStats }

-- Check if gates are met
local ok, details = EvolutionTree.CheckGates(monster, gates)

-- Calculate evolution weight/probability
local weight = EvolutionTree.ComputeWeights(monster, option)
```

### StatCalc API

```lua
local StatCalc = require(game.ReplicatedStorage.Modules.Stats.StatCalc)

-- Generate IVs (deterministic with seed)
local ivs = StatCalc.RollIVs(species, seed)

-- Gain EVs from training/combat
StatCalc.GainEV(monster, "Strength", 10)

-- Clamp EVs to limits (252 per stat, 510 total)
StatCalc.ClampEVs(monster)

-- Roll level-up stat gains
local gains = StatCalc.RollLevelUpGains(monster, speciesData, seed)

-- Recalculate all stats
local newStats = StatCalc.RecalcStats(monster, speciesData)

-- Process full level-up (gains + recalc + clamp)
local gains, newStats = StatCalc.ProcessLevelUp(monster, speciesData, seed)
```

### EvolutionInit API

```lua
local EvolutionInit = require(game.ReplicatedStorage.Modules.Evolution.EvolutionInit)

-- Initialize all evolution data structures
EvolutionInit.InitializeAll(monster, seed)

-- Initialize specific components
EvolutionInit.InitializeIVs(monster, seed)
EvolutionInit.InitializeEVs(monster)
EvolutionInit.InitializeGrowthAccum(monster)

-- Migrate from old format
EvolutionInit.FullMigration(monster, seed)

-- Validate monster data
local ok, errors = EvolutionInit.Validate(monster)
```

## Integration with Existing Systems

### EvolutionManager

The existing `EvolutionManager.luau` has been updated to use the new centralized system:
- `TryEvolve()` now uses EvolutionTree API with fallback to old system
- `CompleteEvolution()` applies evolution via EvolutionTree.ApplyEvolution
- `ProcessLevelUp()` handles stat growth and move learning
- Automatic initialization on evolution attempt

### MonsterGenerator

The `BuildMonster()` function now automatically:
- Initializes IVs/EVs/GrowthAccum if missing
- Migrates old monster data to new format
- Ensures backward compatibility

## Monster Data Structure

```lua
{
    -- Core identity
    Race = "Hopling",
    Stage = "Fledgeling",
    BaseRaceFamily = "Beast",
    Level = 10,
    
    -- Stats
    Stats = { Hp = 100, Strength = 50, Defense = 40, Intelligence = 30, Speed = 60, Skill = 55 },
    
    -- Evolution system data
    IVs = { Hp = 15, Strength = 20, Defense = 10, Intelligence = 5, Speed = 25, Skill = 22 },
    EVs = { Hp = 0, Strength = 50, Defense = 20, Intelligence = 0, Speed = 30, Skill = 40 },
    GrowthAccum = { Hp = 50, Strength = 30, Defense = 25, Intelligence = 15, Speed = 40, Skill = 35 },
    EvolutionAttempts = { [10] = true }, -- Attempted at level 10
    
    -- Training & progression
    Bond = 50,
    Wins = 8,
    CareMistakes = 1,
    Personality = "Balanced",
    History = { "Hopling" },
    
    -- Moves
    Moves = { ... },
    LearnedMoves = { ... }
}
```

## Evolution Flow

### Level Up Flow

1. Monster gains XP and levels up
2. `EvolutionManager.ProcessLevelUp()` is called
3. Stats are rolled using growth dice
4. EVs are clamped
5. Stats are recalculated
6. Evolution attempt lock is reset
7. Level-based moves are unlocked

### Evolution Flow

1. User triggers evolution (manual, combat, or training)
2. `EvolutionManager.StartEvolution()` is called
3. Data is initialized if needed
4. `EvolutionTree.CanEvolve()` checks eligibility
5. `EvolutionTree.AttemptEvolve()` rolls probability
6. If successful, VFX plays for EFFECT_DURATION
7. `EvolutionManager.CompleteEvolution()` is called
8. `EvolutionTree.ApplyEvolution()` updates species and stats
9. Previous moves are preserved
10. New species learnset moves are added
11. Monster model is rebuilt and repositioned
12. Client is notified

## Weight Calculation

Default weight formula:
```
weight = baseChance + (α * statScore) + (β * compatBonus)
```

Where:
- `baseChance`: Rarity-based (0.25-0.5)
- `statScore`: Average of (current/required) for all stat gates
- `compatBonus`: +0.1 same family, -0.1 different family
- `α = 0.5`, `β = 0.15`

Custom weights can be defined as functions in `Evolutions.lua`.

## Testing

Run the test suite:
```lua
local EvolutionTreeTests = require(game.ReplicatedStorage.Modules.Evolution.Tests.EvolutionTreeTests)
local success = EvolutionTreeTests.RunAll()
```

## Migration from Old System

The system automatically migrates old monster data:
1. IVs are generated deterministically from userId
2. EVs are initialized to 0
3. GrowthAccum is estimated from current stats minus base stats
4. BaseRaceFamily and Stage are populated from species data
5. EvolutionAttempts is initialized as empty table

This ensures backward compatibility with existing save data.

## Adding New Species

1. Add species definition to `MonsterForms.lua`:
```lua
NewSpecies = {
    displayName = "New Species",
    stage = "Champion",
    baseFamily = "Beast",
    isSummonable = false,
    baseStats = { Hp = 120, Strength = 55, ... },
    growthDice = { Hp = "d10", Strength = "d8", ... },
    growthMult = { Hp = 1.2, Strength = 1.15, ... },
    learnset = {
        [20] = { "NewMove1" },
        [30] = { "NewMove2" }
    }
}
```

2. Add evolution edge to `Evolutions.lua`:
```lua
ParentSpecies = {
    {
        target = "NewSpecies",
        requiredStage = "Champion",
        gates = {
            minStats = { Strength = 100, Speed = 90 },
            minWins = 5
        },
        weights = "default" -- or custom function
    }
}
```

3. Test the evolution chain

## Performance Considerations

- All evolution calculations are deterministic with optional seeding
- Stats are recalculated on-demand (level up, evolution)
- Evolution tree lookups are O(1) via direct table access
- Weight calculations are pure functions with no side effects
- Migration is idempotent (safe to call multiple times)

## Security

- All evolution logic runs server-side
- Client only triggers requests and displays VFX
- Stats are calculated deterministically to prevent exploits
- Evolution attempts are tracked server-side to prevent spam

## Future Enhancements

- [ ] Cross-family convergent evolutions
- [ ] Evolution items system
- [ ] Branching paths based on training type
- [ ] Digivolution-style de-evolution
- [ ] Mega evolution temporary forms
- [ ] Evolution prerequisites (specific move unlocks)
- [ ] Evolution triggers from quests/events
