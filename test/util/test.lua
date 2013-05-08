-- Utilities for tests

-----
-- bool= tables_equal( tbl1, tbl2 )
--
-- Returns 'true' if 'tbl1' covers all entries of 'tbl2' (with identical contents).
-- This means that 'tbl2' is a subset of 'tbl1' entries.
-- Modified from: http://lua-users.org/lists/lua-l/2003-04/msg00181.html
--
function tables_equal( tbl1, tbl2 )
    --
    for k,v in pairs(tbl2) do
        --
        if (tbl1[k] ~= v) then
            
            if ((type(tbl1[k])~="table") or (type(v)~="table")) then
                --
                return false    -- some entry didn't exist or was different!
            end
            
            -- Subtables need to be dived into (different refs doesn't mean
            -- different contents).
            --
            if (not tables_equal( tbl1[k], v )) then
                return false
            end
            
            -- go on...
        end
    end    
    
    return true     -- covered it all!
end

-- Turns the given graph into a human-readable string
function graph_to_string(graph)
  local rtn = "graph: {\n"
  for node, connections in pairs(graph.connections) do
    local blah = ""
    for c in pairs(connections) do
      blah = blah .. c .. ", "
    end
    rtn = rtn .. "\t" .. node .. ": " .. blah .. "\n"
  end
  rtn = rtn .. "}\n"
  return rtn
end
