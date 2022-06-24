local S = minercantile.get_translator


local shop_sell = {} --formspec temporary variables
local shop_buy = {}
local shop_admin = {}

minercantile.shop.max_stock = 20000 --shop don't buy infinity items
minercantile.shop.shop = {}
minercantile.registered_items = {}
--shop type
minercantile.shop.shop_type = {"General", "Armors", "Beds", "Boats", "Brick", "Carts", "Chest", "Cobble", "Columnia", "Decor", "Doors", "Dye", "Farming", "Fences", "Fishing", "Flowers", "Furnaces", "Glass", "Ingot", "Mesecons", "Nether", "Runes", "Sea", "Sign", "Stair_Slab", "Stone", "Tools", "Wood", "Wool"}

minercantile.shop.shop_sorted = {
	Armors = { groups = {"armor_heal"}, regex={"sword", "throwing", "spears"}},
	Beds = { groups = {"bed"}, regex={":bed"}},
	Boats = { groups = {}, regex={"boats"}},
	Brick = { groups = {}, regex={"brick"}},
	Carts = { groups = {"rail", "connect_to_raillike"}, regex={"cart"}},
	Chest = { groups = {}, regex={"chest"}},
	Cobble = { groups = {}, regex={"cobble"}},
	Columnia = { groups = {}, regex={"columnia"}},
	Decor = { groups = {}, regex={"decor"}},
	Doors = { groups = {}, regex={"door"}},
	Dye = { groups = {"dye"}, regex={}},
	Farming = { groups = {}, regex={"farming", "food"}},
	Fences = { groups = {"fence", "fences", "wall"}, regex={}},
	Flowers  = { groups = {"flora", "flower"}, regex={}},
	Fishing = { groups = {}, regex={"fishing"}},
	Furnaces = { groups = {}, regex={"furnace"}},
	Glass = { groups = {}, regex={"glass"}},
	Ingot = { groups = {"ingot"}, regex={"lump", ":diamond", ":nyancat", ":mese"}},
	--Leaves = { groups = {"leaves"}, regex={}},
	Mesecons = { groups = {}, regex={"mesecon", "pipeworks"}},
	Nether = { groups = {"nether"}, regex={}},
	Runes = { groups = {"amulet", "magic", "rune"}, regex={}},
	Sea = { groups = {"sea", "seaplants", "seacoral"}, regex={}},
	Sign = { groups = {}, regex={"sign"}},
	Stair_Slab = { groups = {"stair", "slab"}, regex={}},
	Stone = { groups = {"stone", "sand"}, regex={"stone", "cobble", "sand", "brick"}},
	Tools = { groups = {}, regex={":pick", ":axe", ":shovel", ":hoe", ":bag"}},
	Wood = { groups = {"wood", "coloredsticks", "leaves", "stick", "tree", "tree_root", "sapling"}, regex={}},
	Wool = { groups = {"wool"}, regex={"cotton"}},
}


--function shop money
function minercantile.shop.get_money()
	return (minercantile.stock.money or 0)
end

function minercantile.shop.take_money(money)
	minercantile.stock.money = minercantile.shop.get_money() - money
	if minercantile.shop.get_money() < 0 then
		minercantile.stock.money = 0
	end
end

function minercantile.shop.give_money(money)
	minercantile.stock.money = minercantile.shop.get_money() + money
end

function minercantile.shop.get_nb(itname)
	if minercantile.stock.items[itname] then
		return minercantile.stock.items[itname].nb
	end
	return 0
end

function minercantile.shop.get_transac_b()
	return minercantile.stock.transac_b
end

function minercantile.shop.get_transac_s()
	return minercantile.stock.transac_s
end


function minercantile.shop.set_transac_b()
	minercantile.stock.transac_b = minercantile.stock.transac_b + 1
end

function minercantile.shop.set_transac_s()
	minercantile.stock.transac_s = minercantile.stock.transac_s + 1
end

function minercantile.shop.is_available(itname)
	if minercantile.registered_items[itname] then
		return true
	end
	return false
end

function minercantile.shop.get_item_desc(itname)
	if minercantile.registered_items[itname] then
		return minercantile.registered_items[itname].desc
	end
	return itname
end

function minercantile.shop.get_defined_price(itname)
	if minercantile.registered_items[itname] then
		if minercantile.stock.items[itname].price ~= nil then
			return minercantile.stock.items[itname].price
		end
	end
	return 0
end

function minercantile.shop.set_defined_price(itname, price)
	if minercantile.registered_items[itname] then
		if not minercantile.stock.items[itname] then
			minercantile.stock.items[itname] = {nb=0}
		end
		if price > 0 then
			minercantile.stock.items[itname].price = price
		elseif minercantile.stock.items[itname].price ~= nil then
			minercantile.stock.items[itname].price = nil
		end
		return true
	end
	return false
end


function minercantile.shop.is_shop_type(itname, def, shop_def)
	for _, group in pairs(shop_def.groups) do
		if def.groups[group] then
			return true
		end
	end
	for _, regex in pairs(shop_def.regex) do
		if regex ~= "" and itname:find(regex) then
			return true
		end
	end
	return false
end


-- table of sellable/buyable items,ignore admin stuff
function minercantile.shop.register_items()
	minercantile.registered_items = {}
	minercantile.shop.register_whitelist()

	for itname, def in pairs(minetest.registered_items) do
		if not itname:find("maptools:") --ignore maptools
		and not itname:find("_coin")
		and not def.groups.not_in_creative_inventory
		and not def.groups.unbreakable
		and (def.description and def.description ~= "") then
			minercantile.registered_items[itname] = {groups = def.groups, desc = def.description}
		end
	end

	minercantile.shop.shop["General"] = {}
	for itname, def in pairs(minercantile.registered_items) do
		table.insert(minercantile.shop.shop["General"], itname)
		for shop, shop_def in pairs(minercantile.shop.shop_sorted) do
			if not minercantile.shop.shop[shop] then
				minercantile.shop.shop[shop] = {}
			end
			if minercantile.shop.is_shop_type(itname, def, shop_def) then
				table.insert(minercantile.shop.shop[shop], itname)
			end
		end
	end
