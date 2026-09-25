Config = {
    Locale = "en",

    Debug = false,
    Use3DText = false,
    InteractionKey = 38,
    InteractionMode = "ox_target", 

    Interaction = {
        fallbackMode = "native",
        showMarker = true,
        use3DTextWhenNative = true,

        oxTextUI = {
            icon = "fa-solid fa-elevator"
        },

        oxTarget = {
            icon = "fa-solid fa-elevator",
            distance = 1.8,
            radius = 1.25,
            drawSprite = false
        },

        cuInteractions = {
            hideMarker = true,
            checkVisibility = false,
            distance = 10.0,
            distanceMenu = 2.0,
            showInCar = false
        }
    },

    DrawDistance = 22.0,
    InteractDistance = 1.85,
    Marker = {
        type = 1,
        size = vector3(1.11, 1.11, 0.11),
        color = { r = 86, g = 158, b = 255, a = 165 },
        bobUpAndDown = false,
        faceCamera = true
    },

    Teleport = {
        fadeOutMs = 320,
        fadeInMs = 320,
        settleMs = 110
    },

    UI = {
        showCurrentFloorInSubtitle = true
    },

    Text = {
        interactHelp = "Press ~INPUT_CONTEXT~ to use elevator (%s)",
        interact3D = "[E] %s",
        interactTarget = "Use elevator (%s)",

        ui = {
            kicker = "Vinewood Avenue",
            panelFallbackTitle = "Elevator",
            subtitleSelect = "Select destination floor",
            subtitleCurrentPrefix = "Current floor:",
            statusMoving = "Moving..."
        }
    },

    Elevators = {
        {
            id = "reaper_left",
            label = "Vinewood Hospital ",
            shortLabel = "Left",
            enabled = true,
            promptLabel = "[E] Elevator",
            floors = {
                { id = "roof",     code = "RF",   label = "Roof",               description = "",      featured = true, coords = vector4(57.52, -390.28, 72.43, 77.89) },
                { id = "floor_03", code = "04",   label = "Floor 03",           description = "",   coords = vector4(59.393406, -358.285706, 55.526001, 252.40) },
                { id = "floor_02", code = "03",   label = "Floor 02",           description = "",   coords = vector4(59.09, -358.15, 51.68, 252.40) },
                { id = "floor_01", code = "02",   label = "Floor 01",           description = "",   coords = vector4(59.35, -358.30, 46.68, 253.10) },
                { id = "lobby_1",  code = "01",   label = "Reception",  description = "",          coords = vector4(59.17, -358.23, 41.13, 250.88) },
                { id = "parking",  code = "P",    label = "Parking",            description = "", featured = true, coords = vector4(61.67, -407.33, 21.13, 338.30) }
            }
        },
        {
            id = "reaper_right",
            label = "Vinewood Hospital",
            shortLabel = "Right",
            enabled = true,
            promptLabel = "[E] Elevator",
            floors = {
                { id = "lobby_2",  code = "03",   label = "Floor 03",  description = "",         coords = vector4(60.02, -391.45, 56.53, 73.60) },
                { id = "lobby_1",  code = "02",   label = "Floor 02",  description = "",          coords = vector4(60.24, -391.39, 51.68, 62.65) }
            }
        }
    }
}

