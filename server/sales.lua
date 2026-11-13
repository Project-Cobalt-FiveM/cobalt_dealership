local config <const> = require 'config'
local DB <const> = require 'server.db'
local Catalogue <const> = require 'server.catalogue'
local format <const> = require 'server.format'

local Cobalt <const> = exports.cobalt_core:GetCoreObject()

local NEAR_SHOP <const> = 15.0
local PREVIEW_RADIUS <const> = 10.0
local PREVIEW_GRACE_MS <const> = 5000
local WATCH_MS <const> = 2000

local Sales <const> = {}

---@alias DealershipFailure 'unavailable'|'funds'|'plate'|'account'|'loans'|'failed'

---@alias DealershipResult { ok: true, plate: string }|{ ok: false, reason: DealershipFailure }

---@class DealershipColour
---@field r integer
---@field g integer
---@field b integer

---@class DealershipDelivery
---@field type string
---@field plate string

---@class DealershipSession
---@field shopId string
---@field origin vector3
---@field openedAt integer
---@field delivery? DealershipDelivery
---@field busy? true
---@field leaving? true
---@field dropped? true the buyer left the server while a checkout was still saving

---@class DealershipOrder
---@field vehicle DealershipVehicle
---@field primary DealershipColour
---@field secondary? DealershipColour
---@field plate string
---@field randomPlate boolean
---@field price integer

---@type table<integer, DealershipSession>
local sessions <const> = {}

---@param value unknown
---@return DealershipColour?
local function parseColour(value)
    if type(value) ~= 'string' then return nil end

    local r <const>, g <const>, b <const> = value:match('^#(%x%x)(%x%x)(%x%x)$')

    if not r then return nil end

    return { r = tonumber(r, 16), g = tonumber(g, 16), b = tonumber(b, 16) }
end

---@param colour DealershipColour
---@return integer[]
local function rgb(colour)
    return { colour.r, colour.g, colour.b }
end

---@param source integer
---@param shopId string
---@return boolean
local function nearShop(source, shopId)
    local location <const> = config.dealerships[shopId].location
    local coords <const> = GetEntityCoords(GetPlayerPed(source))

    return #(coords - vec3(location.x, location.y, location.z)) <= NEAR_SHOP
end

---@param session DealershipSession
---@param data unknown
---@return DealershipOrder|DealershipFailure
local function readOrder(session, data)
    if type(data) ~= 'table' then return 'unavailable' end

    local vehicle <const> = type(data.model) == 'string' and Catalogue.find(session.shopId, data.model)
    local primary <const> = parseColour(data.primary)

    if not vehicle or not primary then return 'unavailable' end

    local secondary <const> = parseColour(data.secondary)

    if data.secondary ~= nil and not secondary then return 'unavailable' end

    local wantsPlate <const> = type(data.plate) == 'string' and data.plate ~= ''
    local requested <const> = wantsPlate and Catalogue.normalisePlate(data.plate) or nil

    if wantsPlate and not requested then return 'plate' end

    local taken <const> = requested ~= nil and exports.cobalt_core:GetVehicleOwnerByPlate(requested) ~= nil

    return {
        vehicle = vehicle,
        primary = primary,
        secondary = secondary,
        plate = (requested and not taken) and requested or exports.cobalt_core:GeneratePlate(),
        randomPlate = taken,
        price = vehicle.price + (secondary and config.secondaryColorPrice or 0),
    }
end

---@param source integer
---@param session DealershipSession
---@param order DealershipOrder
---@param loan? DealershipLoanTerms
---@return boolean
local function register(source, session, order, loan)
    local player <const> = Cobalt.Functions.GetPlayer(source)

    if not player then return false end

    local mods <const> = {
        plate = order.plate,
        color1 = rgb(order.primary),
        color2 = rgb(order.secondary or order.primary),
    }

    local registered <const> = DB.registerPurchase({
        citizenid = player.PlayerData.citizenid,
        license = player.PlayerData.license,
        model = order.vehicle.model,
        plate = order.plate,
        mods = mods,
        loan = loan,
    })

    if not registered then return false end

    session.delivery = { type = order.vehicle.type, plate = order.plate }

    return true
end

---@param source integer
---@param order DealershipOrder
local function notifyRandomPlate(source, order)
    if not order.randomPlate then return end

    Cobalt.Functions.Notify(source, {
        title = 'Plate was taken',
        description = ('Someone registered it first. Your %s got plate %s.'):format(order.vehicle.name, order.plate),
        type = 'inform',
    })
end

---@param source integer
---@return boolean
local function restrained(source)
    local ambulance <const> = GetResourceState('cobalt_ambulancejob') == 'started'
    local police <const> = GetResourceState('cobalt_police') == 'started'

    if ambulance and exports.cobalt_ambulancejob:GetDeathState(source) ~= 'alive' then return true end

    return police and exports.cobalt_police:IsCuffed(source)
end