end


function minercantile.shop.register_whitelist()
	for _, itname in pairs(minercantile.shop.items_whitelist) do
		local def = minetest.registered_items[itname]
		if def then
			minercantile.registered_items[itname] = {groups = def.groups, desc = def.description}
		end
	end
end


function minercantile.shop.add_item(itname, nb)
	if minercantile.shop.is_available(itname) then
		if not minercantile.stock.items[itname] then
			minercantile.stock.items[itname] = {nb=0}
		end
		minercantile.stock.items[itname].nb = minercantile.stock.items[itname].nb + nb
	end
end

function minercantile.shop.del_item(itname, nb)
	if minercantile.shop.is_available(itname) then
		if not minercantile.stock.items[itname] then
			minercantile.stock.items[itname] = {nb=0}
		end
		minercantile.stock.items[itname].nb = minercantile.stock.items[itname].nb - nb
		if minercantile.stock.items[itname].nb < 0 then
			minercantile.stock.items[itname].nb = 0
		end
	end
end


--function save items_base
function minercantile.save_stock_base()
	local input, err = io.open(minercantile.file_stock_base, "w")
	if input then
		input:write(minetest.serialize(minercantile.stock_base))
		input:close()
	else
		minetest.log("error", "open(" .. minercantile.file_stock_base .. ", 'w') failed: " .. err)
	end
end

--function load items_base from file
function minercantile.load_stock_base()
	local file = io.open(minercantile.file_stock_base, "r")
	if file then
		local data = minetest.deserialize(file:read("*all"))
		file:close()
		if data and type(data) == "table" then
			minercantile.stock_base = table.copy(data)
			if minercantile.stock_base.money then
				minercantile.stock.money = minercantile.stock_base.money
			end
			if minercantile.stock_base.items then
				for itname, def in pairs(minercantile.stock_base.items) do
					minercantile.stock.items[itname] = table.copy(def)
				end
			end
		end
	end
end

--function save stock items
function minercantile.save_stock()
	local input, err = io.open(minercantile.file_stock, "w")
	if input then
		input:write(minetest.serialize(minercantile.stock))
		input:close()
	else
		minetest.log("error", "open(" .. minercantile.file_stock .. ", 'w') failed: " .. err)
	end
end

--function load stock items from file
function minercantile.load_stock()
	local file = io.open(minercantile.file_stock, "r")
	if file then
		local data = minetest.deserialize(file:read("*all"))
		file:close()
		if data and type(data) == "table" then
			if data.money then
				minercantile.stock.money = data.money
			end
			if data.items then
				for itname, def in pairs(data.items) do
					minercantile.stock.items[itname] = table.copy(def)
				end
			end
			if data.transac_b then
				minercantile.stock.transac_b = data.transac_b
			end
			if data.transac_s then
				minercantile.stock.transac_s = data.transac_s
			end
		end
	end
end

--create list items for formspec (search/pages)
function minercantile.shop.set_items_buy_list(name, shop_type)
	shop_buy[name] = {page=1, search="", shop_type=shop_type}
	shop_buy[name].items_type = {}
	if minercantile.shop.shop[shop_type] then
		for _, itname in ipairs(minercantile.shop.shop[shop_type]) do
			if minercantile.shop.is_available(itname) and minercantile.shop.get_nb(itname) > 0 then
				table.insert(shop_buy[name].items_type, itname)
			end
		end
		table.sort(shop_buy[name].items_type)
	end
end


-- sell fonction
function minercantile.shop.get_buy_price(shop_type, itname)
	local price
	local money = minercantile.shop.get_money()
	if not minercantile.stock.items[itname] then
		minercantile.stock.items[itname] = {nb=0}
	end

	local nb = minercantile.stock.items[itname].nb
	if minercantile.stock.items[itname].price ~= nil then -- if defined price
		price = math.ceil(minercantile.stock.items[itname].price)
	else
		price = math.ceil((money/1000)/((0.001*(2340+nb-99))^3.9)/13) -- was price = math.ceil((money/1000)/(math.log(nb+2000-99)*10)*1000000/(math.pow((nb+2000-99),(2.01))))
	end
	if price and shop_type ~= "General" then--specific shop sell -10%
		local pct = math.ceil((price * 10)/100)
		price = math.ceil(price - pct)
	end
	if price and price < 1 then price = 1 end
	return price
end


-- sell fonction
function minercantile.shop.get_sell_price(itname, wear)
	local price
	local money = minercantile.shop.get_money()
	if not minercantile.stock.items[itname] then
		minercantile.stock.items[itname] = {nb=0}
	end

	local nb = minercantile.stock.items[itname].nb

	if minercantile.stock.items[itname].price ~= nil then -- if defined price
		price = math.floor(minercantile.stock.items[itname].price)
	else
		price = math.floor((money/1000)/((0.001*(2340+nb+99))^3.9)/13) --was price = math.floor(((money/1000)/(math.log(nb+2000+99)*10)*1000000/(math.pow((nb+2000+99),(2.01))))+0.5)
	end

	if wear and wear > 0 then --calcul price with % wear, (0-65535)
		local pct = math.ceil(((65535-wear)*100)/65535)
		price = math.floor((price * pct)/100)
	end

	if price < 1 then price = 1 end
	return price
end


