local uiOpen        = false
local activeElevId  = nil
local uiText        = Config.Text and Config.Text.ui or {}
local interactCfg   = Config.Interaction or {}
local interactMode  = nil
local oxTextUIShown = false
local oxTargetZones = {}
local cuInterPoints = {}
local oxTargetReady = false

local function debugLog(msg)
    if not Config.Debug then return end
end

local function isResourceRunning(name)
    local state = GetResourceState(name)
    return state == "started" or state == "starting"
end

local function showHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function draw3DText(coords, text)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    local camCoords = GetGameplayCamCoords()
    local dist      = #(camCoords - vector3(coords.x, coords.y, coords.z))
    local scale     = (1.0 / dist) * 1.6 * (1.0 / GetGameplayCamFov() * 100.0)

    SetTextScale(0.0 * scale, 0.42 * scale)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(235, 240, 255, 215)
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(screenX, screenY)
end

local function setNuiFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    uiOpen = state
end

local function resolveInteractMode()
    local mode = Config.InteractionMode or "native"
    mode = mode:lower()

    local fallback = (interactCfg.fallbackMode or "native"):lower()

    if mode ~= "auto" then return mode end

    if isResourceRunning("ox_target")       then return "ox_target"       end
    if isResourceRunning("ox_lib")          then return "ox_textui"        end
    if isResourceRunning("cu_interactions") then return "cu_interactions"  end
    return fallback
end

local function getInteractMode()
    if interactMode then return interactMode end
    interactMode = resolveInteractMode()
    debugLog(("interaction mode: %s"):format(interactMode))
    return interactMode
end

local function hideOxTextUI()
    if not oxTextUIShown then return end
    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
    oxTextUIShown = false
end

local function showOxTextUI(text)
    if not (lib and lib.showTextUI) then return false end

    local icon = (interactCfg.oxTextUI and interactCfg.oxTextUI.icon) or "fa-solid fa-elevator"
    lib.showTextUI(text, { icon = icon })
    oxTextUIShown = true
    return true
end

