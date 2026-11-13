local config <const> = require 'config'

local MIN_RADIUS <const> = 3.0
local MAX_RADIUS <const> = 12.0
local MIN_HEIGHT <const> = -1.0
local MAX_HEIGHT <const> = 3.0

local Camera <const> = {}

local handle = nil
local angle = 0.0
local height = 0.5
local radius = 6.0

local function place()
    if not handle then return end

    local point <const> = config.previewPoint
    local radians <const> = math.rad(angle)

    SetCamCoord(handle, point.x + radius * math.cos(radians), point.y + radius * math.sin(radians), point.z + height)
    PointCamAtCoord(handle, point.x, point.y, point.z + 0.5)
end

function Camera.start()
    if handle then return end

    angle = config.previewPoint.w + 180.0
    height = 0.5
    radius = 6.0

    handle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    place()
    SetCamActive(handle, true)
    RenderScriptCams(true, false, 0, true, false)
end

function Camera.stop()
    if not handle then return end

    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(handle, false)
    handle = nil
end

---@param dx number
function Camera.rotate(dx)
    angle -= dx
    place()
end

---@param direction number
function Camera.zoom(direction)
    radius = math.min(MAX_RADIUS, math.max(MIN_RADIUS, radius - direction * 0.5))
    place()
end

---@param delta number
function Camera.raise(delta)
    height = math.min(MAX_HEIGHT, math.max(MIN_HEIGHT, height + delta))
    place()
end

return Camera
