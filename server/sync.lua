local Vehicles <const> = require 'server.vehicles'

local Cobalt <const> = exports.cobalt_core:GetCoreObject()

local syncing = false

---@param source integer
---@param message string
---@param kind 'success'|'error'|'inform'
local function tell(source, message, kind)
    Cobalt.Functions.Notify(source, { title = 'Vehicle sync', description = message, type = kind })
end

---@param source integer
---@param reason string
local function sync(source, reason)
    if syncing then
        tell(source, 'A sync is already running.', 'error')
        return
    end

    syncing = true

    local ok <const>, scan <const> = pcall(lib.callback.await, 'cobalt_dealership:scanModels', source)

    syncing = false

    if not ok or type(scan) ~= 'table' or type(scan.models) ~= 'table' then
        tell(source, "Your game didn't send its model list. Try again.", 'error')
        return
    end

    local added <const> = Vehicles.merge(scan.models)
    local build <const> = math.tointeger(scan.build)

    if build then Vehicles.markSynced(build) end

    tell(source, ('%d new vehicles added to the vehicle list.'):format(#added), 'success')

    if #added == 0 then return end

    exports.cobalt_core:LogPlayer(source, 'dealership.sync', ('Added %d vehicles (%s)'):format(#added, reason), {
        build = build,
        models = added,
    })
end

Cobalt.Commands.Add('syncvehicles', 'Append new game vehicles to the dealership list', {}, false, function(source)
    if source <= 0 then return end

    CreateThread(function() sync(source, 'command') end)
end, 'admin')

Cobalt.Commands.Add('dealervehicle', 'Stop or resume selling a vehicle at dealerships', {
    { name = 'model', help = 'Spawn name, for example comet2' },
    { name = 'state', help = 'off or on' },
}, true, function(source, args)
    local model <const> = type(args[1]) == 'string' and args[1]:lower() or ''
    local enabled <const> = args[2] == 'on'

    if args[2] ~= 'on' and args[2] ~= 'off' then
        tell(source, 'Use /dealervehicle <model> off or on.', 'error')
        return
    end

    if not Vehicles.setEnabled(model, enabled) then
        tell(source, ('%s is not in the vehicle list.'):format(model), 'error')
        return
    end

    tell(source, ('%s is %s.'):format(model, enabled and 'for sale again' or 'no longer for sale'), 'success')

    local action <const> = enabled and 'Enabled' or 'Disabled'

    exports.cobalt_core:LogPlayer(source, 'dealership.vehicle', ('%s %s'):format(action, model), { model = model })
end, 'admin')

AddEventHandler('cobalt_core:Server:PlayerLoaded', function(player)
    local source <const> = player.PlayerData.source

    if not Cobalt.Functions.HasPermission(source, 'admin') then return end

    local ok <const>, build <const> = pcall(lib.callback.await, 'cobalt_dealership:gameBuild', source)

    if not ok or math.tointeger(build) == nil or build == Vehicles.syncedBuild() then return end

    sync(source, ('game build %d'):format(build))
end)
