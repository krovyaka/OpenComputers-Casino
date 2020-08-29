local setOutput = component.proxy(component.list("redstone")()).setOutput
local getPlayers = component.proxy(component.list("radar")()).getPlayers

function os.sleep(timeout)
    local deadline = computer.uptime() + (timeout or 0)
    repeat
        computer.pullSignal(deadline - computer.uptime())
    until computer.uptime() >= deadline
end

local isActive = false
local OUTPUT_SIDE = 1

local function scan()
    local scanResult = getPlayers()
    for i = 1, #scanResult do
        if scanResult[i].distance <= 4 then
            return true
        end
    end
    return false
end

while true do
    os.sleep(2)
    local scanResult = scan()

    if not isActive and scanResult then
        setOutput(OUTPUT_SIDE, 15)
        isActive = true
    elseif isActive and not scanResult then
        setOutput(OUTPUT_SIDE, 0)
        isActive = false
    end
end