local function getNearestFloor(elevator, pos)
    if not (elevator and elevator.floors and #elevator.floors ~= 0) then
        return nil, math.huge
    end

    local bestIdx  = 1
    local bestDist = math.huge

    for i = 1, #elevator.floors do
        local floor = elevator.floors[i]
        local dist  = #(pos - vector3(floor.coords.x, floor.coords.y, floor.coords.z))
        if dist < bestDist then
            bestDist = dist
            bestIdx  = i
        end
    end

    return bestIdx, bestDist
end

local function buildFloorList(elevator, currentFloorIdx)
    local list = {}
    for i = 1, #elevator.floors do
        local floor = elevator.floors[i]
        list[#list + 1] = {
            id          = floor.id,
            code        = floor.code or floor.id,
            label       = floor.label,
            description = floor.description,
            featured    = floor.featured == true,
            locked      = floor.locked   == true,
            current     = i == currentFloorIdx,
        }
    end
    return list
end

local function openElevator(elevIdx, currentFloorIdx)
    local elevator = Config.Elevators[elevIdx]
    if not elevator then return end

    activeElevId = elevIdx
    setNuiFocus(true)

    local label = elevator.label
        or uiText.panelFallbackTitle
        or "Elevator"

    SendNUIMessage({
        action       = "openElevator",
        elevatorId   = elevator.id,
        elevatorLabel = label,
        uiText = {
            kicker               = uiText.kicker               or "Vinewood Avenue",
            subtitleSelect       = uiText.subtitleSelect       or "Select destination floor",
            subtitleCurrentPrefix = uiText.subtitleCurrentPrefix or "Current floor:",
            statusMoving         = uiText.statusMoving         or "Moving...",
        },
        floors = buildFloorList(elevator, currentFloorIdx),
    })
end

local function closeElevator()
    if not uiOpen then return end
    setNuiFocus(false)
    SendNUIMessage({ action = "closeElevator" })
    activeElevId = nil
end

local function teleportToFloor(floor)
    local ped = PlayerPedId()

    DoScreenFadeOut(Config.Teleport.fadeOutMs)
    while not IsScreenFadedOut() do Wait(0) end

    SetEntityCoordsNoOffset(ped, floor.coords.x, floor.coords.y, floor.coords.z, false, false, false)
    SetEntityHeading(ped, floor.coords.w)

    Wait(Config.Teleport.settleMs)
    DoScreenFadeIn(Config.Teleport.fadeInMs)
end

local function openElevatorAtPos(elevIdx)
    local pos         = GetEntityCoords(PlayerPedId())
    local elevator    = Config.Elevators[elevIdx]
    local floorIdx    = getNearestFloor(elevator, pos)
    if floorIdx then
        openElevator(elevIdx, floorIdx)
    end
end

local function setupOxTarget()
    if oxTargetReady then return true end
    if not isResourceRunning("ox_target") then return false end

    local cfg      = interactCfg.oxTarget or {}
    local radius   = cfg.radius     or 1.25
    local distance = cfg.distance   or Config.InteractDistance
    local icon     = cfg.icon       or "fa-solid fa-elevator"
    local drawSprite = cfg.drawSprite == true

    for elevIdx = 1, #Config.Elevators do
        local elevator = Config.Elevators[elevIdx]
        if elevator.enabled ~= false and elevator.floors and #elevator.floors > 0 then
            for floorIdx = 1, #elevator.floors do
                local floor = elevator.floors[floorIdx]

                local labelText = (uiText.interactTarget or "Use elevator (%s)"):format(elevator.label or "Elevator")

                local zoneId = exports.ox_target:addSphereZone({
                    coords     = vector3(floor.coords.x, floor.coords.y, floor.coords.z),
                    radius     = radius,
                    debug      = false,
                    drawSprite = drawSprite,
                    options    = {
                        {
                            name     = ("elevator_%s_%s"):format(elevator.id, floor.id),
                            icon     = icon,
                            label    = labelText,
                            distance = distance,
                            onSelect = function()
                                openElevatorAtPos(elevIdx)
                            end,
                        }
                    },
                })

                oxTargetZones[#oxTargetZones + 1] = zoneId
            end
        end
    end

    oxTargetReady = true
    return true
end

local function removeOxTargetZones()
    if not oxTargetReady then return end
    if isResourceRunning("ox_target") then
        for _, zoneId in ipairs(oxTargetZones) do
            exports.ox_target:removeZone(zoneId)
        end
    end
    oxTargetZones = {}
    oxTargetReady = false
end

local function setupCuInteractions()
    local cfg = interactCfg.cuInteractions or {}
    if not isResourceRunning("cu_interactions") then return false end

    local count = 0

    for elevIdx = 1, #Config.Elevators do
        local elevator = Config.Elevators[elevIdx]
        if elevator.enabled ~= false and elevator.floors and #elevator.floors > 0 then
            for floorIdx = 1, #elevator.floors do
                local floor   = elevator.floors[floorIdx]
                local zoneName = ("elevator_%s_%s"):format(elevator.id, floor.id)
                local coords   = vector3(floor.coords.x, floor.coords.y, floor.coords.z)

                local ok = pcall(function()
                    local icon      = (interactCfg.oxTarget and interactCfg.oxTarget.icon) or "fa-solid fa-elevator"
                    local labelText = (uiText.interactTarget or "Use elevator (%s)"):format(elevator.label or "Elevator")

                    exports.cu_interactions:registerPointAction(zoneName, coords, {
                        hideMarker      = cfg.hideMarker      == true,
                        checkVisibility = cfg.checkVisibility == true,
                        distance        = cfg.distance        or Config.DrawDistance,
                        distanceMenu    = cfg.distanceMenu    or Config.InteractDistance,
                        showInCar       = cfg.showInCar       == true,
                        options = {
                            {
                                name     = "use_elevator",
                                label    = labelText,
                                icon     = icon,
                                key      = "E",
                                onSelect = function()
                                    openElevatorAtPos(elevIdx)
                                end,
                            }
                        },
                    })
                end)

                if ok then
                    cuInterPoints[#cuInterPoints + 1] = { point = coords, name = zoneName }
                    count = count + 1
                end
            end
        end
    end

    return count > 0
end

local function removeCuInterPoints()
    if #cuInterPoints == 0 then return end
    for _, entry in ipairs(cuInterPoints) do
        pcall(function()
            exports.cu_interactions:unregisterPointAction(entry.point, entry.name)
        end)
    end
    cuInterPoints = {}
end

RegisterNUICallback("closeElevator", function(_, cb)
    closeElevator()
    cb({ ok = true })
end)

RegisterNUICallback("selectFloor", function(data, cb)
    local elevIdx = activeElevId
    local floorId = data and data.id

    if not elevIdx or not floorId then
        closeElevator()
        cb({ ok = false, reason = "invalid_selection" })
        return
    end

    local elevator = Config.Elevators[elevIdx]
    if not elevator then
        closeElevator()
        cb({ ok = false, reason = "missing_elevator" })
        return
    end

    local targetFloor
    for _, floor in ipairs(elevator.floors) do
        if floor.id == floorId then
            targetFloor = floor
            break
        end
    end

    if targetFloor and targetFloor.locked == true then
        cb({ ok = false, reason = "floor_locked" })
        return
    end

    closeElevator()

    if targetFloor then
        CreateThread(function()
            teleportToFloor(targetFloor)
        end)
        cb({ ok = true })
    else
        cb({ ok = false, reason = "floor_not_found" })
    end
end)

CreateThread(function()
    local mode = getInteractMode()

    if mode == "ox_target" then
        if not setupOxTarget() then
            interactMode = (interactCfg.fallbackMode or "native"):lower()
            mode         = interactMode
            debugLog("ox_target unavailable, fallback active")
        end
    elseif mode == "cu_interactions" then
        if not setupCuInteractions() then
            interactMode = (interactCfg.fallbackMode or "native"):lower()
            mode         = interactMode
            debugLog("cu_interactions unavailable, fallback active")
        end
    end

    while true do
        local waitMs = 1000

        if mode == "ox_target" or mode == "cu_interactions" then
            if not uiOpen then waitMs = 500 end
        else
            if not uiOpen then
                local ped    = PlayerPedId()
                local pos    = GetEntityCoords(ped)
                local anyNear = false

                for elevIdx = 1, #Config.Elevators do
                    local elevator = Config.Elevators[elevIdx]
                    if elevator.enabled ~= false and elevator.floors and #elevator.floors > 0 then
                        local floorIdx, dist = getNearestFloor(elevator, pos)

                        if dist <= Config.DrawDistance then
                            waitMs = 0
                            local floor  = elevator.floors[floorIdx]
                            local floorPos = vector3(floor.coords.x, floor.coords.y, floor.coords.z + 0.1)

                            if interactCfg.showMarker ~= false then
                                local m = Config.Marker
                                DrawMarker(
                                    m.type,
                                    floorPos.x, floorPos.y, floorPos.z - 1.0,
                                    0.0, 0.0, 0.0,
                                    0.0, 0.0, 0.0,
                                    m.size.x, m.size.y, m.size.z,
                                    m.color.r, m.color.g, m.color.b, m.color.a,
                                    m.bobUpAndDown, m.faceCamera,
                                    2, false, nil, nil, false
                                )
                            end

                            if dist <= Config.InteractDistance then
                                local promptText = (uiText.interactHelp or "Press ~INPUT_CONTEXT~ to use elevator (%s)"):format(elevator.label)

                                if mode == "ox_textui" then
                                    if showOxTextUI(promptText) then
                                        anyNear = true
                                    end
                                else
                                    if interactCfg.use3DTextWhenNative ~= false and Config.Use3DText then
                                        local displayLabel = elevator.promptLabel
                                        if not displayLabel then
                                            local shortLabel = elevator.shortLabel or elevator.label or "Elevator"
                                            displayLabel = (uiText.interact3D or "[E] %s"):format(shortLabel)
                                        end
                                        draw3DText(vector3(floor.coords.x, floor.coords.y, floor.coords.z), displayLabel)
                                    else
                                        showHelpText(promptText)
                                    end
                                end

                                if IsControlJustReleased(0, Config.InteractionKey) then
                                    if mode == "ox_textui" then hideOxTextUI() end
                                    openElevator(elevIdx, floorIdx)
                                    break
                                end
                            end
                        end
                    end
                end

                if mode == "ox_textui" and not anyNear then
                    hideOxTextUI()
                end
            end
        end

        Wait(waitMs)
    end
end)

RegisterCommand("elevator", function()
    local pos      = GetEntityCoords(PlayerPedId())
    local bestIdx  = nil
    local bestFloor = nil
    local bestDist = math.huge

    for elevIdx = 1, #Config.Elevators do
        local elevator = Config.Elevators[elevIdx]
        if elevator.enabled ~= false and elevator.floors and #elevator.floors > 0 then
            local floorIdx, dist = getNearestFloor(elevator, pos)
            if dist < bestDist then
                bestDist  = dist
                bestIdx   = elevIdx
                bestFloor = floorIdx
            end
        end
    end

    if bestIdx then
        openElevator(bestIdx, bestFloor)
    end
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if uiOpen then setNuiFocus(false) end
    hideOxTextUI()
    removeOxTargetZones()
    removeCuInterPoints()
end)

