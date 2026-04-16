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

-- For Chameleon: find the epoch time of the "start" event to use as origin
startEpoch = 0
if isChameleon then
    startEpoch = tonumber(string.match(content, '"type"%s*:%s*"start"%s*,%s*"time"%s*:%s*([%d%.]+)'))
    if not startEpoch then
        -- fallback: try reverse field order
        startEpoch = tonumber(string.match(content, '"time"%s*:%s*([%d%.]+)%s*,%s*[^}]-"type"%s*:%s*"start"'))
    end
    if not startEpoch then
        print("Warning: Could not find start event for Chameleon origin. Defaulting to 0.")
        startEpoch = 0
    else
        print("Chameleon start epoch: " .. startEpoch)
    end
end

-- Parse and add markers
markersAdded = 0

for typeVal, timeVal in string.gmatch(content, '"type"%s*:%s*"([^"]+)".-"time"%s*:%s*([%d%.]+)') do

    if typeVal ~= "start" then

        eventTime = tonumber(timeVal)

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
            typeVal,
            "",
            durationFrames
        )

        markersAdded = markersAdded + 1
    end
end

print("Added " .. markersAdded .. " markers.")
