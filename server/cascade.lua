local ARCHIVE_LOANS <const> = [[
    UPDATE dealership_loans
    SET repossess_reason = IF(status = 'active', 'character deleted', repossess_reason),
        status = IF(status = 'active', 'repossessed', status),
        repossessed = 1,
        citizenid_archived = citizenid,
        citizenid = '__deleted__'
    WHERE citizenid = ?
]]

---@param citizenid string
---@param reason string?
local function archiveCharacterLoans(citizenid, reason)
    if type(citizenid) ~= 'string' or citizenid == '' then return end

    MySQL.update.await(ARCHIVE_LOANS, { citizenid })

    lib.print.info(('archived dealership loans for %s (%s)'):format(citizenid, reason or 'voluntary'))
end

AddEventHandler('cobalt_core:characterDeleting', archiveCharacterLoans)
