local config <const> = require 'config'
local Camera <const> = require 'client.camera'
local Preview <const> = require 'client.preview'

local Showroom <const> = {}

local isOpen = false

---@param data unknown
---@return string?
local function hexOf(data)
    return type(data) == 'string' and data:match('^#%x%x%x%x%x%x$') or nil
end

local function close()
    if not isOpen then return end

    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    Preview.hide()
    Camera.stop()
    Preview.leave(true)
    lib.callback.await('cobalt_dealership:leave', false)
    Preview.reveal()
end

---@param shopId string
function Showroom.open(shopId)
    if isOpen or not config.dealerships[shopId] then return end

    local catalogue <const> = lib.callback.await('cobalt_dealership:open', false, shopId)

    if not catalogue then return end

    isOpen = true
    Preview.enter()
    Camera.start()
    Preview.reveal()
    SendNUIMessage({ action = 'open', catalogue = catalogue })
    SetNuiFocus(true, true)
end

---@return boolean
function Showroom.isOpen()
    return isOpen
end

RegisterNUICallback('select', function(data, cb)
    cb(type(data?.model) == 'string' and Preview.show(data.model))
end)

RegisterNUICallback('paint', function(data, cb)
    local primary <const> = hexOf(data?.primary)

    if primary then Preview.paint(primary, hexOf(data.secondary)) end

    cb(true)
end)

RegisterNUICallback('plate', function(data, cb)
    if type(data?.text) == 'string' then Preview.plate(data.text:upper():sub(1, config.plate.maxLength)) end

    cb(true)
end)

RegisterNUICallback('checkPlate', function(data, cb)
    cb(lib.callback.await('cobalt_dealership:checkPlate', false, data?.text) or 'invalid')
end)

RegisterNUICallback('camera', function(data, cb)
    local amount <const> = tonumber(data?.amount) or 0

    if data?.kind == 'rotate' then
        Camera.rotate(amount)
    elseif data?.kind == 'zoom' then
        Camera.zoom(amount)
    elseif data?.kind == 'height' then
        Camera.raise(amount)
    end

    cb(true)
end)

---@param name 'buy'|'finance'
local function purchase(name)
    RegisterNUICallback(name, function(data, cb)
        local result <const> = lib.callback.await('cobalt_dealership:' .. name, false, data)
            or { ok = false, reason = 'failed' }

        cb(result)

        if result.ok then close() end
    end)
end

purchase('buy')
purchase('finance')

RegisterNUICallback('close', function(_, cb)
    cb(true)
    close()
end)

RegisterNetEvent('cobalt_dealership:close', close)

local function reset()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    Camera.stop()
    Preview.leave()
end

RegisterNetEvent('cobalt_core:Client:OnPlayerUnload', function()
    if isOpen then reset() end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not isOpen then return end

    reset()
    DoScreenFadeIn(0)
end)

return Showroom