local function set_pages_by_search(name, search)
	shop_buy[name].page = 1
	shop_buy[name].search = search
	shop_buy[name].items_list = {}
	
	local player_info = minetest.get_player_information(name)
	local lang = player_info and player_info.lang_code or ""
	local can_translate = minetest.get_translated_string and lang ~= ""

	for _, itname in ipairs(shop_buy[name].items_type) do
		if minercantile.shop.get_nb(itname) > 0 then
			local item = minercantile.registered_items[itname]
			if item then
				if string.find(itname, search) or string.find(string.lower(item.desc), search) or 
				can_translate and string.find(string.lower(minetest.get_translated_string(lang, item.desc)), search) then
					table.insert(shop_buy[name].items_list, itname)
				end
			end
		end
	end
	table.sort(shop_buy[name].items_list)
end


local function get_shop_inventory_by_page(name)
	local page = shop_buy[name].page
	local search = shop_buy[name].search
	local nb_items, nb_pages
	local shop_type = shop_buy[name].shop_type or "General"
	local inv_list = {}
	if search ~= "" then
		nb_items = #shop_buy[name].items_list
		nb_pages = math.ceil(nb_items/32)
		if page > nb_pages then page = nb_pages end
		local index = (page*32)-32
		for i=1, 32 do
			local itname = shop_buy[name].items_list[index+i]
			if not itname then break end
			local nb = minercantile.shop.get_nb(itname)
			if nb > 0 then
				local price = minercantile.shop.get_buy_price(shop_type, itname)
				if price and price > 0 then
					table.insert(inv_list, {name=itname, nb=nb, price=price})
				end
			end
		end
	else
		nb_items = #shop_buy[name].items_type
		nb_pages = math.ceil(nb_items/32)
		if page > nb_pages then page = nb_pages end
		local index = (page*32)-32
		for i=1, 32 do
			local itname = shop_buy[name].items_type[index+i]
			if itname then
				local nb = minercantile.shop.get_nb(itname)
				if nb > 0 then
					local price = minercantile.shop.get_buy_price(shop_type, itname)
					if price and price > 0 then
						table.insert(inv_list, {name=itname, nb=nb, price=price})
					end
				end
			end
		end
	end
	shop_buy[name].nb_pages = nb_pages
	return inv_list
end


--buy
function minercantile.shop.buy(name, itname, nb, price)
	local player = minetest.get_player_by_name(name)
	if not player then return false end
	local player_inv = player:get_inventory()
	local player_money = minercantile.wallet.get_money(name)
	if player_money < 1 then
		minetest.show_formspec(name, "minercantile:confirmed", "size[6,3]bgcolor[#2A2A2A;]label[2.6,0;".. S("Shop").. "]"..
								"label[0,1;".. S("Sorry, you have not enough money.") .."]"..
								"button[1.3,2.1;1.5,1;return_buy;".. S("Return") .."]"..
								"button_exit[3.3,2.1;1.5,1;close;".. S("Close") .."]")
		return false
	end

	local items_nb = minercantile.stock.items[itname].nb
	local desc = minercantile.shop.get_item_desc(itname)
	if items_nb < 1 then
		minetest.show_formspec(name, "minercantile:confirmed", "size[6,3]bgcolor[#2A2A2A;]label[2.6,0;".. S("Shop") .."]"..
				"label[0,1;" .. S("Sorry, shop have 0 item @1.", desc).."]"..
				"button[1.3,2.1;1.5,1;return_buy;".. S("Return").."]"..
				"button_exit[3.3,2.1;1.5,1;close;".. S("Close") .."]")
		return false
	end

	local item_can_sell = nb
	if items_nb < 4 then
		item_can_sell = 1
	elseif items_nb/4 < nb then
		item_can_sell = math.floor(items_nb/4)
	end

	local price_total = math.floor(item_can_sell * price)
	local player_can_buy = item_can_sell
	if player_money < price_total then
		player_can_buy = math.floor(player_money/price)
	end

	local sell_price = player_can_buy * price
	local stack = ItemStack(itname.." "..player_can_buy)
	--player_inv:room_for_item("main", stack)
	local nn = player_inv:add_item("main", stack)
	local count = nn:get_count()
	if count > 0 then
		minetest.spawn_item(player:getpos(), {name=itname, count=count, wear=0, metadata=""})
	end

	minercantile.stock.items[itname].nb = minercantile.stock.items[itname].nb - player_can_buy
	minercantile.shop.set_transac_b()
	minercantile.shop.give_money(sell_price)

	minercantile.wallet.take_money(name, sell_price, " ".. S("Purchase") .. " ".. player_can_buy .." "..desc..", ".. S("Price") .." "..sell_price.."$.")
	minetest.show_formspec(name, "minercantile:confirmed", "size[6,3]bgcolor[#2A2A2A;]"..
		"label[2.5,0;".. S("Shop") .."]"..
		"label[0,0.8;".. S("You buy @1 @2.", player_can_buy, desc) .."]"..
		"label[0,1.3;".. S("Price: @1$.", sell_price) .."]"..
		"button[1.3,2.1;1.5,1;return_buy;".. S("Return") .."]"..
		"button_exit[3.3,2.1;1.5,1;close;".. S("Close") .."]")
	return true
end


