--- STEAMODDED HEADER
--- MOD_NAME: Joker Tracker
--- MOD_ID: JokerTracker
--- MOD_AUTHOR: [BalatroMod]
--- MOD_DESCRIPTION: A simple mod that displays your current jokers, hand cards, and selected hand score when you press 'J'
--- VERSION: 1.2.0

----------------------------------------------
---------------- MOD CODE --------------------
----------------------------------------------

-- Helper function to get suit symbol
local function get_suit_symbol(suit)
    local suit_map = {
        Spades = "♠",
        Hearts = "♥",
        Diamonds = "♦",
        Clubs = "♣"
    }
    return suit_map[suit] or suit
end

-- Helper function to get rank display
local function get_rank_display(rank)
    local rank_map = {
        ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5",
        ["6"] = "6", ["7"] = "7", ["8"] = "8", ["9"] = "9",
        ["10"] = "10", Jack = "J", Queen = "Q", King = "K", Ace = "A"
    }
    return rank_map[rank] or rank
end

-- Helper function to get selected cards
local function get_selected_cards()
    if not G.hand or not G.hand.cards then
        return {}
    end

    local selected = {}
    for _, card in ipairs(G.hand.cards) do
        if card.highlighted then
            table.insert(selected, card)
        end
    end
    return selected
end

-- Function to calculate and display score for selected cards
local function calculate_selected_score()
    local selected = get_selected_cards()

    if #selected == 0 then
        print("No cards selected")
        return
    end

    print("You have " .. #selected .. " card(s) selected:")

    -- Display selected cards
    for i, card in ipairs(selected) do
        local rank = get_rank_display(card.base.value)
        local suit = get_suit_symbol(card.base.suit)
        print("  " .. i .. ". " .. rank .. suit)
    end

    print("")

    -- Check if we can access the hand evaluation
    -- The game evaluates hands through G.GAME.selected_hand
    if G.GAME and G.GAME.current_round and G.GAME.current_round.hands_left and G.GAME.current_round.hands_left > 0 then
        -- Try to get the currently evaluated hand text
        if G.GAME.selected_hand and type(G.GAME.selected_hand) == "string" then
            local hand_name = G.GAME.selected_hand
            print("Detected Hand: " .. hand_name)

            -- Get hand level and chips/mult from G.GAME.hands
            if G.GAME.hands and G.GAME.hands[hand_name] then
                local hand_data = G.GAME.hands[hand_name]
                local chips = hand_data.chips or 0
                local mult = hand_data.mult or 0
                local level = hand_data.level or 1
                local played = hand_data.played or 0

                print("Hand Level: " .. level .. " (Played " .. played .. " times)")
                print("Base Chips: " .. chips)
                print("Base Mult: " .. mult)

                -- Calculate base score (chips × mult)
                local base_score = chips * mult
                print("Base Score: " .. base_score .. " (" .. chips .. " × " .. mult .. ")")
            else
                print("(Could not retrieve hand scoring data)")
            end
        else
            print("(Hand not yet evaluated - try selecting your cards first)")
        end

        print("")
        print("Note: Actual score will differ due to:")
        print("  - Individual card chip values")
        print("  - Card enhancements (Bonus, Mult, etc.)")
        print("  - Joker effects and multipliers")
        print("  - Editions (Foil +50 chips, Holo +10 mult, etc.)")
        print("  - Seals and other effects")
    else
        print("(Score calculation only available during active hands)")
    end
end

-- Function to display all current jokers and hand cards
local function display_game_state()
    -- Check if we're in a game
    if not G.jokers then
        print("=== Joker & Hand Tracker ===")
        print("Not currently in a run")
        print("============================")
        return
    end

    print("\n" .. string.rep("=", 50))
    print("           JOKER & HAND TRACKER")
    print(string.rep("=", 50))

    -- ===== JOKERS SECTION =====
    print("\n--- JOKERS ---")

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

    -- ===== HAND CARDS SECTION =====
    print("\n--- CARDS IN HAND ---")

    if not G.hand or not G.hand.cards then
        print("No hand available")
    elseif #G.hand.cards == 0 then
        print("Your hand is empty")
    else
        print("You have " .. #G.hand.cards .. " card(s) in hand:")
        print("")

        -- Loop through all cards in hand
        for i, card in ipairs(G.hand.cards) do
            -- Get basic card info
            local rank = get_rank_display(card.base.value)
            local suit = get_suit_symbol(card.base.suit)
            local card_display = rank .. suit

            -- Check for enhancement
            local enhancement = ""
            if card.ability.effect and card.ability.effect ~= "Base" then
                enhancement = " [" .. card.ability.effect .. "]"
            end

            -- Check for edition
            local edition = ""
            if card.edition then
                if card.edition.foil then edition = " [Foil]"
                elseif card.edition.holo then edition = " [Holographic]"
                elseif card.edition.polychrome then edition = " [Polychrome]"
                elseif card.edition.negative then edition = " [Negative]"
                end
            end

            -- Check for seal
            local seal = ""
            if card.seal then
                seal = " {" .. card.seal .. " Seal}"
            end

            -- Check if card is selected
            local selected = ""
            if card.highlighted then
                selected = " (Selected)"
            end

            print(i .. ". " .. card_display .. enhancement .. edition .. seal .. selected)
        end

        print("")
    end

    -- ===== SELECTED CARDS SCORE SECTION =====
    print("\n--- SELECTED HAND SCORE ---")
    print("")

    calculate_selected_score()

    print("")
    print(string.rep("=", 50) .. "\n")
end

-- Register the keybind using SMODS
SMODS.Keybind{
    key = 'joker_tracker',
    key_pressed = 'j',
    action = function(controller)
        display_game_state()
    end
}

-- Also add a message when the mod loads
print("=== Joker & Hand Tracker Mod Loaded (v1.2.0) ===")
print("Press 'J' to display:")
print("  - Current jokers")
print("  - Cards in hand")
print("  - Selected hand score")
print("=================================================")

----------------------------------------------
---------------- MOD CODE END ----------------
----------------------------------------------
