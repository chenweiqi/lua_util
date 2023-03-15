# lua_util
lua common toolset


## dirty_check
Check whether there are any element changes in the lua table

### Instructions
#### A simple example

```lua
t = {}
table_util.dirty_check(t, "__dirty")
print(t.__dirty)  -- nil
t.id = 1
print(t.__dirty)  -- true
```

#### Another example, the element is also table
```lua
t = {{1},{2},{3}}
table_util.dirty_check(t, "__dirty")
print(t.__dirty)  -- nil
t[1][1] = 0
print(t.__dirty)  -- true
```

### Attention
After dirty_check, the table will be a `dirty table` (metatable), which supports three methods:
```lua
t = {}
table_util.dirty_check(t, "__dirty")
t "count"    -- Get the total number of internal data of the dirty table
t "collect"  -- Clear the garbage inside the dirty table. Frequent calls are not recommended. Actively call is not necessary
t "restore"  -- Restore the dirty table to a normal table. When this table is no longer used, it will be free in subsequent gc cycle
```

After the table changes to `dirty table`, attention:
* `pairs` traversal is not affected
* `\#` expression is not affected
* the keys or values of table must not be metatable
* gc may be affected. Referencing any element of `dirty table` will make it unable to be recycled, but it can be recovered by calling t "restore"
* `next` will be affected (use the following method)
```lua
-- next correct version:

local _next = next
next = function(t, k)
    local mt = getmetatable(t)
    if mt and mt.__pairs then
        local f, t1 = pairs(t)
        return f(t1, k)
    end
    return _next(t, k)
end
```