local function show_formspec_to_buy(name)
	local player = minetest.get_player_by_name(name)
	if not player or not shop_buy[name] then return end
	local formspec = {"size[13,10]bgcolor[#2A2A2A;]label[6,0;".. S("Buy Items") .."]"}
	table.insert(formspec, "label[0,0;".. S("Your money: @1$", minercantile.wallet.get_money(name)) .."]")
	local inv_items = get_shop_inventory_by_page(name)
	table.insert(formspec, "label[0.8,1.4;".. S("Page: @1 of @2", shop_buy[name].page, shop_buy[name].nb_pages) .."]")
	if shop_buy[name].search ~= "" then
		table.insert(formspec, "label[3,1.4;".. S("Filter: @1", minetest.formspec_escape(shop_buy[name].search)) .."]")
	end
	local x = 0.8
	local y = 2
	local j = 1
	for i=1, 32 do
		local item = inv_items[i]
		if item then
			table.insert(formspec, "item_image_button["..x..","..y..";1,1;"..item.name..";buttonchoice_"..item.name..";"..item.nb.."]")
			table.insert(formspec, "label["..(x)..","..(y+0.8)..";"..item.price.."$]")
		else
			table.insert(formspec, "image["..x..","..y..";1,1;minercantile_img_inv.png]")
		end
		x = x +1.5
		j = j +1
		if j > 8 then
			j = 1
			x = 0.8
			y = y + 1.6
		end
	end

	table.insert(formspec, "field[5.75,8.75;2.2,1;searchbox;;]")
	table.insert(formspec, "image_button[7.55,8.52;.8,.8;minercantile_search_icon.png;searchbutton;]tooltip[searchbutton;".. S("Search") .."]")
	table.insert(formspec, "button[5.65,9.3;1,1;page_dec;<]tooltip[page_dec;".. S("Previous page") .."]")
	
	table.insert(formspec, "button[6.55,9.3;1,1;page_inc;>]tooltip[page_inc;".. S("Next page") .."]")
	table.insert(formspec, "button_exit[11,9.3;1.5,1;choice;".. S("Close").. "]")
	minetest.show_formspec(name, "minercantile:shop_buy",  table.concat(formspec))
end


local function get_formspec_buy_items(name)
	local itname = shop_buy[name].itname
	local nb = shop_buy[name].nb
	local price = shop_buy[name].price
	local formspec = {"size[8,6]bgcolor[#2A2A2A;]label[3.5,0;".. S("Buy Items") .."]"}
	table.insert(formspec, "label[3.4,1;".. S("Stock: @1", minercantile.shop.get_nb(itname)) .."]")
	table.insert(formspec, "item_image_button[3.6,1.5;1,1;"..itname..";buttonchoice_"..itname..";"..nb.."]")
	if minetest.registered_items[itname] and minetest.registered_items[itname].stack_max and minetest.registered_items[itname].stack_max == 1 then
		table.insert(formspec, "label[2.2,2.5;".. S("This item is being sold by 1 max.") .."]")
	else
		table.insert(formspec, "button[0.6,1.5;1,1;amount_dec_1;-1]")
		table.insert(formspec, "button[1.6,1.5;1,1;amount_dec_10;-10]")
		table.insert(formspec, "button[2.6,1.5;1,1;amount_dec_20;-20]")
		table.insert(formspec, "button[4.6,1.5;1,1;amount_inc_20;+20]")
		table.insert(formspec, "button[5.6,1.5;1,1;amount_inc_10;+10]")
		table.insert(formspec, "button[6.6,1.5;1,1;amount_inc_1;+1]")
	end
	table.insert(formspec, "label[3.2,3;".. S("Price: @1$.", price) .."]")
	table.insert(formspec, "label[3.2,3.4;".. S("Amount: @1 item(s).", nb) .."]")
	table.insert(formspec, "label[3.2,3.8;".. S("Total: @1$.",  nb * price) .."]")
	table.insert(formspec, "button[3.3,5;1.5,1;confirm;".. S("Confirm") .."]")
	table.insert(formspec, "button[0,0;1.5,1;abort;".. S("Return") .."]")
	return table.concat(formspec)
end


-- sell
function minercantile.shop.player_sell(name)
	local player = minetest.get_player_by_name(name)
	if not player then return false end
	local player_inv = player:get_inventory()
	local shop_money = minercantile.shop.get_money()

	if shop_money < 4 then
		minetest.show_formspec(name, "minercantile:confirmed", "size[6,3]bgcolor[#2A2A2A;]"..
			"label[2.6,0;".. S("Shop") .."]"..
			"label[0,1;" ..S("Sorry, shop have not enough money.") .."]"..
			"button[1.3,2.1;1.5,1;return_sell;".. S("Return") .."]"..
			"button_exit[3.3,2.1;1.5,1;close;".. S("Close") .."]")
		return false
	end
	local item = shop_sell[name].item
	local index = item.index
	local nb = shop_sell[name].nb
	local price = shop_sell[name].price
	local stack = player_inv:get_stack("main", index)
	local itname = stack:get_name()
	local items_nb = stack:get_count()
	local desc = minercantile.shop.get_item_desc(itname)
	
	if itname ~= item.name or items_nb == 0 then
		minetest.show_formspec(name, "minercantile:confirmed", "size[6,3]bgcolor[#2A2A2A;]"..
			"label[2.6,0;".. S("Shop") .."]"..
			"label[0,1;".. S("Sorry, You have 0 item @1.", desc) .."]"..
			"button[1.3,2.1;1.5,1;return_sell;".. S("Return") .."]"..
			"button_exit[3.3,2.1;1.5,1;close;".. S("Close") .."]")
		return false
	end

	local item_can_sell = nb
	if items_nb < nb then
		item_can_sell = items_nb
	end

	local price_total = math.floor(item_can_sell * price)
	local shop_can_buy = item_can_sell
	if (shop_money/4) < price_total then
		shop_can_buy = math.floor((shop_money/4)/price)
	end

	if shop_can_buy == 0 then
		minetest.show_formspec(name, "minercantile:confirmed", "size[6,3]bgcolor[#2A2A2A;]"..
			"label[2.6,0;".. S("Shop") .."]"..
			"label[0,1;".. S("Sorry, shop have not enough money.") .."]"..
			"button[1.3,2.1;1.5,1;return_sell;".. S("Return") .."]"..
			"button_exit[3.3,2.1;1.5,1;close;".. S("Close") .."]")
		return false
	end

	local taken = stack:take_item(shop_can_buy)
	local sell_price = math.floor((taken:get_count()) * price)
	player_inv:set_stack("main", index, stack)
	minercantile.stock.items[itname].nb = minercantile.stock.items[itname].nb + shop_can_buy
	minercantile.shop.set_transac_s()
	minercantile.shop.take_money(sell_price)

	minercantile.wallet.give_money(name, sell_price, " ".. S("Sale") .. " ".. shop_can_buy .." "..desc..", ".. S("Price") .." "..sell_price .."$.")
	minetest.show_formspec(name, "minercantile:confirmed", "size[6,3]bgcolor[#2A2A2A;]"..
		"label[2.6,0;".. S("Shop") .."]"..
		"label[0,0.8;".. S("You sell @1 @2.", shop_can_buy, desc) .."]"..
		"label[0,1.3;".. S("Price: @1$.", sell_price) .."]"..
		"button[1.3,2.1;1.5,1;return_sell;".. S("Return") .."]"..
		"button_exit[3.3,2.1;1.5,1;close;".. S("Close") .."]")
	return true
