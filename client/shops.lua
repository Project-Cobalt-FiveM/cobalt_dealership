local config <const> = require 'config'
local Showroom <const> = require 'client.showroom'

local SHOP_RADIUS <const> = 5.0
local RADIAL_ID <const> = 'cobalt_dealership_radial'

local core <const> = exports.cobalt_core

local blips <const> = {}
local peds <const> = {}

---@param shop table
local function addBlip(shop)
    if not shop.blip?.sprite then return end

    local location <const> = shop.location
    local blip <const> = AddBlipForCoord(location.x, location.y, location.z)

    SetBlipSprite(blip, shop.blip.sprite)
    SetBlipColour(blip, shop.blip.color or 0)
    SetBlipScale(blip, shop.blip.scale or 0.7)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(shop.blip.label or shop.label)
    EndTextCommandSetBlipName(blip)

    blips[#blips + 1] = blip
end

---@param shop table
local function spawnClerk(shop)
    local location <const> = shop.location
    local hash <const> = joaat(shop.npc.model)

    lib.requestModel(hash)

    local heading <const> = shop.npc.heading or location.w
    local ped <const> = CreatePed(0, hash, location.x, location.y, location.z - 1.0, heading, false, true)

    SetModelAsNoLongerNeeded(hash)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    peds[#peds + 1] = ped
end

---@param shopId string
---@param shop table
local function addTarget(shopId, shop)
    local location <const> = shop.location

    exports.ox_target:addSphereZone({
        name = 'dealer_' .. shopId,
        coords = vec3(location.x, location.y, location.z),
        radius = SHOP_RADIUS,
        options = {
            {
                name = 'dealer_' .. shopId,
                label = 'Browse ' .. shop.label,
                icon = 'fas fa-car',
                canInteract = function() return not Showroom.isOpen() end,
                onSelect = function() CreateThread(function() Showroom.open(shopId) end) end,
            },
        },
    })
end

---@param shopId string
---@param shop table
local function addRadial(shopId, shop)
    local location <const> = shop.location

    lib.points.new({
        coords = vec3(location.x, location.y, location.z),
        distance = SHOP_RADIUS,
        onEnter = function()
            core:AddRadialItem({
                id = RADIAL_ID,
                label = shop.label,
                icon = 'car',
                onSelect = function() CreateThread(function() Showroom.open(shopId) end) end,
            })
        end,
        onExit = function()
            core:RemoveRadialItem(RADIAL_ID)
        end,
    })
end

CreateThread(function()
    for shopId, shop in pairs(config.dealerships) do
        addBlip(shop)

        if shop.npc then spawnClerk(shop) end
        if config.useOxRadial then addRadial(shopId, shop) end
    end

    lib.waitFor(function()
        if GetResourceState('ox_target') == 'started' then return true end
    end, 'ox_target did not start', 60000)

    for shopId, shop in pairs(config.dealerships) do addTarget(shopId, shop) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for _, blip in ipairs(blips) do RemoveBlip(blip) end

    for _, ped in ipairs(peds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
