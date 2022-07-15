local table_util = require "table_util"

local tb = {1,2,3, {}}
table_util.dirty_check(tb, "__dirty", 100)
print(">> foreach table tb")
for k,v in pairs(tb) do
	print(k,v)
end

print()
print(">> check dirty")
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

print()
print(">> check gc")
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

print("count", tb "count")
print("collect", tb "collect")
print("count", tb "count")


print()
print(">> fix next")

print("next data", next(tb))

local _next = next
next = function(t, k)
    local mt = getmetatable(t)
    if mt and mt.__pairs then
        local f, t1 = pairs(t)
        return f(t1, k)
    end
    return _next(t, k)
end
print("next data", next(tb))



print()
print(">> check restore")
for k,v in pairs(tb) do
	print(k,v)
end
print("tb 4", tb[4])
print("restore", tb "restore")

for k,v in pairs(tb) do
	print(k,v)
end
for k,v in pairs(tb[4]) do
	print(k,v)
end
print("tb 4", tb[4])
