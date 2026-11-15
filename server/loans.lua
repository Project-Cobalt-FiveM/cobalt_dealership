local config <const> = require 'config'
local DB <const> = require 'server.db'
local format <const> = require 'server.format'

local Cobalt <const> = exports.cobalt_core:GetCoreObject()

---@param citizenid string
---@param notification table
local function notifyOwner(citizenid, notification)
    local player <const> = Cobalt.Functions.GetPlayerByCitizenId(citizenid, true)

    if player then Cobalt.Functions.Notify(player.PlayerData.source, notification) end
end

---@param loan DealershipDueLoan
---@param amount integer
---@return boolean
local function charge(loan, amount)
    local payment <const> = loan.payments_made + 1
    local description <const> = ('Vehicle loan %s, payment %d of %d'):format(loan.plate, payment, loan.term_weeks)

    return exports.cobalt_banking:Withdraw(loan.citizenid, amount, {
        note = description,
        initiator = loan.citizenid,
    }) == true
end

---@param loan DealershipDueLoan
---@param amount integer
local function refund(loan, amount)
    exports.cobalt_banking:Deposit(loan.citizenid, amount, {
        note = 'Vehicle loan payment refund',
        initiator = loan.citizenid,
    })
end

---@param loan DealershipDueLoan
local function repossess(loan)
    if not DB.repossess(loan) then return end

    exports.cobalt_vehiclekeys:RemoveKeys(loan.plate)

    notifyOwner(loan.citizenid, {
        title = 'Vehicle repossessed',
        description = ('You missed a payment on %s, so the dealer took it back. Its keys no longer work.')
            :format(loan.plate),
        type = 'error',
    })

    exports.cobalt_core:Log('dealership.repossess', ('Repossessed %s (%s)'):format(loan.vehicle, loan.plate), {
        citizenid = loan.citizenid,
        plate = loan.plate,
        loanId = loan.id,
    })
end

---@param loan DealershipDueLoan
local function collect(loan)
    local amount <const> = math.min(loan.weekly_payment, loan.remaining)

    if not charge(loan, amount) then
        if loan.overdue == 1 then repossess(loan) end
        return
    end

    local remaining <const> = loan.remaining - amount

    if not DB.recordPayment(loan, remaining) then
        refund(loan, amount)
        return
    end

    notifyOwner(loan.citizenid, {
        title = remaining <= 0 and 'Loan paid off' or 'Loan payment taken',
        description = ('%s from your bank for %s. %d of %d payments made.')
            :format(format.money(amount), loan.plate, loan.payments_made + 1, loan.term_weeks),
        type = 'inform',
    })
end

local function collectDue()
    if not config.financeEnabled then return end

    local ok <const>, err <const> = pcall(function()
        for _, loan in ipairs(DB.dueLoans(config.financeGraceHours)) do collect(loan) end
    end)

    if ok then return end

    lib.print.error(err)
    exports.cobalt_core:Log('dealership.loans', 'Collecting loan payments failed', { error = tostring(err) }, 'error')
end

SetInterval(collectDue, config.financeCheckMinutes * 60000)
CreateThread(collectDue)
