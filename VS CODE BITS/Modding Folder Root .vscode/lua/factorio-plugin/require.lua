--##

---@param uri string @ The uri of file
---@param text string @ The content of file
---@param diffs Diff[] @ The diffs to add more diffs to
local function replace(uri, text, diffs)
  ---@type string|number
  for start, name, finish in text:gmatch("require%s*%(?%s*['\"]()(.-)()['\"]%s*%)?") do
    ---@type string
    local original_name = name
    -- if name has slashes, convert to a dotted path, because the
    -- extension currently does not find paths formatted differently
    if name:match("[\\/]") then
      name = name:gsub("%.lua$",""):gsub("[\\/]",".")
    end

    -- then convert the modname prefix, if any...
    ---@param match string
    ---@return string
    name = name:gsub("^__(.-)__", function(match)
      return match
    end)

    if name ~= original_name then
      diffs[#diffs+1] = {
        start  = start,
        finish = finish - 1,
        text = name,
      }
    end
  end
end

return {
  replace = replace,
}
