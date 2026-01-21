local lovely = require("lovely")
local nativefs = require("nativefs")

Brainstorm.AUTOREROLL = {}

-- Money generating jokers list
Brainstorm.MONEY_JOKERS = {
	"j_mail",           -- Mail-in Rebate
	"j_business",       -- Business Card
	"j_cloud_9",        -- Cloud 9
	"j_rocket",         -- Rocket
	"j_midas_mask",     -- Midas Mask
	"j_gift_card",      -- Gift Card
	"j_reserved_parking", -- Reserved Parking
	"j_golden",         -- Golden Joker
	"j_trading_card"    -- Trading Card
}

-- Check if a joker is in a list
function Brainstorm.is_joker_in_list(joker_key, joker_list)
	for _, j in ipairs(joker_list) do
		if joker_key == j then
			return true
		end
	end
	return false
end

-- Simulate shop joker generation for a given ante
-- Based on Immolate's reverse-engineered Balatro shop logic
-- Uses exact RNG seed strings from Balatro v1.0.1c
function Brainstorm.simulate_shop_jokers(seed_found, ante)
	local jokers_found = {}

	-- Check only the first 2 shop slots (initial shop, no rerolls)
	for slot = 1, 2 do
		-- Determine if this slot is a joker (vs tarot/planet/spectral)
		-- Use "cdt" + ante as the seed string (Card_Type from Immolate)
		local card_type_poll = pseudorandom(Brainstorm.pseudoseed("cdt" .. ante .. seed_found))

		-- Shop instance rates: 20 for jokers, 4 for tarots, 4 for planets, 0 for playing cards, 0 for spectrals
		-- Total rate = 28, so joker threshold is 20/28 ≈ 0.714
		if card_type_poll < 0.714 then
			-- This slot contains a joker
			local joker_data = Brainstorm.get_shop_joker(seed_found, ante)
			if joker_data then
				table.insert(jokers_found, joker_data)
			end
		end
	end

	return jokers_found
end

