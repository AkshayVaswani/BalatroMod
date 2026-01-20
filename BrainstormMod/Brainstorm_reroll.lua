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

	-- Simulate up to 4 shop slots (standard shops have 2 jokers, but we check more to be thorough)
	for slot = 1, 4 do
		-- Determine if this slot is a joker (vs tarot/planet/spectral)
		-- Use "cdt" + ante as the seed string (Card_Type from Immolate)
		local card_type_poll = pseudorandom(Brainstorm.pseudoseed("cdt" .. ante .. seed_found))

		-- Shop instance rates: 20 for jokers, 4 for tarots, 4 for planets, 0 for playing cards, 0 for spectrals
		-- Total rate = 28, so joker threshold is 20/28 ≈ 0.714
		if card_type_poll < 0.714 then
			-- This slot contains a joker
			local joker_key = Brainstorm.get_shop_joker(seed_found, ante)
			if joker_key then
				table.insert(jokers_found, joker_key)
			end
		end
	end

	return jokers_found
end

-- Get a shop joker for a given seed and ante
-- Uses weighted selection similar to booster pack generation
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
			return center.key
		end
	end

	return nil
end

-- Check if Blueprint/Brainstorm + money joker combo exists in first 2 antes
function Brainstorm.check_blueprint_money_combo(seed_found)
	local has_blueprint = false
	local has_money_joker = false

	-- Check both ante 1 and ante 2 shops
	for ante = 1, 2 do
		local jokers = Brainstorm.simulate_shop_jokers(seed_found, ante)

		for _, joker_key in ipairs(jokers) do
			-- Check for Blueprint or Brainstorm
			if joker_key == "j_blueprint" or joker_key == "j_brainstorm" then
				has_blueprint = true
			end

			-- Check for money generating joker
			if Brainstorm.is_joker_in_list(joker_key, Brainstorm.MONEY_JOKERS) then
				has_money_joker = true
			end
		end

		-- Early exit if we found both
		if has_blueprint and has_money_joker then
			return true
		end
	end

	return has_blueprint and has_money_joker
end

-- Check if a legendary joker exists in first 2 antes
function Brainstorm.check_legendary_joker(seed_found)
	-- Check both ante 1 and ante 2 shops
	for ante = 1, 2 do
		local jokers = Brainstorm.simulate_shop_jokers(seed_found, ante)

		for _, joker_key in ipairs(jokers) do
			-- Check if this joker is legendary (rarity 4)
			if G.P_CENTER_POOLS and G.P_CENTER_POOLS['Joker'] then
				for k, v in ipairs(G.P_CENTER_POOLS['Joker']) do
					if v.key == joker_key then
						local joker_rarity = v.rarity or (v.config and v.config.rarity) or (v.config and v.config.center and v.config.center.rarity)
						if joker_rarity == 4 then
							return true
						end
						break
					end
				end
			end
		end
	end

	return false
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

-- Check if first standard pack contains polychrome gold red-seal King of Spades
function Brainstorm.check_god_king(seed_found)
	-- First, check if first pack is a standard pack
	local first_pack = Brainstorm.simulate_first_pack(seed_found)

	if not first_pack then
		return false
	end

	-- Check if it's a standard pack and determine pack size
	local pack_size = 0
	if first_pack == "p_standard_normal_1" then
		pack_size = 3
	elseif first_pack == "p_standard_jumbo_1" or first_pack == "p_standard_mega_1" then
		pack_size = 5
	else
		return false -- Not a standard pack
	end

	-- Simulate each card in the pack
	for i = 1, pack_size do
		local card = Brainstorm.simulate_standard_card(seed_found, 1, i)

		-- Check if this card matches our criteria:
		-- King of Spades + Gold enhancement + Polychrome edition + Red seal
		local is_king_spades = (card.base == "King" and card.suit == "Spades")
		local is_gold = (card.enhancement == "m_gold")
		local is_polychrome = (card.edition == "e_polychrome")
		local is_red_seal = (card.seal == "Red")

		if is_king_spades and is_gold and is_polychrome and is_red_seal then
			return true
		end
	end

	return false
end

-- Simulate first pack generation
function Brainstorm.simulate_first_pack(seed_found)
	-- Use the same logic as searchPack filter
	local cume, it, center = 0, 0, nil
	for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
		cume = cume + (v.weight or 1)
	end
	local poll = pseudorandom(Brainstorm.pseudoseed("shop_pack1" .. seed_found)) * cume
	for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
		it = it + (v.weight or 1)
		if it >= poll and it - (v.weight or 1) <= poll then
			center = v
			break
		end
	end

	if center then
		return center.key
	end
	return nil
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

G.FUNCS.toggle_legendary_search = function(args)
	Brainstorm.SETTINGS.autoreroll.searchLegendary = args.to_val
	nativefs.write(lovely.mod_dir .. "/Brainstorm/settings.lua", STR_PACK(Brainstorm.SETTINGS))
end

G.FUNCS.toggle_god_king_search = function(args)
	Brainstorm.SETTINGS.autoreroll.searchGodKing = args.to_val
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
		-- Custom filter: Blueprint/Brainstorm + Money Joker in first 2 antes
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchBlueprintMoney then
			if not Brainstorm.check_blueprint_money_combo(seed_found) then
				seed_found = nil
			end
		end
		-- Custom filter: Legendary joker in first 2 antes
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchLegendary then
			if not Brainstorm.check_legendary_joker(seed_found) then
				seed_found = nil
			end
		end
		-- Custom filter: Polychrome Gold Red-Seal King of Spades in first standard pack
		if seed_found and Brainstorm.SETTINGS.autoreroll.searchGodKing then
			if not Brainstorm.check_god_king(seed_found) then
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