end

local function get_wear_img(wear)
	local pct = math.floor(((65535-wear)*10)/65535)
	for i=9, 0, -1 do
		if pct == i then
			return "minercantile_wear_".. i ..".png"
		end
	end
	return nil
end

-- show sell formspec
local function show_formspec_to_sell(name)
	local player = minetest.get_player_by_name(name)
	if not player then return end
	local formspec = {"size[13,10]bgcolor[#2A2A2A;]label[6,0;".. S("Sell Items") .."]"}
	table.insert(formspec, "label[0,0;".. S("Your money: @1$", minercantile.wallet.get_money(name)) .."]")
	local player_inv = player:get_inventory()
	shop_sell[name] = {}
	shop_sell[name].items = {}
	for i=1, player_inv:get_size("main") do
		local stack = player_inv:get_stack("main", i)
		if not stack:is_empty() then
			local itname = stack:get_name()
			if minercantile.shop.is_available(itname) and minercantile.shop.get_nb(itname) < minercantile.shop.max_stock then
				local nb = stack:get_count()
				local wear = stack:get_wear()
				local price = minercantile.shop.get_sell_price(itname, wear)
				if price and price > 0 then
					table.insert(shop_sell[name].items, {name=itname, nb=nb, price=price, index=i, wear=wear})
				end
			end
		end
	end
	local x = 0.8
	local y = 2
	local j = 1
	for i=1, 32 do
		local item = shop_sell[name].items[i]
		if item then
			table.insert(formspec, "item_image_button["..x..","..y..";1,1;"..item.name..";buttonchoice_"..i..";"..item.nb.."]")
			table.insert(formspec, "label["..(x)..","..(y+0.9)..";"..item.price.."$]")
			if item.wear and item.wear > 0 then
				local img = get_wear_img(item.wear)
				if img then
					table.insert(formspec, "image["..x..","..(y+0.1)..";1,1;"..img.."]")
				end
			end
		else
			table.insert(formspec, "image["..x..","..y..";1,1;minercantile_img_inv.png]")
		end
		x = x +1.5
		j = j + 1
		if j > 8 then
			j = 1
			x = 0.8
			y = y + 1.6
		end
	end
	table.insert(formspec, "button_exit[5.8,9.3;1.5,1;choice;".. S("Close") .."]")
	minetest.show_formspec(name, "minercantile:shop_sell",  table.concat(formspec))
end


local function get_formspec_sell_items(name)
	local item = shop_sell[name].item
	local itname = item.name
	local index = shop_sell[name].index
	local nb = shop_sell[name].nb
	local price = minercantile.shop.get_sell_price(itname, item.wear)
	shop_sell[name].price = price
	local formspec = {"size[8,6]bgcolor[#2A2A2A;]label[3.5,0;".. S("Sell Items") .."]"}
	table.insert(formspec, "item_image_button[3.6,1.5;1,1;"..itname..";buttonchoice_"..index..";"..nb.."]")
	if item.wear and item.wear > 0 then
		local img = get_wear_img(item.wear)
		if img then
			table.insert(formspec, "image[3.6,1.6;1,1;"..img.."]")
		end
	end

	if minetest.registered_items[itname] and minetest.registered_items[itname].stack_max and minetest.registered_items[itname].stack_max == 1 then
		table.insert(formspec, "label[2.2,2.5;".. S("This item is being sold by 1 max.") .."]")
	else
		table.insert(formspec, "button[0.6,1.5;1,1;amount_dec_1;-1]")
		table.insert(formspec, "button[1.6,1.5;1,1;amount_dec_10;-10]")
		table.insert(formspec, "button[2.6,1.5;1,1;amount_dec_20;-20]")
		table.insert(formspec, "button[4.6,1.5;1,1;amount_inc_20;+20]")
		table.insert(formspec, "button[5.6,1.5;1,1;amount_inc_10;+10]")
		table.insert(formspec, "button[6.6,1.5;1,1;amount_inc_1;+1]")
	end

	table.insert(formspec, "label[3.2,3;".. S("Price: @1$.", price) .."]")
	table.insert(formspec, "label[3.2,3.4;".. S("Amount: @1 item(s).", nb).."]")
	table.insert(formspec, "label[3.2,3.8;".. S("Total: @1$.", nb * price) .."]")
	table.insert(formspec, "button[3.3,5;1.5,1;confirm;".. S("Confirm") .."]")
	table.insert(formspec, "button[0,0;1.5,1;abort;".. S("Return") .."]")
	return table.concat(formspec)
end


local function get_formspec_welcome(name)
	local formspec = {"size[6,5]bgcolor[#2A2A2A;]label[2.6,0;".. S("Shop") .."]"}
		table.insert(formspec, "image[1,1;5,1.25;minercantile_shop_welcome.png]")
		table.insert(formspec, "label[1,2.5;".. S("Total purchases: @1", minercantile.shop.get_transac_b()).."]")
		table.insert(formspec, "label[1,3;".. S("Total sales: @1", minercantile.shop.get_transac_s()) .."]")
		table.insert(formspec, "button[1,4.3;1.5,1;choice_buy;".. S("Buy") .."]")
		table.insert(formspec, "button[3.5,4.3;1.5,1;choice_sell;".. S("Sell") .."]")
	return table.concat(formspec)