---@param source integer
---@param shopId unknown
---@return table|false
function Sales.open(source, shopId)
    if sessions[source] then
        Sales.leave(source)
        return false
    end

    if type(shopId) ~= 'string' or not config.dealerships[shopId] then return false end
    if not nearShop(source, shopId) then return false end

    local player <const> = Cobalt.Functions.GetPlayer(source)

    if not player then return false end

    if restrained(source) then
        Cobalt.Functions.Notify(source, { description = 'The dealer won\'t serve you like this', type = 'error' })
        return false
    end

    sessions[source] = { shopId = shopId, origin = GetEntityCoords(GetPlayerPed(source)), openedAt = GetGameTimer() }
    exports.cobalt_core:SetPlayerBucket(source, source)

    local vehicles <const> = Catalogue.vehicles(shopId)

    return {
        shop = { id = shopId, label = config.dealerships[shopId].label },
        vehicles = vehicles,
        categories = Catalogue.categories(shopId, vehicles),
        money = {
            bank = player.Functions.GetMoney('bank') or 0,
            cash = player.Functions.GetMoney('cash') or 0,
        },
        secondaryColorPrice = config.secondaryColorPrice,
        plateMaxLength = config.plate.maxLength,
        finance = config.financeEnabled and {
            rate = config.financeInterestRate,
            termsWeeks = config.financeTermsWeeks,
        } or false,
    }
end

---@param source integer
---@param text unknown
---@return 'available'|'taken'|'invalid'
function Sales.checkPlate(source, text)
    if not sessions[source] then return 'invalid' end

    local plate <const> = Catalogue.normalisePlate(text)

    if not plate then return 'invalid' end

    return exports.cobalt_core:GetVehicleOwnerByPlate(plate) and 'taken' or 'available'
end

local PARK_UNDELIVERED <const> = 'UPDATE player_vehicles SET state = 1, garage = ? WHERE plate = ? AND state = 0'

---@param session DealershipSession
local function park(session)
    local delivery <const> = session.delivery

    if not delivery then return end

    MySQL.update.await(PARK_UNDELIVERED, { config.deliveryGarage, delivery.plate })
end

---@alias DealershipCheckout fun(source: integer, session: DealershipSession, data: unknown): DealershipResult

---@param source integer
---@param data unknown
---@param purchase DealershipCheckout
---@return DealershipResult
local function checkout(source, data, purchase)
    local session <const> = sessions[source]

    if not session or session.delivery or session.busy then
        return { ok = false, reason = 'unavailable' }
    end

    session.busy = true

    local ok <const>, result <const> = pcall(purchase, source, session, data)

    session.busy = nil

    if session.dropped then
        park(session)
    elseif session.leaving and sessions[source] == session then
        Sales.leave(source)
    end

    if not ok then
        exports.cobalt_core:Log('dealership.checkout', 'Checkout errored', { error = tostring(result) }, 'error')
        return { ok = false, reason = 'failed' }
    end

    return result
end

---@type DealershipCheckout
local function buy(source, session, data)
    local order <const> = readOrder(session, data)

    if type(order) == 'string' then
        return { ok = false, reason = order }
    end

    local player <const> = Cobalt.Functions.GetPlayer(source)

    if not player then
        return { ok = false, reason = 'failed' }
    end

    local bank <const> = player.Functions.GetMoney('bank') or 0
    local cash <const> = player.Functions.GetMoney('cash') or 0
    local account <const> = bank >= order.price and 'bank' or cash >= order.price and 'cash' or nil

    if not account then
        return { ok = false, reason = 'funds' }
    end

    if not player.Functions.RemoveMoney(account, order.price, 'vehicle-purchase') then
        return { ok = false, reason = 'funds' }
    end

    if not register(source, session, order) then
        player.Functions.AddMoney(account, order.price, 'vehicle-purchase-refund')
        return { ok = false, reason = 'failed' }
    end

    Cobalt.Functions.Notify(source, {
        title = 'Vehicle bought',
        description = ('%s %s, plate %s. %s from your %s. The keys are yours.')
            :format(order.vehicle.brand, order.vehicle.name, order.plate, format.money(order.price), account),
        type = 'success',
    })
    notifyRandomPlate(source, order)

    local summary <const> = ('Bought %s for %s'):format(order.vehicle.model, format.money(order.price))

    exports.cobalt_core:LogPlayer(source, 'dealership.purchase', summary, {
        model = order.vehicle.model,
        plate = order.plate,
        price = order.price,
        account = account,
    })

    return { ok = true, plate = order.plate }
end

