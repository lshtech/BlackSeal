--- STEAMODDED HEADER
--- MOD_NAME: Black Seal
--- MOD_ID: BlackSeal
--- MOD_AUTHOR: [Infarctus, elbe]
--- MOD_DESCRIPTION: Adds a Black Seal to the game
--- PREFIX: black

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Seal {
    name = "black_seal",
    key = "black_seal",
    badge_colour = HEX("000000"),
    loc_txt = {
        label = 'Black Seal',
        name = 'Black Seal',
        text = {
            "If you play only this card:",
            "add {C:dark_edition}negative{} to a random {C:attention}Joker{}",
            "remove all {C:dark_edition}Black Seals{} from your deck",
            "{C:inactive}(Can only be found in Standard packs){}"
        }
    },
    config = {},
    loc_vars = function(self, info_queue)
        return { vars = { } }
    end,
    atlas = "blackseal_atlas",
    pos = {x=0, y=0},
    calculate = function(self, card, context)
        if context.cardarea == G.play and not context.repetition_only then
            local eligible_jokers = {}
            for _, v in pairs(G.jokers.cards) do
                if v.ability.set == 'Joker' and (not v.edition) then
                    table.insert(eligible_jokers, v)
                end
            end
            sendDebugMessage("Eligible jokers: " .. #eligible_jokers)
            if #eligible_jokers>=1 then
                local eligible_joker_card = pseudorandom_element(eligible_jokers, pseudoseed("blackseal"))
                eligible_joker_card:set_edition({negative = true})
            end
            G.E_MANAGER:add_event(
                Event({
                    trigger = 'after',
                    delay = 0.2,
                    func = function()
                        for _,v in pairs(G.playing_cards) do
                            if v.seal== 'black_seal'then
                                v.seal=nil
                            end
                        end
                        return true
                    end
                })
            )
        end
    end
}
SMODS.Atlas {
    key = "blackseal_atlas",
    path = "black_seal.png",
    px = 71,
    py = 95
}

----------------------------------------------
------------MOD CODE END----------------------
