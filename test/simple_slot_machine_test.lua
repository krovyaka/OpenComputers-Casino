local sides_pair = 2
local neighbours_pair = 1
local combos = { 5, 5, 5, 10, 10, 20, 50, 100, 200 }
local rolls = 10000000

math.randomseed(os.time())

local function randomElement()
    return math.random(1, #combos)
end

local function roll()
    local a, b, c = randomElement(), randomElement(), randomElement()
    if a == b and b == c then
        return combos[a]
    end
    if a == b or b == c then
        return neighbours_pair
    end
    if a == c then
        return sides_pair
    end
    return 0
end

local money = 0
local max_money = money
local min_money = money
for test = 1, rolls do
    local result = roll()
    money = money - 1 + result
    if money > max_money then
        max_money = money
    end
    if money < min_money then
        min_money = money
    end
end

print("Money: " .. money)
print("Min money: " .. min_money)
print("Max money: " .. max_money)
print("Cash back: " .. (rolls + money) / rolls * 100 .. "%")