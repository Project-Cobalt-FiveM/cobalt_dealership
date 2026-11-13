return {
    -- Showroom
    useOxRadial = false, -- also add an "open dealership" entry to the ox_lib radial menu near a dealer
    previewPoint = vec4(1219.25, -2280.94, -49.0, 180.67), -- where preview vehicles spawn, below the map and out of sight
    showroomMinutes = 15, -- minutes a player can browse before the showroom closes and returns them to the dealer
    deliveryGarage = 'legion_square', -- cobalt_garages garage id a bought car waits in when the buyer leaves the server before it is delivered
    secondaryColorPrice = 2000, -- dollars extra for a secondary colour

    -- Custom plates at purchase
    plate = {
        maxLength = 8, -- characters
        pattern = '^[A-Z0-9]+$', -- Lua pattern a custom plate must match once spaces are removed; other resources compare plates without spaces
    },

    -- Catalogue picture for each model; %s is the model name
    imageUrl = 'https://docs.fivem.net/vehicles/%s.webp',

    -- Price in dollars by vehicle class, for vehicles the catalogue scan adds without a set price
    classPrices = {
        default = 50000,
        compacts = 15000,
        sedans = 25000,
        suvs = 45000,
        coupes = 60000,
        muscle = 55000,
        sportsclassic = 150000,
        sports = 120000,
        super = 600000,
        motorcycles = 20000,
        offroad = 40000,
        industrial = 90000,
        utility = 60000,
        vans = 30000,
        cycles = 1000,
        boats = 80000,
        helicopters = 900000,
        planes = 1200000,
        service = 70000,
        emergency = 100000,
        military = 2000000,
        commercial = 120000,
        trains = 5000000,
        openwheel = 1500000,
    },

    -- Financing
    financeEnabled = true, -- offer loans at checkout
    financeInterestRate = 0.05, -- interest added to the loan, 0.05 is 5 percent
    financeTermsWeeks = { 4 }, -- loan lengths offered, in weeks
    financeMaxLoans = 2, -- loans one character can have open at once; paid-off and repossessed loans don't count
    financeGraceHours = 24, -- hours past a due payment before it is collected
    financeCheckMinutes = 5, -- minutes between checks for due payments

    -- Dealerships: blip, dealer position, where bought vehicles spawn, the dealer ped, and the classes sold
    dealerships = {
        pdm = {
            label = 'Premium Deluxe Motorsport', -- dealership name in the catalogue
            blip = { sprite = 326, color = 3, scale = 0.7, label = 'Car Dealer' }, -- map blip sprite, colour, size and name
            location = vec4(-56.71, -1098.78, 26.42, 19.39), -- where the dealer stands and players open the catalogue
            spawnPoint = vec4(-14.32, -1097.86, 26.68, 160.72), -- where bought vehicles appear, with heading
            npc = { model = 's_m_m_autoshop_01', heading = 19.39 }, -- dealer ped model; heading defaults to location's
            categories = { -- vehicle classes this dealership sells
                'compacts', 'sedans', 'suvs', 'coupes', 'sports',
                'sportsclassic', 'super', 'muscle', 'offroad', 'vans',
                'motorcycles', 'openwheel',
            },
        },
        luxury = {
            label = 'Luxury Autos',
            blip = { sprite = 326, color = 5, scale = 0.7, label = 'Luxury Autos' },
            location = vec4(-1257.43, -369.44, 36.91, 352.43),
            spawnPoint = vec4(-1246.15, -348.34, 36.91, 204.0),
            npc = { model = 's_m_m_autoshop_01', heading = 352.43 },
            categories = { 'super', 'sports', 'sportsclassic', 'coupes', 'sedans' },
        },
    },
}
