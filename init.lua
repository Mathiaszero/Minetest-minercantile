-----------------------------------------------------------------------------------------------
local version 	= "2.0.0"
local mname		= "minercantile"

minetest.log("action","[Mod] ".. mname .." Loading...")

local S = minetest.get_translator(minetest.get_current_modname())

minercantile = {}
minercantile.isloaded = false
minercantile.get_translator = S

minetest.register_privilege("shop", S("Can place|dig|configure shop"))
--path
minercantile.path = minetest.get_worldpath()
minercantile.path_wallet =  minercantile.path.. "/minercantile_wallet/"
minercantile.file_stock_base = minercantile.path.."/minercantile_stock_base.txt"
minercantile.file_stock = minercantile.path.."/minercantile_stock.txt"
minetest.mkdir(minercantile.path_wallet)

--items
minercantile.shop = {}
minercantile.shop.items_inventory = {}
minercantile.shop.items_whitelist = {}

--stock items
minercantile.stock_base = {}
minercantile.stock = {} -- table saved money, items list
minercantile.stock.items = {}
minercantile.stock.money = 1000000
minercantile.stock.transac_b = 0
minercantile.stock.transac_s = 0

--functions specific to wallet
minercantile.wallet = {}
-- table players wallets
minercantile.wallets = {}

--load money
dofile(minetest.get_modpath("minercantile") .. "/whitelist.lua")
dofile(minetest.get_modpath("minercantile") .. "/wallets.lua")
dofile(minetest.get_modpath("minercantile") .. "/change.lua")
dofile(minetest.get_modpath("minercantile") .. "/shop.lua")


--load items base and available
minercantile.load_stock_base()
minercantile.load_stock()

minetest.after(10, function()
	minercantile.shop.register_items()
	minercantile.isloaded = true
end)


--save on shutdown
minetest.register_on_shutdown(function()
	minetest.log("action", "[minercantile] Server shuts down, saving shop file.")
	if minercantile.isloaded then -- dont save empty file if not loaded (crash/stop on boot)
		minercantile.save_stock()
	end
end)



-----------------------------------------------------------------------------------------------
minetest.log("action", "[Mod] "..mname.." ["..version.."] Loaded...")
-----------------------------------------------------------------------------------------------
