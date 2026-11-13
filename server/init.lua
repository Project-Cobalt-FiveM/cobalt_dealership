local Sales <const> = require 'server.sales'

require 'server.loans'
require 'server.cascade'
require 'server.sync'

lib.callback.register('cobalt_dealership:open', Sales.open)
lib.callback.register('cobalt_dealership:checkPlate', Sales.checkPlate)
lib.callback.register('cobalt_dealership:buy', Sales.buy)
lib.callback.register('cobalt_dealership:finance', Sales.finance)

lib.callback.register('cobalt_dealership:leave', function(source)
    Sales.leave(source)
    return true
end)

AddEventHandler('playerDropped', function()
    Sales.drop(source)
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', Sales.unload)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then Sales.stopAll() end
end)