---@type DealershipCheckout
local function finance(source, session, data)
    if not config.financeEnabled then
        return { ok = false, reason = 'unavailable' }
    end

    local termWeeks <const> = type(data) == 'table' and math.tointeger(data.termWeeks) or nil

    if not termWeeks or not lib.table.contains(config.financeTermsWeeks, termWeeks) then
        return { ok = false, reason = 'unavailable' }
    end

    local order <const> = readOrder(session, data)

    if type(order) == 'string' then
        return { ok = false, reason = order }
    end

    local citizenid <const> = Cobalt.Functions.GetPlayer(source).PlayerData.citizenid

    if not exports.cobalt_banking:GetAccount(citizenid) then
        return { ok = false, reason = 'account' }
    end

    if DB.activeLoans(citizenid) >= config.financeMaxLoans then
        return { ok = false, reason = 'loans' }
    end

    local totalOwed <const> = order.price + math.floor(order.price * config.financeInterestRate + 0.5)
    local weeklyPayment <const> = math.ceil(totalOwed / termWeeks)

    local loan <const> = {
        principal = order.price,
        rate = config.financeInterestRate,
        totalOwed = totalOwed,
        weeklyPayment = weeklyPayment,
        termWeeks = termWeeks,
    }

    if not register(source, session, order, loan) then
        return { ok = false, reason = 'failed' }
    end

    Cobalt.Functions.Notify(source, {
        title = 'Loan approved',
        description = ('%s %s is yours. %s a week for %d weeks. First payment in 7 days.')
            :format(order.vehicle.name, order.plate, format.money(weeklyPayment), termWeeks),
        type = 'success',
    })
    notifyRandomPlate(source, order)

    local summary <const> = ('Financed %s over %d weeks'):format(order.vehicle.model, termWeeks)

    exports.cobalt_core:LogPlayer(source, 'dealership.finance', summary, {
        model = order.vehicle.model,
        plate = order.plate,
        totalOwed = totalOwed,
        weeklyPayment = weeklyPayment,
    })

    return { ok = true, plate = order.plate }
end

---@param source integer
---@param data unknown
---@return DealershipResult
function Sales.buy(source, data)
    return checkout(source, data, buy)
end

---@param source integer
---@param data unknown
---@return DealershipResult
function Sales.finance(source, data)
    return checkout(source, data, finance)
end

---@param source integer
---@param session DealershipSession
local function deliver(source, session)
    local delivery <const> = session.delivery --[[@as DealershipDelivery]]
    local point <const> = config.dealerships[session.shopId].spawnPoint
    local garages <const> = GetResourceState('cobalt_garages') == 'started'

    if garages and exports.cobalt_garages:SpawnVehicle(source, delivery.plate, point, delivery.type) then return end

    park(session)

    Cobalt.Functions.Notify(source, {
        title = 'Delivery delayed',
        description = ("The lot couldn't bring your car round. Plate %s is parked in the city garage."):format(delivery.plate),
        type = 'error',
    })
end

---@param source integer
function Sales.leave(source)
    local session <const> = sessions[source]

    if not session then return end

    if session.busy then
        session.leaving = true
        return
    end

    sessions[source] = nil
    exports.cobalt_core:SetPlayerBucket(source, 0)

    if session.delivery then deliver(source, session) end
end

---@param source integer
function Sales.drop(source)
    local session <const> = sessions[source]

    sessions[source] = nil

    if not session then return end

    if session.busy then
        session.dropped = true
        return
    end

    park(session)
end

---@param source integer
function Sales.unload(source)
    if not sessions[source] then return end

    exports.cobalt_core:SetPlayerBucket(source, 0)
    Sales.drop(source)
end

function Sales.stopAll()
    for source, session in pairs(sessions) do
        exports.cobalt_core:SetPlayerBucket(source, 0)
        park(session)
    end

    table.wipe(sessions)
end

---@param source integer
---@param session DealershipSession
local function closeForTime(source, session)
    TriggerClientEvent('cobalt_dealership:close', source)
    Sales.leave(source)

    Cobalt.Functions.Notify(source, {
        title = 'Showroom closed',
        description = 'The dealer is closing up the showroom. Come back any time to keep browsing.',
        type = 'inform',
    })

    if session.delivery then return end

    local origin <const> = session.origin

    SetEntityCoords(GetPlayerPed(source), origin.x, origin.y, origin.z, false, false, false, false)
end

---@alias DealershipSessionEnd 'timeout' | 'away'

---@param session DealershipSession
---@param ped integer
---@param now integer
---@return DealershipSessionEnd?
local function sessionEnd(session, ped, now)
    local age <const> = now - session.openedAt

    if age > config.showroomMinutes * 60000 then return 'timeout' end
    if age < PREVIEW_GRACE_MS then return end

    local point <const> = config.previewPoint

    if #(GetEntityCoords(ped) - vec3(point.x, point.y, point.z)) > PREVIEW_RADIUS then return 'away' end
end

local function watchSessions()
    local now <const> = GetGameTimer()
    local ended <const> = {}

    for source, session in pairs(sessions) do
        local reason <const> = not session.busy and sessionEnd(session, GetPlayerPed(source), now)

        if reason then ended[source] = { session = session, reason = reason } end
    end

    for source, entry in pairs(ended) do
        if entry.reason == 'timeout' then
            closeForTime(source, entry.session)
        else
            Sales.leave(source)
        end
    end
end

SetInterval(watchSessions, WATCH_MS)

return Sales
