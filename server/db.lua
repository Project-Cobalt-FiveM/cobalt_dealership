local DB <const> = {}

local INSERT_VEHICLE <const> = [[
    INSERT INTO player_vehicles
        (license, citizenid, vehicle, hash, mods, plate, fuel, engine, body, state, depotprice, drivingdistance, status)
    VALUES (?, ?, ?, ?, ?, ?, 100, 1000, 1000, 0, 0, 0, '[]')
]]

local INSERT_LOAN <const> = [[
    INSERT INTO dealership_loans
        (citizenid, vehicle, plate, principal, interest_rate, remaining, weekly_payment, term_weeks,
         next_payment_due)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 7 DAY))
]]

local DUE_LOANS <const> = [[
    SELECT id, citizenid, vehicle, plate, remaining, weekly_payment, term_weeks, payments_made,
        next_payment_due < DATE_SUB(NOW(), INTERVAL ? HOUR) AS overdue
    FROM dealership_loans
    WHERE status = 'active' AND next_payment_due <= NOW()
    ORDER BY next_payment_due
    LIMIT 100
]]

local RECORD_PAYMENT <const> = [[
    UPDATE dealership_loans
    SET remaining = ?, payments_made = ?, status = ?, next_payment_due = DATE_ADD(next_payment_due, INTERVAL 7 DAY)
    WHERE id = ? AND status = 'active' AND payments_made = ?
]]

local ACTIVE_LOANS <const> = "SELECT COUNT(*) FROM dealership_loans WHERE citizenid = ? AND status = 'active'"

local DELETE_FINANCED_VEHICLE <const> = 'DELETE FROM player_vehicles WHERE citizenid = ? AND plate = ?'

local MARK_REPOSSESSED <const> = [[
    UPDATE dealership_loans
    SET status = 'repossessed', repossessed = 1, repossess_reason = 'missed payment'
    WHERE id = ? AND status = 'active'
]]

---@class DealershipLoanTerms
---@field principal integer
---@field rate number
---@field totalOwed integer
---@field weeklyPayment integer
---@field termWeeks integer

---@class DealershipPurchase
---@field citizenid string
---@field license string
---@field model string
---@field plate string
---@field mods table
---@field loan? DealershipLoanTerms

---@class DealershipDueLoan
---@field id integer
---@field citizenid string
---@field vehicle string
---@field plate string
---@field remaining integer
---@field weekly_payment integer
---@field term_weeks integer
---@field payments_made integer
---@field overdue 0|1

---@param purchase DealershipPurchase
---@return boolean
function DB.registerPurchase(purchase)
    return MySQL.startTransaction(function(query)
        query(INSERT_VEHICLE, {
            purchase.license,
            purchase.citizenid,
            purchase.model,
            tostring(joaat(purchase.model)),
            json.encode(purchase.mods),
            purchase.plate,
        })

        local loan <const> = purchase.loan

        if not loan then return true end

        query(INSERT_LOAN, {
            purchase.citizenid,
            purchase.model,
            purchase.plate,
            loan.principal,
            loan.rate,
            loan.totalOwed,
            loan.weeklyPayment,
            loan.termWeeks,
        })

        return true
    end)
end

---@param citizenid string
---@return integer
function DB.activeLoans(citizenid)
    return MySQL.scalar.await(ACTIVE_LOANS, { citizenid }) or 0
end

---@param graceHours integer
---@return DealershipDueLoan[]
function DB.dueLoans(graceHours)
    return MySQL.query.await(DUE_LOANS, { graceHours }) or {}
end

---@param loan DealershipDueLoan
---@param remaining integer
---@return boolean
function DB.recordPayment(loan, remaining)
    local status <const> = remaining <= 0 and 'paid' or 'active'

    return MySQL.startTransaction(function(query)
        local updated <const> = query(RECORD_PAYMENT, {
            math.max(0, remaining),
            loan.payments_made + 1,
            status,
            loan.id,
            loan.payments_made,
        })

        return updated.affectedRows > 0
    end)
end

---@param loan DealershipDueLoan
---@return boolean
function DB.repossess(loan)
    return MySQL.startTransaction(function(query)
        if query(MARK_REPOSSESSED, { loan.id }).affectedRows == 0 then return false end

        query(DELETE_FINANCED_VEHICLE, { loan.citizenid, loan.plate })

        return true
    end)
end

return DB
