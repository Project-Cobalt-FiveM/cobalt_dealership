local format <const> = {}

---@param amount integer
---@return string
function format.money(amount)
    local digits <const> = tostring(math.floor(amount)):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')

    return '$' .. digits
end

return format
