---@param key string
---@return string
local function label(key)
    if key == '' then return '' end

    local text <const> = GetLabelText(key)

    if text == 'NULL' then return '' end

    return text
end

lib.callback.register('cobalt_dealership:gameBuild', function()
    return GetGameBuildNumber()
end)

lib.callback.register('cobalt_dealership:scanModels', function()
    local models <const> = {}

    for _, model in ipairs(GetAllVehicleModels()) do
        local hash <const> = joaat(model)

        models[#models + 1] = {
            model = model:lower(),
            class = GetVehicleClassFromName(hash),
            name = label(GetDisplayNameFromVehicleModel(hash)),
            brand = label(GetMakeNameFromVehicleModel(hash)),
        }
    end

    return { build = GetGameBuildNumber(), models = models }
end)
