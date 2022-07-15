# lua_util
lua common toolset


## dirty_check
检查 table 数据是否变化

### 用法说明
#### 一个简单的例子

```lua
t = {}
table_util.dirty_check(t, "__dirty")
print(t.__dirty)  -- nil
t.id = 1
print(t.__dirty)  -- true
```

#### 子项是 table 的例子
如果子项是 table ，修改这个子项 table ，同样可以检查到
```lua
t = {{1},{2},{3}}
table_util.dirty_check(t, "__dirty")
print(t.__dirty)  -- nil
t[1][1] = 0
print(t.__dirty)  -- true
```

### 特别说明
执行 dirty_check 后，table 会变成一个 `dirty table`（本质是 metatable），支持 3 个方法：
```lua
t = {}
table_util.dirty_check(t, "__dirty")
t "count"    -- 获取 dirty table 内部数据总数
t "collect"  -- 释放 dirty table 内部的垃圾缓存，不推荐频繁调用，可以不主动调用
t "restore"  -- 恢复为普通 table ，当这个 table 不再被使用时，在随后的 gc 中释放内存
```

table 变成 `dirty table` 后，注意：
* pairs 遍历不受影响
* \# 表达式不受影响
* 子项 k/v 不能是 metatable
* next 受影响 （改用后面的方式）
* gc 可能受影响。引用子项 table 会使 `dirty table` 无法被回收，但可通过调用 t "restore" 恢复

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
