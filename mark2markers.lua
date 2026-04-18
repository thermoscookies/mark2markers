-- Marker settings
START_OFFSET_SECONDS = 15
MARKER_DURATION_SECONDS = 15

-- Get Resolve
resolve = Resolve()
pm = resolve:GetProjectManager()
project = pm:GetCurrentProject()
timeline = project:GetCurrentTimeline()

if not timeline then
    print("No active timeline.")
    return
end

fps = tonumber(project:GetSetting("timelineFrameRate"))

function secondsToFrames(seconds)
    return math.floor(seconds * fps + 0.5)
end

-- File picker
fusion = resolve:Fusion()
filepath = fusion:RequestFile("", "", {["File Types"] = "Mark Files (*.mark)|*.mark;JSON Files (*.json)|*.json|All Files (*.*)|*.*"})

if not filepath or filepath == "" then
    print("No file selected.")
    return
end

-- Read file
file = io.open(filepath, "r")
if not file then
    print("Could not open file.")
    return
end

content = file:read("*all")
file:close()

-- Auto-detect device format:
-- Chameleon uses Unix epoch timestamps (large integers, e.g. > 1,000,000,000)
-- Falcon uses relative seconds (small floats/ints)
firstTime = tonumber(string.match(content, '"time"%s*:%s*([%d%.]+)'))

isChameleon = firstTime and firstTime > 1000000000

if isChameleon then
    print("Detected format: Chameleon (epoch timestamps)")
else
    print("Detected format: Falcon (relative seconds)")
end

-- Parse each JSON object {…} individually to avoid greedy cross-object matching
function parseEvents(str)
    local events = {}
    for obj in string.gmatch(str, "{([^}]+)}") do
        local typeVal = string.match(obj, '"type"%s*:%s*"([^"]+)"')
        local timeVal = tonumber(string.match(obj, '"time"%s*:%s*([%d%.]+)'))
        if typeVal and timeVal then
            table.insert(events, {type = typeVal, time = timeVal})
        end
    end
    return events
end

events = parseEvents(content)

-- For Chameleon: find the start epoch from the parsed events
startEpoch = 0
if isChameleon then
    for _, e in ipairs(events) do
        if e.type == "start" then
            startEpoch = e.time
            break
        end
    end
    if startEpoch == 0 then
        print("Warning: Could not find start event for Chameleon origin. Defaulting to 0.")
    else
        print("Chameleon start epoch: " .. startEpoch)
    end
end

-- Add markers
markersAdded = 0

for _, e in ipairs(events) do
    if e.type ~= "start" then

        eventTime = e.time

        -- Normalize Chameleon epoch to relative seconds
        if isChameleon then
            eventTime = eventTime - startEpoch
        end

        markerStartSeconds = math.max(0, eventTime - START_OFFSET_SECONDS)

        startFrame = secondsToFrames(markerStartSeconds)
        durationFrames = secondsToFrames(MARKER_DURATION_SECONDS)

        timeline:AddMarker(
            startFrame,
            "Blue",
            e.type,
            "",
            durationFrames
        )

        markersAdded = markersAdded + 1
    end
end

print("Added " .. markersAdded .. " markers.")
