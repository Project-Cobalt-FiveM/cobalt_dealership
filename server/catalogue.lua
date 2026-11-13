local config <const> = require 'config'
local Vehicles <const> = require 'server.vehicles'

local Catalogue <const> = {}

---@class DealershipVehicle
---@field model string
---@field name string
---@field brand string
---@field price integer
---@field category string
---@field type string
---@field image string

---@param shopId string
---@param shop table
---@param entry SharedVehicle
---@return boolean
local function soldAt(shopId, shop, entry)
    if entry.enabled == false then return false end
    if entry.shops and not lib.table.contains(entry.shops, shopId) then return false end

    return lib.table.contains(shop.categories, entry.category)
end

---@param shopId string
---@return DealershipVehicle[]
function Catalogue.vehicles(shopId)
    local shop <const> = config.dealerships[shopId]
    local list <const> = {}

    if not shop then return list end

    for model, entry in pairs(Vehicles.all()) do
        if soldAt(shopId, shop, entry) then
            list[#list + 1] = {
                model = model,
                name = entry.name,
                brand = entry.brand,
                price = entry.price,
                category = entry.category,
                type = entry.type,
                image = entry.image or config.imageUrl:format(model:lower()),
            }
        end
    end

    return list
end

---@param shopId string
---@param model string
---@return DealershipVehicle?
function Catalogue.find(shopId, model)
    for _, vehicle in ipairs(Catalogue.vehicles(shopId)) do
        if vehicle.model == model then return vehicle end
    end
end

---@param shopId string
---@param vehicles DealershipVehicle[]
---@return string[]
function Catalogue.categories(shopId, vehicles)
    local present <const> = {}
    local ordered <const> = {}

    for _, vehicle in ipairs(vehicles) do present[vehicle.category] = true end

    for _, category in ipairs(config.dealerships[shopId].categories) do
        if present[category] then ordered[#ordered + 1] = category end
    end

    return ordered
end

---@param value unknown
---@return string?
function Catalogue.normalisePlate(value)
    if type(value) ~= 'string' then return nil end

    local plate <const> = value:upper():gsub('%s+', '')

    if plate == '' or #plate > config.plate.maxLength then return nil end
    if not plate:match(config.plate.pattern) then return nil end

    return plate
end

return Catalogue