end

-- formspec admin shop
function minercantile.get_formspec_shop_admin_shop(pos, node_name, name)
	if not shop_admin[name] then
		shop_admin[name] = {}
	end
	shop_admin[name].pos = pos
	shop_admin[name].node_name = node_name

	local formspec = {"size[6,6]bgcolor[#2A2A2A;]label[0,0;".. S("Shop Admin") .."]"..
		"button[4.2,0;1.5,1;shop;".. S("Shop") .."]"}
	local isnode = minetest.get_node_or_nil(pos)
	if not isnode or isnode.name ~= node_name then return end
	local meta = minetest.get_meta(pos)
	local shop_type = meta:get_int("shop_type")
	table.insert(formspec, "label[0,1;".. S("Shop Type:") .."]")
	table.insert(formspec, "dropdown[3,1;3,1;select_type;"..table.concat(minercantile.shop.shop_type, ",")..";"..shop_type.."]")

	local isopen = meta:get_int("open")
	if isopen == 1 then
		table.insert(formspec, "label[0,2;".. S("Is Open: Yes") .."]"..
			"button[3.5,1.8;1.5,1;open_close_no;".. S("No") .."]")
	else
		table.insert(formspec, "label[0,2;".. S("Is Open: No") .."]"..
			"button[3.5,1.8;1.5,1;open_close_yes;".. S("Yes") .."]")
	end

	local always_open = meta:get_int("always_open")
	if always_open == 1 then
		table.insert(formspec, "label[0,3;".. S("Open 24/24: Yes").."]"..
			"button[3.5,2.8;1.5,1;always_open_no;".. S("No") .."]")
	else
		table.insert(formspec, "label[0,3;".. S("Open 24/24: No").."]"..
			"button[3.5,2.8;1.5,1;always_open_yes;".. S("Yes") .."]")
	end
	table.insert(formspec, "label[0,4;".. S("Shop money: @1$", minercantile.shop.get_money()).."]")
	table.insert(formspec, "button_exit[2.4,5.3;1.5,1;close;".. S("Close") .."]")
	return table.concat(formspec)
end


minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if not name or name == "" then return end
	if formname == "minercantile:shop_welcome" then
		if fields["choice_buy"] then
			show_formspec_to_buy(name)
		elseif fields["choice_sell"] then
			show_formspec_to_sell(name)
		end
		return
	elseif formname == "minercantile:shop_buy" then
		for b, n in pairs(fields) do
			if string.find(b, "buttonchoice_") then
				if not shop_buy[name] then return end
				local itname = string.sub(b, 14)
				shop_buy[name].itname = itname
				shop_buy[name].max = math.floor(minercantile.shop.get_nb(itname)/4)
				if minetest.registered_items[itname].stack_max and minetest.registered_items[itname].stack_max == 1 then
					shop_buy[name].max = 1
					shop_buy[name].nb = 1
				else
					shop_buy[name].max = math.floor(minercantile.shop.get_nb(itname)/4)
					shop_buy[name].nb = math.floor(minercantile.shop.get_nb(itname)/4)
				end
				if shop_buy[name].max > 99 then
					shop_buy[name].max = 99
				end
				if shop_buy[name].nb < 1 then
					shop_buy[name].nb = 1
				elseif shop_buy[name].nb > 99 then
					shop_buy[name].nb = 99
				end
				local shop_type = shop_buy[name].shop_type or "General"
				shop_buy[name].price = minercantile.shop.get_buy_price(shop_type, itname)
				minetest.show_formspec(name, "minercantile:shop_buy_items",  get_formspec_buy_items(name))
				return
			end
		end
		if fields["quit"] then
			return
		elseif fields["searchbutton"] then
			local search = string.sub(string.lower(minetest.formspec_escape(fields["searchbox"])), 1, 14)
			set_pages_by_search(name, search)
		elseif fields["page_inc"] then
			if shop_buy[name].page < shop_buy[name].nb_pages then
				shop_buy[name].page = shop_buy[name].page+1
			end
		elseif fields["page_dec"] then
			if shop_buy[name].page > 1 then
				shop_buy[name].page = shop_buy[name].page-1
			end
		end
		show_formspec_to_buy(name)
	elseif formname == "minercantile:shop_buy_items" then
		if fields["amount_inc_1"] or fields["amount_inc_10"] or fields["amount_inc_20"] or fields["amount_dec_1"] or fields["amount_dec_10"] or fields["amount_dec_20"] then
			local inc = 1
			if fields["amount_inc_1"] then
				inc = 1
			elseif fields["amount_inc_10"] then
				inc = 10
			elseif fields["amount_inc_20"] then
				inc = 20
			elseif fields["amount_dec_1"] then
				inc = -1
			elseif fields["amount_dec_10"] then
				inc = -10
			elseif fields["amount_dec_20"] then
				inc = -20			
			end
			
			if inc ~= nil then
				shop_buy[name].nb = shop_buy[name].nb + inc
			end
			if shop_buy[name].nb > 99 then
				shop_buy[name].nb = 99
			end
			if shop_buy[name].nb > shop_buy[name].max then
				 shop_buy[name].nb = shop_buy[name].max
			end
			if shop_buy[name].nb < 1 then
				 shop_buy[name].nb = 1
			end
		elseif fields["abort"] then
			show_formspec_to_buy(name)
			return
		elseif fields["confirm"] then
			if not shop_buy[name] or not shop_buy[name].itname or not shop_buy[name].nb or not shop_buy[name].price then return end
			minercantile.shop.buy(name, shop_buy[name].itname, shop_buy[name].nb, shop_buy[name].price)
			return
		elseif fields["quit"] then
			shop_buy[name] = nil
			return
		end
		minetest.show_formspec(name, "minercantile:shop_buy_items",  get_formspec_buy_items(name))
	elseif formname == "minercantile:shop_sell" then
		for b, n in pairs(fields) do
			if string.find(b, "buttonchoice_") then
				if not shop_sell[name] then
					shop_sell[name] = {}
				end
				local index = tonumber(string.sub(b, 14))
				shop_sell[name].index = index
				local item = shop_sell[name].items[index]
				shop_sell[name].item = item
				shop_sell[name].itname = item.name
				shop_sell[name].max = item.nb
				if shop_sell[name].max > 99 then
					shop_sell[name].max = 99
				end
				shop_sell[name].wear = item.wear
				shop_sell[name].nb = shop_sell[name].max
				shop_sell[name].price = minercantile.shop.get_sell_price(item.name, item.wear)
				minetest.show_formspec(name, "minercantile:shop_sell_items",  get_formspec_sell_items(name))
				break
			end
		end
		return
	elseif formname == "minercantile:shop_sell_items" then
		if fields["amount_inc_1"] or fields["amount_inc_10"] or fields["amount_inc_20"] or fields["amount_dec_1"] or fields["amount_dec_10"] or fields["amount_dec_20"] then
			local inc = 1
			if fields["amount_inc_1"] then
				inc = 1
			elseif fields["amount_inc_10"] then
				inc = 10
			elseif fields["amount_inc_20"] then
				inc = 20
			elseif fields["amount_dec_1"] then
				inc = -1
			elseif fields["amount_dec_10"] then
				inc = -10
			elseif fields["amount_dec_20"] then
				inc = -20			
			end
			if inc ~= nil then
				shop_sell[name].nb = shop_sell[name].nb + inc
			end
			if shop_sell[name].nb > shop_sell[name].max then
				 shop_sell[name].nb = shop_sell[name].max
			end
			if shop_sell[name].nb > 99 then
				shop_sell[name].nb = 99
			end
			if shop_sell[name].nb < 1 then
				 shop_sell[name].nb = 1
			end
		elseif fields["abort"] then
			show_formspec_to_sell(name)
			return
		elseif fields["confirm"] then
			minercantile.shop.player_sell(name)
			return
		elseif fields["quit"] then
			shop_sell[name] = nil
			return
		end
		minetest.show_formspec(name, "minercantile:shop_sell_items",  get_formspec_sell_items(name))
	elseif formname == "minercantile:confirmed" then
		if fields["return_sell"] then
			show_formspec_to_sell(name)
		elseif fields["return_buy"] then
			show_formspec_to_buy(name)
		end
	-- admin conf
	elseif formname == "minercantile:shop_admin_shop" then
		if fields["quit"] then
			shop_admin[name] = nil
			return
		elseif fields["shop"] then
			minetest.show_formspec(name, "minercantile:shop_welcome",  get_formspec_welcome(name))
			return
		end
		if not shop_admin[name] then return end
		local pos = shop_admin[name].pos
		local node_name = shop_admin[name].node_name
		local isnode = minetest.get_node_or_nil(pos)
		if not isnode or isnode.name ~= node_name then return end --FIXME
		local meta = minetest.get_meta(pos)

		if fields["open_close_yes"] or fields["open_close_no"] then
			local open = 0
			if fields["open_close_yes"] then
				open = 1
			end
			meta:set_int("open", open)
		elseif fields["always_open_no"] or fields["always_open_yes"]  then
			local always_open = 0
			if fields["always_open_yes"]  then
				always_open = 1
			end
			meta:set_int("always_open", always_open)
		elseif fields["select_type"] then
			for i, n in pairs(minercantile.shop.shop_type) do
				if n == fields["select_type"] then
					meta:set_int("shop_type", i)
					local t = string.gsub(n, "_$","")
					meta:set_string("infotext", S("@1 Shop", t))
					break
				end
			end
		end
		minetest.show_formspec(name, "minercantile:shop_admin_shop",  minercantile.get_formspec_shop_admin_shop(pos, node_name, name))
	end
end)


--Barter shop.
minetest.register_node("minercantile:shop", {
	description = S("Barter Shop"),
	tiles = {"minercantile_shop.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	paramtype2 = "facedir",
	drawtype = "mesh",
	mesh = "minercantile_shop.obj",
	paramtype = "light",
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("General Shop"))
		meta:set_int("open", 1)
		meta:set_int("always_open", 0)
		meta:set_int("shop_type", 1)
	end,
	can_dig = function(pos, player)
		local name = player:get_player_name()
		return (minetest.check_player_privs(name, {protection_bypass = true}) or minetest.check_player_privs(name, {shop = true}))
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local name = player:get_player_name()
		if not name or name == "" then return end
		local meta = minetest.get_meta(pos)
		local shop_type = minercantile.shop.shop_type[meta:get_int("shop_type")] or "General"
		minercantile.shop.set_items_buy_list(name, shop_type)
		if minetest.check_player_privs(name, {protection_bypass = true}) or minetest.check_player_privs(name, {shop = true}) then
			minetest.show_formspec(name, "minercantile:shop_admin_shop",  minercantile.get_formspec_shop_admin_shop(pos, node.name, name))
		else
			local isopen = meta:get_int("open")
			if (isopen and isopen == 1) then
				local always_open = meta:get_int("always_open")
				local tod = (minetest.get_timeofday() or 0) * 24000
				if always_open == 1 or (tod > 8000 and tod < 19000) then --FIXME check tod 8h-19h
					minetest.show_formspec(name, "minercantile:shop_welcome",  get_formspec_welcome(name))
				else
					minetest.show_formspec(name, "minercantile:closed", "size[6,3]bgcolor[#2A2A2A;]"..
						"label[2.4,0;".. S("Shop") .."]"..
						"label[1,1;".. S("Sorry, shop is closed.") .."]"..
						"label[1,1.5;".. S("Open only from 8am to 7pm.") .."]"..
						"button_exit[2.3,2.1;1.5,1;close;".. S("Close") .."]")
				end
			else
				minetest.show_formspec(name, "minercantile:closed", "size[6,3]bgcolor[#2A2A2A;]"..
					"label[2.6,0;".. S("Shop") .."]"..
					"label[1,1;".. S("Sorry, shop is closed.") .."]"..
					"button_exit[2.3,2.1;1.5,1;close;".. S("Close") .."]")
			end
		end
	end,
})


