-- ServerScriptService > Main > Data > OnJoining.lua
local RP = game:GetService('ReplicatedStorage');
local queue_functions = require(script:WaitForChild('QueueFunctions'));

local CURRENT_UPDATE = 1
local module = {
	function(plr, data)
		-- THIS IS THE NEW PLAYER LOGIC
		if not data.Value.NewPlayer then return end
		data.Value.NewPlayer = false

		print("[OnJoining] New player detected, rolling starter monster.")
		local newMonster = _G.MONSTERGENERATOR.RollMonster(data.Value, plr.UserId, false, {})
		newMonster.Name = _G.UTILS.nameGenerator(newMonster.Race)

		-- Apply the rolled monster data to the player's data
		for key, value in pairs(newMonster) do
			data.Value[key] = value
		end
		print("Generated starter monster for " .. plr.Name .. ": " .. newMonster.Race)
	end,

	function(plr, data)
		local last_played = data.Value.LastUpdatePlayed
		if last_played and tonumber(last_played) >= CURRENT_UPDATE then return end
		data.Value.LastUpdatePlayed = tostring(CURRENT_UPDATE)
	end,

	function(plr, data)
		while not _G.DATA do task.wait(1) end
		data.Value.Version = _G.DATA.Template.Version
	end,

	function(plr, data)
		-- We REMOVED the "if not data.Value.Race" block from here.
		-- The monster roll is now handled by the NewPlayer check above.

		-- Connect the queue processor
		data.ProcessQueue:Connect(function(id, values_array)
			data:Remove(id)
			for _, pack in ipairs(values_array) do
				if not queue_functions[pack.key] then continue end
				queue_functions[pack.key](plr, pack.info)
			end
		end)
	end,
}
return module