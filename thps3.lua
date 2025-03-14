process('THPS3.exe')

local LEVEL_COUNT = 9
local LEVEL_IS_COMP = {
    false,
    false,
    true,
    false,
    false,
    true,
    false,
    true,
    false,
}

-- Define state tables using named keys for clarity
local current = {
    goal_count = 0,
    medal_count = 0,
    gold_count = 0,
    level_id = 0,
    is_loading = false,
    is_timer_running = false,
    is_paused = false,
    comp_ranking = 0,
    comp_is_over = false,
}

local old = {
    goal_count = 0,
    medal_count = 0,
    gold_count = 0,
    level_id = 0,
    is_loading = false,
    is_timer_running = false,
    is_paused = false,
    comp_ranking = 0,
    comp_is_over = false,
}

local foundry_started = false
local tokyo_started = false
local tokyo_complete = false
local all_goals_and_golds_complete = false

function startup()
    refreshRate = 120
    mapsCacheCycles = 1
end

function state()
    -- Copy the current state into old
    for key, value in pairs(current) do
        old[key] = value
    end

    current.goal_count = get_goal_count()
    current.level_id = readAddress('uint', 0x4e1e90, 0x134, 0x14, 0x690)
    current.is_loading = readAddress('bool', 'THPS3.exe', 0x1d0620)
    current.is_timer_running = readAddress('bool', 'THPS3.exe', 0x450BC0)
    current.is_paused = readAddress('bool', 'THPS3.exe', 0x450BC8)  -- Fixed typo here.
    current.comp_ranking = readAddress('uint', 0x4e1e90, 0x45c, 0x160)
    current.comp_is_over = readAddress('bool', 0x4e1e90, 0x45c, 0x15c)
    
    -- Update medal and gold counts
    local medals, golds = get_medal_count()
    current.medal_count = medals
    current.gold_count = golds
end

function update()
    if foundry_started and current.level_id ~= 1 then
        foundry_started = false
    end

    if not tokyo_started and current.level_id == 8 and not current.comp_is_over and current.medal_count < 3 then
        tokyo_started = true
    end

    if tokyo_started and current.level_id ~= 8 then
        tokyo_started = false
    end

    if tokyo_complete and current.level_id ~= 8 and current.medal_count < 3 then
        tokyo_complete = false
    end

    if (current.goal_count ~= old.goal_count or current.gold_count ~= old.gold_count) and
       current.goal_count == 54 and current.gold_count == 3 then
        all_goals_and_golds_complete = true
    end

    if all_goals_and_golds_complete and (current.goal_count ~= 54 or current.gold_count ~= 3) then
        all_goals_and_golds_complete = false
    end

    if current.level_id == 1 and old.level_id == 0 and current.goal_count == 0 then
        foundry_started = true
    end
end

function start()
    if foundry_started and not current.is_loading and not current.is_paused and current.is_timer_running then
        return true
    end
end

function split()
    if current.level_id ~= old.level_id and current.level_id ~= 0 and old.level_id ~= 8 and current.level_id ~= 9 then
        return true
    end

    if not tokyo_complete and ((current.level_id == 8 and tokyo_started and current.comp_is_over and current.comp_ranking <= 3)
       or current.medal_count == 3) then
        tokyo_complete = true
        return true
    end

    if all_goals_and_golds_complete and not current.is_timer_running then
        all_goals_and_golds_complete = false
        return true
    end
end

function reset()
    if current.level_id == 0 and current.goal_count == 0 then
        return true
    end
end

function isLoading()
    return current.is_loading and not old.is_loading
end

function get_goal_count()
    local result = 0
    for i = 1, LEVEL_COUNT do
        if not LEVEL_IS_COMP[i] then
            local offset = 0x564 + ((i - 1) * 8)
            local v = readAddress('uint', 0x4e1e90, 0x134, 0x14, offset)
            result = result + countOnes(v)
        end
    end
    return result
end

function get_medal_count()
    local num_medals = 0
    local num_gold = 0
    for i = 1, LEVEL_COUNT do
        if LEVEL_IS_COMP[i] then
            local offset = 0x564 + ((i - 1) * 8)
            local v = readAddress('uint', 0x4e1e90, 0x134, 0x14, offset)
            if v ~= 0 then
                num_medals = num_medals + 1
            end
            num_gold = num_gold + (v == 0x04 and 1 or 0)
        end
    end
    return num_medals, num_gold
end

-- Helper function to count the number of ones in the binary representation
function countOnes(n)
    local count = 0
    while n > 0 do
        count = count + (n % 2)
        n = math.floor(n / 2)
    end
    return count
end
