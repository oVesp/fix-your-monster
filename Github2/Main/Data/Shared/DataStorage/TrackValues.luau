-- ModuleScript: ServerScriptService>Main>Data>Shared>DataStorage>TrackValues
local module = {}

local function custom_print(t, l, seen)
	l = l or 0
	seen = seen or {}
	if seen[t] then
		return '"*** cycle table reference detected ***"'
	end
	seen[t] = true
	local indent = string.rep(" ", l)
	local inner_indent = string.rep(" ", l + 1)
	local entries = {}

	local function format_value(v)
		if type(v) == "string" then
			return '"' .. v .. '"'
		elseif type(v) == "table" then
			return custom_print(v, l + 1, seen)
		end
		return tostring(v)
	end

	for k, v in pairs(t) do
		local key_str = type(k) == "string" and '["'..k..'"]' or "["..tostring(k).."]"
		local value_str = format_value(v)
		table.insert(entries, inner_indent .. key_str .. "=" .. value_str)
	end

	if #entries == 0 then
		return "{}"
	end
	return "{\n" .. table.concat(entries, "\n") .. "\n" .. indent .. "}"
end

local type_to_class = {
	boolean = 'BoolValue',
	string = 'StringValue',
	number = 'NumberValue',
}

function set_value(target: Instance, key: string, value: any)
	if not value then
		local existingChild = target:FindFirstChild(key)
		if existingChild then
			existingChild:Destroy()
		end
		return
	end

	local instance_class = type_to_class[typeof(value)]
	if not instance_class then
		return
	end

	local existingChild = target:FindFirstChild(key)
	if existingChild and existingChild.ClassName ~= instance_class then
		existingChild:Destroy()
		existingChild = nil
	end

	local new_value = existingChild or Instance.new(instance_class)
	new_value.Name = key
	new_value.Value = value
	new_value.Parent = target
end

function replicate(t: {any}, target: Instance, folder_name: string)
	local folder = Instance.new('Folder')
	folder.Name = folder_name
	folder.Parent = target

	for k, v in pairs(t) do
		if typeof(v) ~= 'table' then
			set_value(folder, k, v)
		end
	end

	return folder
end

-- FIX: Use iterative approach instead of recursion to avoid stack overflow
function convert_to_proxy(source: {any}, target: Instance?, folder_name: string)
	local folder = replicate(source, target, folder_name)
	local proxy = {}
	local source_ref = source

	-- Use iterative approach for nested tables
	local stack = {{source = source, proxy = proxy, folder = folder}}
	local processed_tables = {}
	processed_tables[source] = true

	while #stack > 0 do
		local current = table.remove(stack)
		local current_source = current.source
		local current_proxy = current.proxy
		local current_folder = current.folder

		for k, v in pairs(current_source) do
			if typeof(v) == 'table' and not processed_tables[v] then
				-- Create nested proxy and folder
				local nested_folder = replicate(v, current_folder, tostring(k))
				local nested_proxy = {}

				-- Set up metatable for nested proxy
				setmetatable(nested_proxy, {
					__stg = v,
					__index = function(self, nested_k)
						return v[nested_k]
					end,
					__newindex = function(self, nested_k, nested_v)
						if typeof(nested_v) ~= 'table' then
							set_value(nested_folder, nested_k, nested_v)
							v[nested_k] = nested_v
						else
							if nested_folder:FindFirstChild(nested_k) then
								nested_folder[nested_k]:Destroy()
							end
							v[nested_k] = convert_to_proxy(nested_v, nested_folder, nested_k)
						end
					end,
					__iter = function(self)
						return next, v
					end,
					__tostring = function(self)
						return custom_print(v)
					end,
				})

				current_proxy[k] = nested_proxy
				table.insert(stack, {source = v, proxy = nested_proxy, folder = nested_folder})
				processed_tables[v] = true
			else
				current_proxy[k] = v
			end
		end
	end

	-- Set up metatable for the main proxy
	setmetatable(proxy, {
		__stg = source_ref,
		__index = function(self, k)
			return source_ref[k]
		end,
		__newindex = function(self, k, v)
			if typeof(v) ~= 'table' then
				set_value(folder, k, v)
				source_ref[k] = v
			else
				if folder:FindFirstChild(k) then
					folder[k]:Destroy()
				end
				source_ref[k] = convert_to_proxy(v, folder, k)
			end
		end,
		__iter = function(self)
			return next, source_ref
		end,
		__tostring = function(self)
			return custom_print(source_ref)
		end,
	})

	return proxy
end

module.track = function(storage: {any}, replication_target: Instance)
	return convert_to_proxy(storage, replication_target, 'Data')
end

-- FIX: Improve normalize function to handle deep nesting
module.normalize = function(tracked: {any})
	if not getmetatable(tracked) then
		return tracked
	end

	local function deep_normalize(t)
		if not getmetatable(t) then
			if type(t) == "table" then
				local normalized = {}
				for k, v in pairs(t) do
					normalized[k] = deep_normalize(v)
				end
				return normalized
			end
			return t
		end

		local source_table = getmetatable(t).__stg
		if not source_table then
			return t
		end

		local normalized = {}
		for k, v in pairs(source_table) do
			normalized[k] = deep_normalize(v)
		end
		return normalized
	end

	return deep_normalize(tracked)
end

return module