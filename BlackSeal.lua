--- STEAMODDED HEADER
--- MOD_NAME: Black Seal
--- MOD_ID: BlackSeal
--- MOD_AUTHOR: [Infarctus]
--- MOD_DESCRIPTION: Adds a Black Seal to the game

----------------------------------------------
------------MOD CODE -------------------------

local MOD_ID = 'BlackSeal'

SMODS.Seal {
    name = "black_seal",
    key = "Black",
    badge_colour = HEX("000000"),
    loc_txt = {
        -- Badge name (displayed on card description when seal is applied)
        label = 'Black Seal',
        -- Tooltip description
        name = 'Black Seal',
        text = {
            "If you play only this card:",
            "add {C:dark_edition}negative{} to a random {C:attention}Joker{}",
            "remove all {C:dark_edition}Black Seals{} from your deck",
            "{C:inactive}(Can only be found in Standard packs){}"
        }
    },
    atlas = "blackseal_atlas",
    pos = {x=0, y=0},
}

SMODS.Atlas {
    key = "blackseal_atlas",
    path = "black_seal.png",
    px = 71,
    py = 95
}

function SMODS.INIT.BlackSeal()

--    add_seal(
--        MOD_ID,
--        'Black',
--        'black_seal',
--        'Black Seal',
--        {
--            discovered = false,
--            set = 'Seal',
--            config = { Xmult = 1 } -- thanks GreenSeal you need to update your release
--        },
--        {
--            name = 'Black Seal',
--            text = {
--                "If you play only this card:",
--                "add {C:dark_edition}negative{} to a random {C:attention}Joker{}",
--                "remove all {C:dark_edition}Black Seals{} from your deck",
--                "{C:inactive}(Can only be found in Standard packs){}"
--            }
--        }
--    )
--    refresh_items()
end

-- Add in the seal functionality
local calculate_seal_ref = Card.calculate_seal
function Card:calculate_seal(context)
    local fromRef = calculate_seal_ref(self, context)

    if context.cardarea == G.play and not context.repetition_only then
        if self.seal == 'Black' then
            return "Black"
        end
    end

    return fromRef
end