-- Get a shop joker for a given seed and ante
-- Returns table with {key, edition}
function Brainstorm.get_shop_joker(seed_found, ante)
	local ante_str = tostring(ante)

	-- Determine rarity using "rarity" + ante + "sho" seed string
	-- Common: 70%, Uncommon: 25%, Rare: 5%
	local rarity_poll = pseudorandom(Brainstorm.pseudoseed("rarity" .. ante_str .. "sho" .. seed_found))
	local rarity_id
	if rarity_poll > 0.95 then
		rarity_id = 3 -- rare
	elseif rarity_poll > 0.7 then
		rarity_id = 2 -- uncommon
	else
		rarity_id = 1 -- common
	end

	-- Determine edition (from Immolate's nextJoker)
	-- Negative: >0.997, Polychrome: >0.994, Holographic: >0.98, Foil: >0.96
	local edition_poll = pseudorandom(Brainstorm.pseudoseed("edi" .. "sho" .. ante_str .. seed_found))
	local edition = "none"
	if edition_poll > 0.997 then
		edition = "e_negative"
	elseif edition_poll > 0.994 then
		edition = "e_polychrome"
	elseif edition_poll > 0.98 then
		edition = "e_holo"
	elseif edition_poll > 0.96 then
		edition = "e_foil"
	end

	-- Use Balatro's actual seed strings: "Joker1"=common, "Joker2"=uncommon, "Joker3"=rare
	local seed_prefix = "Joker" .. rarity_id

	-- Use weighted selection on jokers (similar to booster pack code)
	if G.P_CENTER_POOLS and G.P_CENTER_POOLS['Joker'] then
		local cume, it, center = 0, 0, nil

		-- Calculate cumulative weights for jokers matching the rarity
		for k, v in ipairs(G.P_CENTER_POOLS['Joker']) do
			-- Check various possible rarity field locations
			local joker_rarity = v.rarity or (v.config and v.config.rarity) or (v.config and v.config.center and v.config.center.rarity)
			if joker_rarity == rarity_id then
				cume = cume + (v.weight or 1)
			end
		end

		-- Select joker using cumulative weight method
		local poll = pseudorandom(Brainstorm.pseudoseed(seed_prefix .. "sho" .. ante_str .. seed_found)) * cume
		for k, v in ipairs(G.P_CENTER_POOLS['Joker']) do
			local joker_rarity = v.rarity or (v.config and v.config.rarity) or (v.config and v.config.center and v.config.center.rarity)
			if joker_rarity == rarity_id then
				it = it + (v.weight or 1)
				if it >= poll and it - (v.weight or 1) <= poll then
					center = v
					break
				end
			end
		end

		if center then
			return {key = center.key, edition = edition}
		end
	end

	return nil
end

-- Check if Blueprint/Brainstorm + money joker combo exists in buffoon packs in ante 1
function Brainstorm.check_blueprint_money_combo(seed_found)
	local has_blueprint = false
	local has_money_joker = false

	-- Check buffoon packs in ante 1
	local jokers = Brainstorm.simulate_buffoon_pack_jokers(seed_found, 1)

	for _, joker_data in ipairs(jokers) do
		-- Check for Blueprint or Brainstorm
		if joker_data.key == "j_blueprint" or joker_data.key == "j_brainstorm" then
			has_blueprint = true
		end

		-- Check for money generating joker
		if Brainstorm.is_joker_in_list(joker_data.key, Brainstorm.MONEY_JOKERS) then
			has_money_joker = true
		end
	end

	return has_blueprint and has_money_joker
end

-- Check if Blueprint or Brainstorm exists in shops OR buffoon packs up to max_ante
function Brainstorm.check_blueprint_brainstorm(seed_found, max_ante)
	max_ante = max_ante or 1

	-- Check each ante up to max_ante
	for ante = 1, max_ante do
		-- Check shop jokers
		local shop_jokers = Brainstorm.simulate_shop_jokers(seed_found, ante)
		for _, joker_data in ipairs(shop_jokers) do
			if joker_data.key == "j_blueprint" or joker_data.key == "j_brainstorm" then
				print("[Brainstorm] Found Blueprint/Brainstorm in ante " .. ante .. " shop for seed: " .. seed_found)
				return true
			end
		end

		-- Check buffoon packs
		local pack_jokers = Brainstorm.simulate_buffoon_pack_jokers(seed_found, ante)
		for _, joker_data in ipairs(pack_jokers) do
			if joker_data.key == "j_blueprint" or joker_data.key == "j_brainstorm" then
				print("[Brainstorm] Found Blueprint/Brainstorm in ante " .. ante .. " buffoon pack for seed: " .. seed_found)
				return true
			end
		end
	end

	return false
end

-- Check if money-generating joker exists in shop up to max_ante
function Brainstorm.check_money_joker(seed_found, max_ante)
	max_ante = max_ante or 1

	-- Check each ante up to max_ante
	for ante = 1, max_ante do
		local jokers = Brainstorm.simulate_shop_jokers(seed_found, ante)

		for _, joker_data in ipairs(jokers) do
			-- Check for money generating joker
			if Brainstorm.is_joker_in_list(joker_data.key, Brainstorm.MONEY_JOKERS) then
				print("[Brainstorm] Found Money joker in ante " .. ante .. " shop for seed: " .. seed_found)
				return true
			end
		end
	end

	return false
end

-- Check if negative Blueprint or Brainstorm exists in shops OR buffoon packs up to max_ante
function Brainstorm.check_negative_blueprint_brainstorm(seed_found, max_ante)
	max_ante = max_ante or 1

	-- Check each ante up to max_ante
	for ante = 1, max_ante do
		-- Check shop jokers
		local shop_jokers = Brainstorm.simulate_shop_jokers(seed_found, ante)
		for _, joker_data in ipairs(shop_jokers) do
			if (joker_data.key == "j_blueprint" or joker_data.key == "j_brainstorm") and joker_data.edition == "e_negative" then
				print("[Brainstorm] Found Negative Blueprint/Brainstorm in ante " .. ante .. " shop for seed: " .. seed_found)
				return true
			end
		end

		-- Check buffoon packs
		local pack_jokers = Brainstorm.simulate_buffoon_pack_jokers(seed_found, ante)
		for _, joker_data in ipairs(pack_jokers) do
			if (joker_data.key == "j_blueprint" or joker_data.key == "j_brainstorm") and joker_data.edition == "e_negative" then
				print("[Brainstorm] Found Negative Blueprint/Brainstorm in ante " .. ante .. " buffoon pack for seed: " .. seed_found)
				return true
			end
		end
	end

	return false
end

-- Simulate buffoon pack jokers for a given ante
-- Checks all possible buffoon packs that could appear
function Brainstorm.simulate_buffoon_pack_jokers(seed_found, ante)
	local all_jokers = {}

	-- Check multiple pack iterations (since packs can be rerolled in shop)
	for pack_iter = 1, 4 do
		local pack = Brainstorm.simulate_pack(seed_found, ante, pack_iter)

		if pack and (pack.key == "p_buffoon_normal_1" or pack.key == "p_buffoon_jumbo_1" or pack.key == "p_buffoon_mega_1") then
			-- Simulate jokers in this buffoon pack
			local pack_size = pack.size or 2
			for i = 1, pack_size do
				local joker_data = Brainstorm.get_buffoon_pack_joker(seed_found, ante, i)
				if joker_data then
					table.insert(all_jokers, joker_data)
				end
			end
		end
	end

	return all_jokers
end

-- Get a joker from a buffoon pack
function Brainstorm.get_buffoon_pack_joker(seed_found, ante, card_num)
	local ante_str = tostring(ante)

	-- Determine rarity (buffoon packs can have any rarity)
	local rarity_poll = pseudorandom(Brainstorm.pseudoseed("rarity" .. ante_str .. "buf" .. seed_found))
	local rarity_id
	if rarity_poll > 0.95 then
		rarity_id = 3 -- rare
	elseif rarity_poll > 0.7 then
		rarity_id = 2 -- uncommon
	else
		rarity_id = 1 -- common
	end

	-- Determine edition
	local edition_poll = pseudorandom(Brainstorm.pseudoseed("edi" .. "buf" .. ante_str .. seed_found))
	local edition = "none"
	if edition_poll > 0.997 then
		edition = "e_negative"
	elseif edition_poll > 0.994 then
		edition = "e_polychrome"
	elseif edition_poll > 0.98 then
		edition = "e_holo"
	elseif edition_poll > 0.96 then
		edition = "e_foil"
	end

	-- Select joker
	local seed_prefix = "Joker" .. rarity_id

	if G.P_CENTER_POOLS and G.P_CENTER_POOLS['Joker'] then
		local cume, it, center = 0, 0, nil

		-- Calculate cumulative weights for jokers matching the rarity
		for k, v in ipairs(G.P_CENTER_POOLS['Joker']) do
			local joker_rarity = v.rarity or (v.config and v.config.rarity) or (v.config and v.config.center and v.config.center.rarity)
			if joker_rarity == rarity_id then
				cume = cume + (v.weight or 1)
			end
		end

		-- Select joker using cumulative weight method
		local poll = pseudorandom(Brainstorm.pseudoseed(seed_prefix .. "buf" .. ante_str .. seed_found)) * cume
		for k, v in ipairs(G.P_CENTER_POOLS['Joker']) do
			local joker_rarity = v.rarity or (v.config and v.config.rarity) or (v.config and v.config.center and v.config.center.rarity)
			if joker_rarity == rarity_id then
				it = it + (v.weight or 1)
				if it >= poll and it - (v.weight or 1) <= poll then
					center = v
					break
				end
			end
		end

		if center then
			return {key = center.key, edition = edition}
		end
	end

	return nil
end

-- Simulate a standard pack card generation
-- Returns card properties: {base, enhancement, edition, seal}
function Brainstorm.simulate_standard_card(seed_found, ante, card_index)
	local ante_str = tostring(ante)
	local card = {}

	-- Enhancement check (60% chance of no enhancement, 40% chance of having one)
	local has_enhancement_poll = pseudorandom(Brainstorm.pseudoseed("stdset" .. ante_str .. seed_found))
	if has_enhancement_poll <= 0.6 then
		card.enhancement = "none"
	else
		-- Has enhancement - select from pool using pseudorandom_element
		if G.P_CENTER_POOLS and G.P_CENTER_POOLS['Enhanced'] then
			local enh = pseudorandom_element(G.P_CENTER_POOLS['Enhanced'], Brainstorm.pseudoseed("Enhancedsta" .. ante_str .. seed_found))
			card.enhancement = enh and enh.key or "none"
		else
			card.enhancement = "none"
		end
	end

	-- Get base card (rank and suit) from 52-card deck
	if G.P_CARDS then
		local base_card = pseudorandom_element(G.P_CARDS, Brainstorm.pseudoseed("frontsta" .. ante_str .. seed_found))
		card.base = base_card and base_card.value or "unknown"
		card.suit = base_card and base_card.suit or "unknown"
	else
		card.base = "unknown"
		card.suit = "unknown"
	end

	-- Edition check: Polychrome (0.988-1.0), Holographic (0.96-0.988), Foil (0.92-0.96), None (0-0.92)
	local edition_poll = pseudorandom(Brainstorm.pseudoseed("standard_edition" .. ante_str .. seed_found))
	if edition_poll > 0.988 then
		card.edition = "e_polychrome"
	elseif edition_poll > 0.96 then
		card.edition = "e_holo"
	elseif edition_poll > 0.92 then
		card.edition = "e_foil"
	else
		card.edition = "none"
	end

	-- Seal check (80% chance of no seal, 20% chance of having one)
	local has_seal_poll = pseudorandom(Brainstorm.pseudoseed("stdseal" .. ante_str .. seed_found))
	if has_seal_poll <= 0.8 then
		card.seal = "none"
	else
		-- Has seal - Red (0.75-1.0), Blue (0.5-0.75), Gold (0.25-0.5), Purple (0-0.25)
		local seal_poll = pseudorandom(Brainstorm.pseudoseed("stdsealtype" .. ante_str .. seed_found))
		if seal_poll > 0.75 then
			card.seal = "Red"
		elseif seal_poll > 0.5 then
			card.seal = "Blue"
		elseif seal_poll > 0.25 then
			card.seal = "Gold"
		else
			card.seal = "Purple"
		end
	end

	return card
end

-- Check if any pack in ante 1 contains polychrome gold/steel red-seal face card
function Brainstorm.check_god_king(seed_found)
	-- Check multiple pack iterations in ante 1 (packs can be rerolled in shop)
	for pack_iter = 1, 4 do
		local pack = Brainstorm.simulate_pack(seed_found, 1, pack_iter)

		if pack and (pack.key == "p_standard_normal_1" or pack.key == "p_standard_jumbo_1" or pack.key == "p_standard_mega_1") then
			-- This is a standard pack, check cards in it
			local pack_size = pack.size or 3

			for i = 1, pack_size do
				local card = Brainstorm.simulate_standard_card(seed_found, 1, i)

				-- Check if this card matches our criteria:
				-- Any face card (K, Q, J) + Any suit + Gold or Steel enhancement + Polychrome edition + Red seal
				local is_face_card = (card.base == "King" or card.base == "Queen" or card.base == "Jack")
				local is_gold_or_steel = (card.enhancement == "m_gold" or card.enhancement == "m_steel")
				local is_polychrome = (card.edition == "e_polychrome")
				local is_red_seal = (card.seal == "Red")

				if is_face_card and is_gold_or_steel and is_polychrome and is_red_seal then
					return true
				end
			end
		end
	end

	return false
end

-- Helper function to get default pack size based on pack key
function Brainstorm.get_pack_size(pack_key)
	-- Default pack sizes for different pack types
	local pack_sizes = {
		-- Arcana packs
		p_arcana_normal_1 = 3,
		p_arcana_jumbo_1 = 5,
		p_arcana_mega_1 = 5,
		-- Celestial packs
		p_celestial_normal_1 = 3,
		p_celestial_jumbo_1 = 5,
		p_celestial_mega_1 = 5,
		-- Standard packs
		p_standard_normal_1 = 3,
		p_standard_jumbo_1 = 5,
		p_standard_mega_1 = 5,
		-- Buffoon packs
		p_buffoon_normal_1 = 2,
		p_buffoon_jumbo_1 = 4,
		p_buffoon_mega_1 = 4,
		-- Spectral packs
		p_spectral_normal_1 = 2,
		p_spectral_jumbo_1 = 4,
		p_spectral_mega_1 = 4,
	}
	return pack_sizes[pack_key] or 2
end

-- Simulate pack generation for a given iteration
-- pack_iteration: 1 for first pack, 2-4 for subsequent rerolls
function Brainstorm.simulate_pack(seed_found, ante, pack_iteration)
	if not G.P_CENTER_POOLS or not G.P_CENTER_POOLS['Booster'] then
		return nil
	end

	-- Use the same logic as searchPack filter
	local cume, it, center = 0, 0, nil
	for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
		cume = cume + (v.weight or 1)
	end

	-- Incorporate pack iteration into seed for different rerolls
	local pack_seed = "shop_pack" .. pack_iteration .. seed_found
	local poll = pseudorandom(Brainstorm.pseudoseed(pack_seed)) * cume

	for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
		it = it + (v.weight or 1)
		if it >= poll and it - (v.weight or 1) <= poll then
			center = v
			break
		end
	end

	if center then
		local size = center.config and center.config.choose or Brainstorm.get_pack_size(center.key)
		return {key = center.key, size = size}
	end
	return nil
end

-- Simulate first pack generation (legacy function for backwards compatibility)
function Brainstorm.simulate_first_pack(seed_found)
	local pack = Brainstorm.simulate_pack(seed_found, 1, 1)
	return pack and pack.key or nil
end

G.FUNCS.change_search_tag = function(x)
	Brainstorm.SETTINGS.autoreroll.searchTagID = x.to_key
	Brainstorm.SETTINGS.autoreroll.searchTag = Brainstorm.SearchTagList[x.to_val]
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.change_search_pack = function(x)
	Brainstorm.SETTINGS.autoreroll.searchPackID = x.to_key
	Brainstorm.SETTINGS.autoreroll.searchPack = Brainstorm.SearchPackList[x.to_val]
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.change_search_soul_count = function(x)
	Brainstorm.SETTINGS.autoreroll.searchForSoul = x.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.change_seeds_per_frame = function(x)
	Brainstorm.SETTINGS.autoreroll.seedsPerFrameID = x.to_key
	Brainstorm.SETTINGS.autoreroll.seedsPerFrame = Brainstorm.seedsPerFrame[x.to_val]
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.toggle_blueprint_money_search = function(args)
	Brainstorm.SETTINGS.autoreroll.searchBlueprintMoney = args.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.toggle_blueprint_brainstorm_search = function(args)
	Brainstorm.SETTINGS.autoreroll.searchBlueprintBrainstorm = args.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.toggle_money_joker_search = function(args)
	Brainstorm.SETTINGS.autoreroll.searchMoneyJoker = args.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.toggle_god_king_search = function(args)
	Brainstorm.SETTINGS.autoreroll.searchGodKing = args.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.toggle_negative_blueprint_search = function(args)
	Brainstorm.SETTINGS.autoreroll.searchNegativeBlueprint = args.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.change_blueprint_brainstorm_max_ante = function(x)
	Brainstorm.SETTINGS.autoreroll.searchBlueprintBrainstormMaxAnteID = x.to_key
	Brainstorm.SETTINGS.autoreroll.searchBlueprintBrainstormMaxAnte = x.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.change_money_joker_max_ante = function(x)
	Brainstorm.SETTINGS.autoreroll.searchMoneyJokerMaxAnteID = x.to_key
	Brainstorm.SETTINGS.autoreroll.searchMoneyJokerMaxAnte = x.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.change_negative_blueprint_max_ante = function(x)
	Brainstorm.SETTINGS.autoreroll.searchNegativeBlueprintMaxAnteID = x.to_key
	Brainstorm.SETTINGS.autoreroll.searchNegativeBlueprintMaxAnte = x.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

Brainstorm.AUTOREROLL.autoRerollActive = false
Brainstorm.AUTOREROLL.rerollInterval = 0.01 -- Time interval between rerolls (in seconds)
Brainstorm.AUTOREROLL.rerollTimer = 0

function FastReroll()
	G.GAME.viewed_back = nil
	G.run_setup_seed = G.GAME.seeded
	G.challenge_tab = G.GAME and G.GAME.challenge and G.GAME.challenge_tab or nil
	G.forced_seed, G.setup_seed = nil, nil
	if G.GAME.seeded then
		G.forced_seed = G.GAME.pseudorandom.seed
	end
	local current_stake = G.GAME.stake
	local _seed = G.run_setup_seed and G.setup_seed or G.forced_seed or nil
	local _challenge = G.challenge_tab
	if not G.challenge_tab then
		_stake = current_stake or G.PROFILES[G.SETTINGS.profile].MEMORY.stake or 1
	else
		_stake = 1
	end
	G:delete_run()
	G:start_run({ stake = _stake, seed = _seed, challenge = _challenge })
end

function Brainstorm.auto_reroll()
	local rerollsThisFrame = 0
	-- This part is meant to mimic how Balatro rerolls for Gold Stake
	local extra_num = -0.561892350821
	local seed_found = nil
	while not seed_found and rerollsThisFrame < Brainstorm.SETTINGS.autoreroll.seedsPerFrame do
		rerollsThisFrame = rerollsThisFrame + 1
		extra_num = extra_num + 0.561892350821
		seed_found = random_string(
			8,
			extra_num
				+ G.CONTROLLER.cursor_hover.T.x * 0.33411983
				+ G.CONTROLLER.cursor_hover.T.y * 0.874146
				+ 0.412311010 * G.CONTROLLER.cursor_hover.time
		)
		Brainstorm.random_state = {
			hashed_seed = pseudohash(seed_found),
		}
		if Brainstorm.SETTINGS.autoreroll.searchTag ~= "" then
			_tag = pseudorandom_element(G.P_CENTER_POOLS["Tag"], Brainstorm.pseudoseed("Tag1" .. seed_found)).key
			if _tag ~= Brainstorm.SETTINGS.autoreroll.searchTag then
				seed_found = nil
			end
		end
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchForSoul then
			-- Check if arcana pack from skip has The Soul
			for i = 1, Brainstorm.SETTINGS.autoreroll.searchForSoul do
				local soul_found = false
				for i = 1, 5 do
					if pseudorandom(Brainstorm.pseudoseed("soul_Tarot1" .. seed_found)) > 0.997 then
						soul_found = true
					end
				end
				if not soul_found then
					seed_found = nil
					break
				end
			end
		end
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchPack and #Brainstorm.SETTINGS.autoreroll.searchPack > 0 then
		    local cume, it, center = 0, 0, nil
			for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
				if (not _type or _type == v.kind) then cume = cume + (v.weight or 1 ) end
			end
			local poll = pseudorandom(Brainstorm.pseudoseed("shop_pack1"..seed_found))*cume
			for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
				if not _type or _type == v.kind then it = it + (v.weight or 1) end
				if it >= poll and it - (v.weight or 1) <= poll then center = v
break end
			end
			local pack_found = false
			for i = 1, #Brainstorm.SETTINGS.autoreroll.searchPack do
				if Brainstorm.SETTINGS.autoreroll.searchPack[i] == center.key then
					pack_found = true
					break
				end
			end
			if not pack_found then
				seed_found = nil
			end
		end
		-- Custom filter: Blueprint/Brainstorm + Money Joker combo (legacy - for backwards compatibility)
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchBlueprintMoney then
			if not Brainstorm.check_blueprint_money_combo(seed_found) then
				seed_found = nil
			end
		end
		-- Custom filter: Blueprint/Brainstorm (separate)
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchBlueprintBrainstorm then
			local max_ante = Brainstorm.SETTINGS.autoreroll.searchBlueprintBrainstormMaxAnte or 1
			local has_bp = Brainstorm.check_blueprint_brainstorm(seed_found, max_ante)
			if not has_bp then
				seed_found = nil
			end
		end
		-- Custom filter: Money Joker (separate)
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchMoneyJoker then
			local max_ante = Brainstorm.SETTINGS.autoreroll.searchMoneyJokerMaxAnte or 1
			local has_money = Brainstorm.check_money_joker(seed_found, max_ante)
			if not has_money then
				seed_found = nil
			end
		end
		-- Custom filter: Polychrome Gold/Steel Red-Seal Face card in first standard pack
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchGodKing then
			local has_god_king = Brainstorm.check_god_king(seed_found)
			if has_god_king then
				print("[Brainstorm] Found God King card in seed: " .. seed_found)
			end
			if not has_god_king then
				seed_found = nil
			end
		end
		-- Custom filter: Negative Blueprint/Brainstorm
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchNegativeBlueprint then
			local max_ante = Brainstorm.SETTINGS.autoreroll.searchNegativeBlueprintMaxAnte or 1
			local has_negative = Brainstorm.check_negative_blueprint_brainstorm(seed_found, max_ante)
			if not has_negative then
				seed_found = nil
			end
		end
		--[[
		Relevant vanilla pack code
		    local cume, it, center = 0, 0, nil
			for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
				if (not _type or _type == v.kind) and not G.GAME.banned_keys[v.key] then cume = cume + (v.weight or 1 ) end
			end
			local poll = pseudorandom(pseudoseed((_key or 'pack_generic')..G.GAME.round_resets.ante))*cume
			for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
				if not G.GAME.banned_keys[v.key] then 
					if not _type or _type == v.kind then it = it + (v.weight or 1) end
					if it >= poll and it - (v.weight or 1) <= poll then center = v; break end
				end
			end
			return center
		]]
	end
	if seed_found then
		_stake = G.GAME.stake
		G:delete_run()
		G:start_run({
			stake = _stake,
			seed = seed_found,
			challenge = G.GAME and G.GAME.challenge and G.GAME.challenge_tab,
		})
		G.GAME.seeded = false
	end
	return seed_found
end

function Brainstorm.searchParametersMet()
	--note: this appears to be deprecated, so I didn't update it
	if not G or not G.GAME or not G.GAME.round_resets or not G.GAME.round_resets.blind_tags then
		print("One or more variables are nil or undefined")
		return false
	end

	local _tag = G.GAME.round_resets.blind_tags.Small
	if not _tag then
		print("Value of _tag is nil or undefined")
		return false
	end

	if _tag == Brainstorm.SETTINGS.autoreroll.searchTag then
		if Brainstorm.SETTINGS.autoreroll.searchForSoul then
			return true
		end
		-- Check if arcana pack from skip has The Soul
		Brainstorm.random_state = copy_table(G.GAME.pseudorandom)
		for i = 1, 5 do
			if pseudorandom(Brainstorm.pseudoseed("soul_Tarot1")) > 0.997 then
				return true
			end
		end
		return false
	else
		return false
	end
end

function wait(seconds)
	local start = os.clock()
	while os.clock() - start < seconds do
		-- Busy wait
	end
end

function Brainstorm.pseudoseed(key, predict_seed)
	if key == "seed" then
		return math.random()
	end

	if predict_seed then
		local _pseed = pseudohash(key .. (predict_seed or ""))
		_pseed = math.abs(tonumber(string.format("%.13f", (2.134453429141 + _pseed * 1.72431234) % 1)))
		return (_pseed + (pseudohash(predict_seed) or 0)) / 2
	end

	if not Brainstorm.random_state[key] then
		Brainstorm.random_state[key] = pseudohash(key .. (Brainstorm.random_state.seed or ""))
	end

	Brainstorm.random_state[key] =
		math.abs(tonumber(string.format("%.13f", (2.134453429141 + Brainstorm.random_state[key] * 1.72431234) % 1)))
	return (Brainstorm.random_state[key] + (Brainstorm.random_state.hashed_seed or 0)) / 2
end

--Used for reroll UI
--Based on Balatro's attention_text
function Brainstorm.attention_text(args)
    args = args or {}
    args.text = args.text or 'test'
    args.scale = args.scale or 1
    args.colour = copy_table(args.colour or G.C.WHITE)
    args.hold = (args.hold or 0) + 0.1*(G.SPEEDFACTOR)
    args.pos = args.pos or {x = 0, y = 0}
    args.align = args.align or 'cm'
    args.emboss = args.emboss or nil

    args.fade = 1

    if args.cover then
      args.cover_colour = copy_table(args.cover_colour or G.C.RED)
      args.cover_colour_l = copy_table(lighten(args.cover_colour, 0.2))
      args.cover_colour_d = copy_table(darken(args.cover_colour, 0.2))
    else
      args.cover_colour = copy_table(G.C.CLEAR)
    end

    args.uibox_config = {
      align = args.align or 'cm',
      offset = args.offset or {x=0,y=0}, 
      major = args.cover or args.major or nil,
    }

    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      delay = 0,
      blockable = false,
      blocking = false,
      func = function()
          args.AT = UIBox{
            T = {args.pos.x,args.pos.y,0,0},
            definition = 
              {n=G.UIT.ROOT, config = {align = args.cover_align or 'cm', minw = (args.cover and args.cover.T.w or 0.001) + (args.cover_padding or 0), minh = (args.cover and args.cover.T.h or 0.001) + (args.cover_padding or 0), padding = 0.03, r = 0.1, emboss = args.emboss, colour = args.cover_colour}, nodes={
                {n=G.UIT.O, config={draw_layer = 1, object = DynaText({scale = args.scale, string = args.text, maxw = args.maxw, colours = {args.colour},float = true, shadow = true, silent = not args.noisy, args.scale, pop_in = 0, pop_in_rate = 6, rotate = args.rotate or nil})}},
              }}, 
            config = args.uibox_config
          }
          args.AT.attention_text = true

          args.text = args.AT.UIRoot.children[1].config.object
          args.text:pulse(0.5)

          if args.cover then
            Particles(args.pos.x,args.pos.y, 0,0, {
              timer_type = 'TOTAL',
              timer = 0.01,
              pulse_max = 15,
              max = 0,
              scale = 0.3,
              vel_variation = 0.2,
              padding = 0.1,
              fill=true,
              lifespan = 0.5,
              speed = 2.5,
              attach = args.AT.UIRoot,
              colours = {args.cover_colour, args.cover_colour_l, args.cover_colour_d},
          })
          end
          if args.backdrop_colour then
            args.backdrop_colour = copy_table(args.backdrop_colour)
            Particles(args.pos.x,args.pos.y,0,0,{
              timer_type = 'TOTAL',
              timer = 5,
              scale = 2.4*(args.backdrop_scale or 1), 
              lifespan = 5,
              speed = 0,
              attach = args.AT,
              colours = {args.backdrop_colour}
            })
          end
          return true
      end
      }))
      return args
end

function Brainstorm.remove_attention_text(args)
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0,
        blockable = false,
        blocking = false,
        func = function()
          if not args.start_time then
            args.start_time = G.TIMERS.TOTAL
            args.text:pop_out(3)
          else
            --args.AT:align_to_attach()
            args.fade = math.max(0, 1 - 3*(G.TIMERS.TOTAL - args.start_time))
            if args.cover_colour then args.cover_colour[4] = math.min(args.cover_colour[4], 2*args.fade) end
            if args.cover_colour_l then args.cover_colour_l[4] = math.min(args.cover_colour_l[4], args.fade) end
            if args.cover_colour_d then args.cover_colour_d[4] = math.min(args.cover_colour_d[4], args.fade) end
            if args.backdrop_colour then args.backdrop_colour[4] = math.min(args.backdrop_colour[4], args.fade) end
            args.colour[4] = math.min(args.colour[4], args.fade)
            if args.fade <= 0 then
              args.AT:remove()
              return true
            end
          end
        end
      }))
end