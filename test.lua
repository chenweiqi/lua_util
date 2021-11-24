local table_util = require "table_util"

local tb = {1,2,3, {}}
local gc_sweep = table_util.dirty_check(tb, "__dirty", 100)
print("foreach table tb")
for k,v in pairs(tb) do
	print(k,v)
end

print("table dirty 1", tb.__dirty)
tb[3]=1
print("table dirty 2", tb.__dirty)

tb.__dirty = nil
tb[3]=2
print("table dirty 3", tb.__dirty)

tb.__dirty = nil
local t={{},{},{},{},{}}
tb[4] = t
print("table dirty 4", tb.__dirty)


tb.__dirty = nil
t[3][1] = 1
print("table dirty 5", tb.__dirty)


tb.__dirty = nil
t[3][1] = 2
print("table dirty 6", tb.__dirty)


tb.__dirty = nil
t[3][2] = {}
print("table dirty 7", tb.__dirty)

-- check gc
tb.__dirty = nil
local tt = t[3][2]
tt[1] = {}
tt[1] = {}
tt[1] = {}
tt[1] = {}
tt[1] = {}
tt[1] = {}
tt[1] = {}
tt[1] = {}
tt[1] = {}
tt[1] = {}
print("table dirty 8", tb.__dirty)
tb.__dirty = nil

print("table dirty 9", #tb)

print("gc_sweep", gc_sweep())

for k,v in pairs(tb) do
	print(k,v)
end
print(tb[4])