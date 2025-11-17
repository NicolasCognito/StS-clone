-- INVINCIBLE MAX STATUS EFFECT
-- Stores the maximum damage cap value for Invincible
-- Restores the invincible status to this value at the start of each turn
return {
    invincible_max = {
        id = "invincible_max",
        name = "Invincible (Max)",
        description = "Restores Invincible cap to this value at the start of each turn.",
        minValue = 0,
        maxValue = 9999,
        stackType = "intensity",
        debuff = false,

        -- Restore invincible cap at start of turn
        onStartTurn = function(world, target)
            if not target.status then
                target.status = {}
            end

            local maxCap = target.status.invincible_max or 0
            if maxCap > 0 then
                -- Restore invincible to max cap
                target.status.invincible = maxCap

                local displayName = target.name or target.id or "Target"
                table.insert(world.log, displayName .. "'s Invincible restored to " .. maxCap)
            end
        end
    }
}
