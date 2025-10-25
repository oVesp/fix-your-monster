-- Server: MonsterDataHandler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvents
local GetMonsterDataEvent = Instance.new("RemoteEvent")
GetMonsterDataEvent.Name = "GetMonsterData"
GetMonsterDataEvent.Parent = ReplicatedStorage

-- Handle data requests
GetMonsterDataEvent.OnServerEvent:Connect(function(player)
	local Data = _G.DATA
	local MovesModule = require(ReplicatedStorage.Modules.Moves)

	local success, monsterData = pcall(function()
		return Data:Get(player)
	end)

	if success and monsterData then
		-- Convert proxy data to a simple table for client
		local dataTable = {}

		-- Direct property access
		dataTable.id = monsterData.id
		dataTable.Name = monsterData.Name
		dataTable.Race = monsterData.Race
		dataTable.Stage = monsterData.Stage
		dataTable.Level = monsterData.Level
		dataTable.BaseRaceFamily = monsterData.BaseRaceFamily
		dataTable.Bond = monsterData.Bond
		dataTable.Wins = monsterData.Wins
		dataTable.SessionTime = monsterData.SessionTime
		dataTable.CareMistakes = monsterData.CareMistakes
		dataTable.Personality = monsterData.Personality

		-- Stats - handle both full names and abbreviations
		dataTable.Stats = {}
		if monsterData.Stats then
			dataTable.Stats.Hp = monsterData.Stats.Hp or 100
			dataTable.Stats.Mp = monsterData.Stats.Mp or 100
			dataTable.Stats.Strength = monsterData.Stats.Strength or monsterData.Stats.STR or 10
			dataTable.Stats.Defense = monsterData.Stats.Defense or monsterData.Stats.DEF or 10
			dataTable.Stats.Skill = monsterData.Stats.Skill or monsterData.Stats.SKL or 10
			dataTable.Stats.Speed = monsterData.Stats.Speed or monsterData.Stats.SPD or 10
			dataTable.Stats.Intelligence = monsterData.Stats.Intelligence or monsterData.Stats.INT or 10
			dataTable.Stats.Luck = monsterData.Stats.Luck or monsterData.Stats.LCK or 10
		else
			-- Default stats if none exist
			dataTable.Stats = {
				Hp = 100, Mp = 100,
				Strength = 10, Defense = 10, Skill = 10,
				Speed = 10, Intelligence = 10, Luck = 10
			}
		end

		-- Process moves with full move data from Moves module
		dataTable.Moves={}
		if monsterData.Moves then
			for i=1,#monsterData.Moves do
				local moveEntry=monsterData.Moves[i]
				if moveEntry and moveEntry.move then
					local moveId=moveEntry.move.id
					if moveId then
						-- VVV FIX: Changed to GetMove(nil, moveId)
						local fullMoveData=MovesModule:GetMove(nil, moveId) 
						if fullMoveData then
							dataTable.Moves[i]={move=fullMoveData,rarity=moveEntry.rarity or fullMoveData.rarity}
						else
							dataTable.Moves[i]={move={id=moveId,name=moveEntry.move.name or moveId,rarity=moveEntry.rarity or "Common"}}
						end
					end
				end
			end
		end

		-- Process learned moves
		dataTable.LearnedMoves={}
		if monsterData.LearnedMoves then
			for i=1,#monsterData.LearnedMoves do
				local moveEntry=monsterData.LearnedMoves[i]
				if moveEntry and moveEntry.move then
					local moveId=moveEntry.move.id
					if moveId then
						-- VVV FIX: Changed to GetMove(nil, moveId)
						local fullMoveData=MovesModule:GetMove(nil, moveId)
						if fullMoveData then
							dataTable.LearnedMoves[i]={move=fullMoveData,rarity=moveEntry.rarity or fullMoveData.rarity}
						else
							dataTable.LearnedMoves[i]={move={id=moveId,name=moveEntry.move.name or moveId,rarity=moveEntry.rarity or "Common"}}
						end
					end
				end
			end
		end

		GetMonsterDataEvent:FireClient(player, dataTable)
	else
		GetMonsterDataEvent:FireClient(player, nil)
		warn("Failed to get monster data for: " .. player.Name)
	end
end)