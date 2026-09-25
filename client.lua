
CreateThread(function()
    local oldinterior = GetInteriorAtCoordsWithType(442.42957, -985.067, 29.885286, 'hei_heist_police_dlc')
    DisableInterior(oldinterior, true)
    UnpinInterior(oldinterior)

    local oldinterior2 = GetInteriorAtCoordsWithType(442.42957, -985.0669, 29.885286, 'v_policehub')
    DisableInterior(oldinterior2, true)
    UnpinInterior(oldinterior2)
end)

-- Join Quality Interiors For More Content https://discord.gg/KQDPqhfx7Y