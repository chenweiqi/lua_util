local table_util = {}
local version = _VERSION and tonumber(_VERSION:match("5.*"))
assert(version>=5.2, "lua version >= 5.2")

-- author: chenweiqi 2021-11-22
-- check whether the table has changed
-- >= lua 5.2  (lua 5.1 __len is not available)
function table_util.dirty_check(root, dirty_flag, gc_threshold)
	dirty_flag = dirty_flag or "__dirty"
	gc_threshold = gc_threshold or 100
	assert(type(root) == "table", "not table")
	assert(type(dirty_flag) == "string", "dirty_flag invalid")
	assert(type(gc_threshold) == "number" and gc_threshold >= 0, "gc_threshold invalid")
	
	local dummy = {}
	local g_set = {}
	local threshold = 0
	local is_dirty

	local function assert_key(key)
		assert(type(key) ~= "table", "not support table key")
	end

	local function check_alive(t, alive)
		if type(t) ~= "table" or alive[t] then
			return
		end
		alive[t] = true
		for k, v in pairs(t) do
			check_alive(v, alive)
		end
	end

	local function restore(t)
		local mt = getmetatable(t)
		if not mt then return end
		assert(mt == dummy, "restore invalid metatable")
		setmetatable(t, nil)
		local gt = g_set[t]
		for k,v in pairs(gt) do
			if type(v) == "table" then
				restore(v)
			end
			rawset(t, k, v)
		end
		g_set[t] = nil
	end

	local function collect()
		if threshold == 0 then
			return 0
		end
		threshold = 0
		local alive = {}
		check_alive(root, alive)
		local cnt = 0
		for t in pairs(g_set) do
			if not alive[t] then
				restore(t)
				cnt = cnt + 1
			end
		end
		return cnt
	end

	local function count()
		local cnt = 0
		for _ in pairs(g_set) do
			cnt = cnt + 1
		end
		return cnt
	end

	local function check_table(t)
		if type(t) ~= "table" then
			return
		end
		local mt = getmetatable(t)
		assert(not mt or mt == dummy, "not support metatable")
		if g_set[t] then return end
		local tv = {}
		g_set[t] = tv
		for k, v in pairs(t) do
			assert_key(k)
			check_table(v)
			rawset(tv, k, v) -- move kv to g_set
			rawset(t, k, nil) -- force trigger newindex
		end
		setmetatable(t, dummy)
	end

	dummy.__newindex = function(t, k, v)
		if t == root and k == dirty_flag then
			if v and v ~= true then
				error(string.format("%s must be nil or true", dirty_flag))
			end
			is_dirty = v
			return
		end
		assert_key(k)
		local old = g_set[t][k]
		if old == v then return end
		is_dirty = true
		check_table(v)
		g_set[t][k] = v
		if type(old) == "table" then
			threshold = threshold + 1
			if threshold > gc_threshold then
				collect()
			end
		end
	end

	dummy.__index = function(t, k)
		if t == root and k == dirty_flag then
			return is_dirty
		end
		return g_set[t][k]
	end

	dummy.__pairs = function(t, k)
		return next, g_set[t], k
	end

	dummy.__len = function(t)
		return #g_set[t]
	end

	dummy.__call = function(t, option)
		if t ~= root then
			error('attempt to call a child table')
		end
		if option == "restore" then
			return restore(t)
		elseif option == "collect" then
			return collect()
		elseif option == "count" then
			return count()
		end
		error(string.format('invalid option %s', option))
	end

	check_table(root)
end

-- table clone, avoid to modify table reference
function table_util.clone(obj)
	local lookup_table = {}
	local function _clone(obj)
		if type(obj) ~= "table" then
			return obj
		end
		if lookup_table[obj] then
			return lookup_table[obj]
		end
		
		local new_table = {}
		lookup_table[obj] = new_table
		for key, val in pairs(obj) do
			new_table[_clone(key)] = _clone(val)
		end
		return new_table
	end
	return _clone(obj)
end


return table_util

