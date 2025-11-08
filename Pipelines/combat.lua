-- COMBAT PIPELINES
-- All game verbs live here. All modifications go here. No abstraction layers.

local CombatPipelines = {}

-- ============================================================================
-- DEAL DAMAGE
-- ============================================================================
-- world: the complete game state
-- attacker: character dealing damage
-- defender: character taking damage
-- card: the card being played (contains baseDamage and any scaling flags)
--
-- Handles:
-- - Base damage from card
-- - Attacker's Strength multiplier (when added)
-- - Defender's Vulnerable/Weak (when added)
-- - Block absorption
-- - HP reduction
-- - Combat log
function CombatPipelines.DealDamage(world, attacker, defender, card)
    -- TODO: implement
end

-- ============================================================================
-- APPLY BLOCK
-- ============================================================================
-- world: the complete game state
-- target: character gaining block
-- amount: block amount
--
-- Handles:
-- - Adding block to character
function CombatPipelines.ApplyBlock(world, target, amount)
    -- TODO: implement
end

-- ============================================================================
-- HEAL
-- ============================================================================
-- world: the complete game state
-- target: character being healed
-- amount: healing amount
--
-- Handles:
-- - Adding HP to character
-- - Capping at max HP
function CombatPipelines.Heal(world, target, amount)
    -- TODO: implement
end

-- ============================================================================
-- PLAY CARD
-- ============================================================================
-- world: the complete game state
-- player: the player character
-- card: the card from hand to play
-- target: target of the card (can be null for some cards)
--
-- Handles:
-- - Pay energy cost
-- - Resolve card effects (calls appropriate pipelines)
-- - Discard or exhaust the card
-- - Combat logging
function CombatPipelines.PlayCard(world, player, card, target)
    -- TODO: implement
end

-- ============================================================================
-- DRAW CARD
-- ============================================================================
-- world: the complete game state
-- player: the player character
-- count: number of cards to draw
--
-- Handles:
-- - Draw from deck
-- - Shuffle discard back into deck if deck is empty
-- - Draw limit enforcement (if any)
function CombatPipelines.DrawCard(world, player, count)
    -- TODO: implement
end

-- ============================================================================
-- END TURN
-- ============================================================================
-- world: the complete game state
-- player: the player whose turn is ending
--
-- Handles:
-- - Apply end-of-turn effects (Poison damage, debuff decay, etc.)
-- - Discard remaining hand
-- - Prepare for enemy turn
-- - Process effect queue
function CombatPipelines.EndTurn(world, player)
    -- TODO: implement
end

-- ============================================================================
-- ENEMY TAKE TURN
-- ============================================================================
-- world: the complete game state
-- enemy: the enemy taking its turn
-- player: the player being attacked
--
-- Handles:
-- - Execute enemy's intent action
-- - Apply damage/effects/status to player
function CombatPipelines.EnemyTakeTurn(world, enemy, player)
    -- TODO: implement
end

-- ============================================================================
-- PROCESS EFFECT QUEUE
-- ============================================================================
-- world: the complete game state
--
-- Handles:
-- - Process all queued events until queue is empty
-- - Events can be: ON_DAMAGE, ON_BLOCK, ON_HEAL, etc.
-- - Simple linear processing (no recursion)
function CombatPipelines.ProcessEffectQueue(world)
    -- TODO: implement
end

return CombatPipelines
