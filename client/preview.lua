local config <const> = require 'config'

local Preview <const> = {}

local vehicle = nil
local returnCoords = nil
local showRequest = 0

---@param hex string
---@return integer, integer, integer
local function rgb(hex)
    local r <const>, g <const>, b <const> = hex:match('^#(%x%x)(%x%x)(%x%x)$')

    return tonumber(r, 16) or 0, tonumber(g, 16) or 0, tonumber(b, 16) or 0
end

local FADE_MS <const> = 250
local LOAD_TIMEOUT_MS <const> = 8000
local SCENE_RADIUS <const> = 50.0

local pinned = 0

---@param x number
---@param y number
---@param z number
local function placePed(x, y, z)
    SetEntityCoordsNoOffset(cache.ped, x, y, z, false, false, false)
end

---@param point vector4
local function loadShowroom(point)
    local deadline <const> = GetGameTimer() + LOAD_TIMEOUT_MS

    SetFocusPosAndVel(point.x, point.y, point.z, 0.0, 0.0, 0.0)
    NewLoadSceneStartSphere(point.x, point.y, point.z, SCENE_RADIUS, 0)
    RequestCollisionAtCoord(point.x, point.y, point.z)

    pcall(lib.waitFor, function()
        pinned = GetInteriorAtCoords(point.x, point.y, point.z)
        return pinned ~= 0 or nil
    end, nil, deadline - GetGameTimer())

    if pinned ~= 0 then
        PinInteriorInMemory(pinned)
        pcall(lib.waitFor, function() return IsInteriorReady(pinned) or nil end, nil, deadline - GetGameTimer())
    end

    pcall(lib.waitFor, function() return IsNewLoadSceneLoaded() or nil end, nil, deadline - GetGameTimer())
    NewLoadSceneStop()
    placePed(point.x, point.y, point.z)

    if pinned ~= 0 then RefreshInterior(pinned) end

    pcall(lib.waitFor, function() return HasCollisionLoadedAroundEntity(cache.ped) or nil end, nil, deadline - GetGameTimer())
end

function Preview.enter()
    local point <const> = config.previewPoint

    returnCoords = GetEntityCoords(cache.ped)

    DoScreenFadeOut(FADE_MS)
    Wait(FADE_MS)

    FreezeEntityPosition(cache.ped, true)
    SetEntityVisible(cache.ped, false, false)
    SetEntityCollision(cache.ped, false, false)
    placePed(point.x, point.y, point.z)

    loadShowroom(point)
end

function Preview.reveal()
    DoScreenFadeIn(FADE_MS)
end

function Preview.hide()
    DoScreenFadeOut(FADE_MS)
    Wait(FADE_MS)
end

function Preview.clear()
    if vehicle and DoesEntityExist(vehicle) then DeleteEntity(vehicle) end

    vehicle = nil
end

---@param settle? boolean
function Preview.leave(settle)
    Preview.clear()
    ClearFocus()

    if pinned ~= 0 then UnpinInterior(pinned) end

    pinned = 0

    if returnCoords then
        placePed(returnCoords.x, returnCoords.y, returnCoords.z)
    end

    SetEntityCollision(cache.ped, true, true)
    SetEntityVisible(cache.ped, true, true)

    if settle and returnCoords then
        RequestCollisionAtCoord(returnCoords.x, returnCoords.y, returnCoords.z)
        pcall(lib.waitFor, function() return HasCollisionLoadedAroundEntity(cache.ped) or nil end, nil, LOAD_TIMEOUT_MS)
    end

    FreezeEntityPosition(cache.ped, false)
    returnCoords = nil
end

---@return boolean
function Preview.active()
    return returnCoords ~= nil
end

---@param model string
---@return boolean
function Preview.show(model)
    local hash <const> = joaat(model)

    if not IsModelInCdimage(hash) then return false end

    showRequest += 1

    local request <const> = showRequest
    local loaded <const> = pcall(lib.requestModel, hash)

    if not loaded then return false end

    if request ~= showRequest or not Preview.active() then
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    Preview.clear()

    local point <const> = config.previewPoint

    vehicle = CreateVehicle(hash, point.x, point.y, point.z, point.w, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(vehicle)
    FreezeEntityPosition(vehicle, true)
    SetEntityInvincible(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)

    return true
end

---@param primary string
---@param secondary? string
function Preview.paint(primary, secondary)
    if not vehicle then return end

    SetVehicleCustomPrimaryColour(vehicle, rgb(primary))
    SetVehicleCustomSecondaryColour(vehicle, rgb(secondary or primary))
end

---@param text string
function Preview.plate(text)
    if not vehicle then return end

    SetVehicleNumberPlateText(vehicle, text)
end

return Preview