minetest.register_chatcommand("shop_addmoney",{
	params = S("<Amount>"),
	description = S("Add money to the shop"),
	privs = {shop = true},
	func = function(name, param)
		param = string.gsub(param, " ", "")
		local amount = tonumber(param)
		if amount == nil then
			minetest.chat_send_player(name, S("Invalid, you must add amount at param."))
			return
		end
		minercantile.shop.give_money(amount)
		minetest.chat_send_player(name, S("You add @1$, new total: @2$", amount, minercantile.shop.get_money()))
	end,
})

minetest.register_chatcommand("shop_delmoney",{
	params = S("<Amount>"),
	description = S("Delete money from the shop"),
	privs = {shop = true},
	func = function(name, param)
		param = string.gsub(param, " ", "")
		local amount = tonumber(param)
		if (amount  == nil ) then
			minetest.chat_send_player(name, S("Invalid, you must add amount at param."))
			return
		end
		minercantile.shop.take_money(amount)
		minetest.chat_send_player(name, S("You deleted @1$, new total: @2$.", amount, minercantile.shop.get_money()))
	end,
})

minetest.register_chatcommand("shop_additem",{
	params = S("<Itemname> <Number>"),
	description = S("Add item to the shop"),
	privs = {shop = true},
	func = function(name, param)
		if ( param == "" ) then
			minetest.chat_send_player(name, S("Invalid, missing param."))
			return
		end
		local itname, amount = param:match("^(%S+)%s(%S+)$")

		if itname == nil or amount == nil  then
			minetest.chat_send_player(name, S("Invalid, missing param."))
			return
		end
		if not minercantile.shop.is_available(itname) then
			minetest.chat_send_player(name, S("Invalid param, item unknow."))
			return
		end
		if amount == nil or not tonumber(amount) then
			minetest.chat_send_player(name, S("Invalid param amount."))
			return
		end
		amount = tonumber(amount)
		if amount < 1 then
			minetest.chat_send_player(name, S("Invalid param amount."))
			return
		end
		minercantile.shop.add_item(itname, amount)
		minetest.chat_send_player(name, S("You add @1 @2, new amount: @3.", amount, itname, minercantile.shop.get_nb(itname)))
	end,
})

minetest.register_chatcommand("shop_delitem",{
	params = S("<Itemname> <Number>"),
	description = S("Delete item from the shop"),
	privs = {shop = true},
	func = function(name, param)
		if ( param == "" ) then
			minetest.chat_send_player(name, S("Invalid, missing param."))
			return
		end
		local itname, amount = param:match("^(%S+)%s(%S+)$")
		if itname == nil or amount == nil  then
			minetest.chat_send_player(name, S("Invalid, missing param."))
			return
		end
		if not minercantile.shop.is_available(itname) then
			minetest.chat_send_player(name, S("Shop don't know item @1.", itname))
			return
		end
		if not tonumber(amount) then
			minetest.chat_send_player(name, S("Invalid param amount."))
			return
		end
		amount = tonumber(amount)
		if amount < 1 then
			minetest.chat_send_player(name, S("Invalid param amount."))
			return
		end
		minercantile.shop.del_item(itname, amount)
		minetest.chat_send_player(name, S("You deleted @1 @2, new amount: @3.", amount, itname, minercantile.shop.get_nb(itname)))
	end,
})


minetest.register_chatcommand("shop_getprice",{
	params = S("<Itemname>"),
	description = S("Get item price"),
	privs = {shop = true},
	func = function(name, param)
		if ( param == "" ) then
			minetest.chat_send_player(name, S("Invalid, missing param."))
			return
		end
		if not minercantile.shop.is_available(param) then
			minetest.chat_send_player(name, S("Shop don't know item @1.", param))
			return
		end
		local price = minercantile.shop.get_defined_price(param)
		if price > 0 then
			minetest.chat_send_player(name, S("The price of item @1 is defined to @2$.", param, price))
		else
			minetest.chat_send_player(name, S("Item @1 has no defined price.", param))
		end
	end,
})


minetest.register_chatcommand("shop_setprice",{
	params = S("<Itemname> <Price>"),
	description = S("Defines a fixed price"),
	privs = {shop = true},
	func = function(name, param)
		if ( param == "" ) then
			minetest.chat_send_player(name, S("Invalid, missing param."))
			return
		end
		local itname, price = param:match("^(%S+)%s(%S+)$")
		if itname == nil or price == nil  then
			minetest.chat_send_player(name, S("Invalid, missing param."))
			return
		end
		if not minercantile.shop.is_available(itname) then
			minetest.chat_send_player(name, S("Shop don't know item @1.", itname))
			return
		end
		
		if not tonumber(price) then
			minetest.chat_send_player(name, S("Invalid param price."))
			return
		end
		price = tonumber(price)
		if price < 0 then
			minetest.chat_send_player(name, S("Invalid param price."))
			return
		end
		
		minercantile.shop.set_defined_price(itname, price)
		local price = minercantile.shop.get_defined_price(itname)
		if price > 0 then
			minetest.chat_send_player(name, S("The price of item @1 is now defined to @2$.", itname, price))
		else
			minetest.chat_send_player(name, S("Item @1 has no defined price.", itname))
		end
	end,
})

