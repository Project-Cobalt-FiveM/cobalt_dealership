local config <const> = require 'config'
local BUILD_KVP <const> = 'vehicles:gameBuild'

local CLASS_CATEGORIES <const> = {
    [0] = 'compacts', 'sedans', 'suvs', 'coupes', 'muscle', 'sportsclassic', 'sports', 'super', 'motorcycles',
    'offroad', 'industrial', 'utility', 'vans', 'cycles', 'boats', 'helicopters', 'planes', 'service',
    'emergency', 'military', 'commercial', 'trains', 'openwheel',
}

local CATEGORY_TYPES <const> = {
    motorcycles = 'bike',
    cycles = 'bike',
    boats = 'boat',
    helicopters = 'heli',
    planes = 'plane',
    trains = 'train',
}

local Vehicles <const> = {}

---@type table<string, SharedVehicle>
local entries = exports.cobalt_core:GetShared('Vehicles') or {}

---@class DealershipScannedModel
---@field model string
---@field class integer
---@field name string
---@field brand string

---@return table<string, SharedVehicle>
function Vehicles.all()
    return entries
end

---@param changes table<string, table>
---@return string[] changed
local function write(changes)
    local changed <const> = exports.cobalt_core:SetVehicles(changes)

    if #changed > 0 then entries = exports.cobalt_core:GetShared('Vehicles') or entries end

    return changed
end

---@param scanned unknown
---@return table?, string?
local function entryFrom(scanned)
    if type(scanned) ~= 'table' or type(scanned.model) ~= 'string' then return nil end

    local model <const> = scanned.model:lower()

    if not model:match('^[%w_%-]+$') or #model > 32 then return nil end

    local category <const> = CLASS_CATEGORIES[math.tointeger(scanned.class) or -1]

    if not category then return nil end

    local name <const> = type(scanned.name) == 'string' and scanned.name ~= '' and scanned.name:sub(1, 64) or model
    local brand <const> = type(scanned.brand) == 'string' and scanned.brand:sub(1, 32) or ''

    return {
        name = name,
        brand = brand,
        category = category,
        price = config.classPrices[category] or config.classPrices.default,
        type = CATEGORY_TYPES[category] or 'automobile',
    }, model
end

---@param scanned unknown[]
---@return string[] added
function Vehicles.merge(scanned)
    local additions <const> = {}

    for _, item in ipairs(scanned) do
        local entry <const>, model <const> = entryFrom(item)

        if entry and model and not entries[model] then additions[model] = entry end
    end

    return write(additions)
end

---@param model string
---@param enabled boolean
---@return boolean
function Vehicles.setEnabled(model, enabled)
    if not entries[model] then return false end

    return #write({ [model] = { enabled = enabled } }) == 1
end

---@return integer
function Vehicles.syncedBuild()
    return GetResourceKvpInt(BUILD_KVP)
end

---@param build integer
function Vehicles.markSynced(build)
    SetResourceKvpInt(BUILD_KVP, build)
end

return Vehicles
