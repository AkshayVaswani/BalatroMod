--- STEAMODDED HEADER
--- MOD_NAME: Joker Tracker
--- MOD_ID: JokerTracker
--- MOD_AUTHOR: [BalatroMod]
--- MOD_DESCRIPTION: A simple mod that displays your current jokers when you press 'J'
--- VERSION: 1.0.0

----------------------------------------------
---------------- MOD CODE --------------------
----------------------------------------------

-- Function to display all current jokers
local function display_jokers()
    -- Check if we're in a game
    if not G.jokers then
        print("=== Joker Tracker ===")
        print("No jokers available (not in a run)")
        print("====================")
        return
    end

    -- Print header
    print("\n=== Current Jokers ===")

    -- Check if we have any jokers
    if #G.jokers.cards == 0 then
        print("You have no jokers yet!")
    else
        print("You have " .. #G.jokers.cards .. " joker(s):")
        print("")

        -- Loop through all jokers and display them
        for i, card in ipairs(G.jokers.cards) do
            local joker_name = card.config.center.name or "Unknown Joker"
            local joker_key = card.config.center.key or "unknown"
            local edition = ""

            -- Check for editions (Foil, Holographic, Polychrome, Negative)
            if card.edition then
                if card.edition.foil then edition = " [Foil]"
                elseif card.edition.holo then edition = " [Holographic]"
                elseif card.edition.polychrome then edition = " [Polychrome]"
                elseif card.edition.negative then edition = " [Negative]"
                end
            end

            -- Check if joker is perishable
            local perishable = ""
            if card.ability.perishable then
                perishable = " (Perishable: " .. card.ability.perish_tally .. " rounds left)"
            end

            -- Check if joker is rental
            local rental = ""
            if card.ability.rental then
                rental = " (Rental)"
            end

            -- Check if joker is eternal
            local eternal = ""
            if card.ability.eternal then
                eternal = " (Eternal)"
            end

            print(i .. ". " .. joker_name .. edition .. eternal .. rental .. perishable)
            print("   ID: " .. joker_key)

            -- Display ability description if available
            if card.ability and card.ability.extra then
                print("   Extra Data: " .. tostring(card.ability.extra))
            end

            print("")
        end
    end

    print("======================\n")
end

-- Register the keybind using SMODS
SMODS.Keybind{
    key = 'joker_tracker',
    key_pressed = 'j',
    action = function(controller)
        display_jokers()
    end
}

-- Also add a message when the mod loads
print("=== Joker Tracker Mod Loaded ===")
print("Press 'J' to display your current jokers!")
print("================================")

----------------------------------------------
---------------- MOD CODE END ----------------
----------------------------------------------