-- Applies the effect of the black seal
local eval_card_ref = eval_card
function eval_card(card, context)
    if context and context.full_hand and (#context.full_hand or 0)==1 and context.scoring_hand and context.cardarea == G.play and not(context.repetition_only) then
        local seal = card:calculate_seal(context)
        if seal == 'Black' then
            Add_Negative_Random()
            G.E_MANAGER:add_event(
                Event({
                    trigger = 'after',
                    delay = 0.2,
                    func = function() 
                        for k,v in pairs(G.playing_cards) do
                            if v.seal== 'Black'then
                                v.seal=nil
                            end
                        end
                        return true 
                    end 
                })
            )
            
        end
    end
    local fromRef = eval_card_ref(card, context)
    return fromRef
end

function Add_Negative_Random()
    local eligible_jokers = {}
    for k, v in pairs(G.jokers.cards) do
        if v.ability.set == 'Joker' and (not v.edition) then
            table.insert(eligible_jokers, v)
        end
    end
    sendDebugMessage("Eligible jokers: " .. #eligible_jokers)
    if #eligible_jokers>=1 then
        local eligible_joker_card = pseudorandom_element(eligible_jokers, pseudoseed("blackseal"))
        eligible_joker_card:set_edition({negative = true})
    end
end

-- Add the seal to be randomly generated in standard packs
-- This is bad because we have to reimplement the seal generation logic for standard packs
-- for my seal to be randomly generated. BEcause of how the logic is implemented in the base
-- game we cannot call the base function or else we'll end up with twice the amount of cards in the pack.
-- This means that any other mod that touches the standard pack may be wiped out
local card_open_ref = Card.open
function Card:open()
    if self.ability.set == "Booster" and not self.ability.name:find('Standard') then
        return card_open_ref(self)
    else
        stop_use()
        G.STATE_COMPLETE = false
        self.opening = true

        if not self.config.center.discovered then
            discover_card(self.config.center)
        end
        self.states.hover.can = false
        G.STATE = G.STATES.STANDARD_PACK
        G.GAME.pack_size = self.ability.extra

        G.GAME.pack_choices = self.config.center.config.choose or 1

        if self.cost > 0 then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    inc_career_stat('c_shop_dollars_spent', self.cost)
                    self:juice_up()
                    return true
                end
            }))
            ease_dollars(-self.cost)
        else
            delay(0.2)
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                self:explode()
                local pack_cards = {}

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 1.3 * math.sqrt(G.SETTINGS.GAMESPEED),
                    blockable = false,
                    blocking = false,
                    func = function()
                        local _size = self.ability.extra

                        for i = 1, _size do
                            local card = nil
                            card = create_card(
                                (pseudorandom(pseudoseed('stdset' .. G.GAME.round_resets.ante)) > 0.6) and
                                "Enhanced" or
                                "Base", G.pack_cards, nil, nil, nil, true, nil, 'sta')
                            local edition_rate = 2
                            local edition = poll_edition('standard_edition' .. G.GAME.round_resets.ante,
                                edition_rate,
                                true)
                            card:set_edition(edition)
                            local seal_rate = 10
                            local seal_poll = pseudorandom(pseudoseed('stdseal' .. G.GAME.round_resets.ante))
                            if seal_poll > 1 - 0.02 * seal_rate then
                                -- This is basically the only code that is changed
                                local seal_type = pseudorandom(
                                    pseudoseed('stdsealtype' .. G.GAME.round_resets.ante),
                                    1,
                                    #G.P_CENTER_POOLS['Seal']
                                )
                                local sealName
                                for k, v in pairs(G.P_SEALS) do
                                    if v.order == seal_type then sealName = k end
                                end

                                if sealName == nil then sendDebugMessage("SEAL NAME IS NIL") end

                                card:set_seal(sealName)
                                -- End changed code
                            end
                            card.T.x = self.T.x
                            card.T.y = self.T.y
                            card:start_materialize({ G.C.WHITE, G.C.WHITE }, nil, 1.5 * G.SETTINGS.GAMESPEED)
                            pack_cards[i] = card
                        end
                        return true
                    end
                }))

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 1.3 * math.sqrt(G.SETTINGS.GAMESPEED),
                    blockable = false,
                    blocking = false,
                    func = function()
                        if G.pack_cards then
                            if G.pack_cards and G.pack_cards.VT.y < G.ROOM.T.h then
                                for k, v in ipairs(pack_cards) do
                                    G.pack_cards:emplace(v)
                                end
                                return true
                            end
                        end
                    end
                }))

                for i = 1, #G.jokers.cards do
                    G.jokers.cards[i]:calculate_joker({ open_booster = true, card = self })
                end

                if G.GAME.modifiers.inflation then
                    G.GAME.inflation = G.GAME.inflation + 1
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            for k, v in pairs(G.I.CARD) do
                                if v.set_cost then v:set_cost() end
                            end
                            return true
                        end
                    }))
                end

                return true
            end
        }))
    end
end

-- UI code for seal
local generate_card_ui_ref = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end, card)
    local fromRef = generate_card_ui_ref(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start,
        main_end, card)

    local info_queue = {}

    if not (_c.set == 'Edition') and badges then
        for k, v in ipairs(badges) do
            if v == 'black_seal' then info_queue[#info_queue + 1] = { key = 'black_seal', set = 'Other' } end
        end
    end

    for _, v in ipairs(info_queue) do
        generate_card_ui(v, fromRef)
    end

    return fromRef
end

-- Add the background color of the box that says "Black Seal"
local get_badge_colour_ref = get_badge_colour
function get_badge_colour(key)
    local fromRef = get_badge_colour_ref(key)

    if key == 'black_seal' then
        return G.C.BLACK
    end

    return fromRef
end
----------------------------------------------
------------MOD CODE END----------------------
