local table_util = {}
local version = _VERSION and tonumber(_VERSION:match("5.*"))

-- author: chenweiqi 2021-11-22
-- check whether the table has changed
-- >= lua 5.2  (lua 5.1 __len is not available)
function table_util.dirty_check(root, dirty_flag, gc_threshold)
	dirty_flag = dirty_flag or "__dirty"
	gc_threshold = gc_threshold or 100
	assert(type(dirty_flag) == "string", "dirty_flag invalid")
	assert(type(gc_threshold) == "number" and gc_threshold >= 0, "gc_threshold invalid")
	assert(version>=5.2, "lua version >= 5.2")
	local dummy = {}
	local function assert_key(key)
		assert(type(key) ~= "table", "not support table key")
	end
	local g_set = {}
	local threshold = 0
	local function check_alive(t, alive)
		if type(t) ~= "table" or alive[t] then
			return
		end
		alive[t] = true
		for k, v in pairs(t) do
			check_alive(v, alive)
		end
	end
	local function gc_sweep()
		threshold = 0
		local alive = {}
		check_alive(root, alive)
		local all_cnt, del_cnt = 0,0
		for t in pairs(g_set) do
			all_cnt = all_cnt + 1
			if not alive[t] then
				g_set[t] = nil
				del_cnt = del_cnt + 1
			end
		end
		return all_cnt, del_cnt
	end
	local function check_table(t)
		if type(t) ~= "table" then
			return
		end
		local mt = getmetatable(t)
		assert(not mt or mt == dummy, "not support metatable")
		local tv = g_set[t]
		if not tv then
			local tv = {}
			for k, v in pairs(t) do
				assert_key(k)
				check_table(v)
				tv[k] = v
				rawset(t, k, nil) -- force trigger newindex
			end
			g_set[t] = tv
		end
		if not mt then
			setmetatable(t, dummy)
		end
	end
	dummy.__newindex = function(t, k, v)
		assert_key(k)
		if k ~= dirty_flag then
			g_set[root][dirty_flag] = true
			check_table(v)
		end
		local old = g_set[t][k]
		g_set[t][k] = v
		if type(old) == "table" then
			threshold = threshold + 1
			if threshold > gc_threshold then
				gc_sweep()
			end
		end
	end
	dummy.__index = function(t, k)
		assert_key(k)
		return g_set[t][k]
	end
	dummy.__pairs = function(t, k)
		return next, g_set[t], k
	end
	dummy.__len = function(t)
		return #g_set[t]
	end
	check_table(root)
	return gc_sweep
end


return table_util

