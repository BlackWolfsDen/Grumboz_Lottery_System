local npcid = 390000

LottoSettings = {};
LottoEntries = {};
LottoEntriez = {};
LottoHistory = {};
LottoEntries["SERVER"] = {
		pot = 0
			};
local function LottoLoader(event)
local LS = WorldDBQuery("SELECT * FROM lotto.settings;");
	if(LS)then
		repeat
			LottoSettings["SERVER"] = {
				item = LS:GetUInt32(1),
				timer = LS:GetUInt32(2),
				operation = LS:GetUInt32(3),
				mumax = LS:GetUInt32(4) -- max for winnings random multiplier
										};
		until not LS:NextRow()
	end	
local LH = WorldDBQuery("SELECT * FROM lotto.history;");
	if(LH)then
		repeat
			LottoHistory[LH:GetUInt32(0)] = {
				id = LH:GetUInt32(0),
				initdate = LH:GetUInt32(1),
				winner = LH:GetString(2),
				amount = LH:GetUInt32(3)
											};
		until not LH:NextRow()
	end
local LE = WorldDBQuery("SELECT * FROM lotto.entries;");
	if(LE)then
		repeat
			LottoEntries[LE:GetUInt32(0)] = {
				id = LE:GetUInt32(0),
				name = LE:GetString(1),
				count = LE:GetUInt32(2)
											};
			count = ((LottoEntries["SERVER"].pot)+(LE:GetUInt32(2)))				
			LottoEntries["SERVER"].pot = count
		until not LE:NextRow()
	end
end

LottoLoader(1)

local function LoadLottoEntriez()
LottoEntriez = {};
LottoEntries["SERVER"].pot = 0
local LZ = WorldDBQuery("SELECT * FROM lotto.entries WHERE `count`>='1';");
	if(LZ)then
		repeat
			LottoEntriez[LZ:GetUInt32(0)] = {
				id = LZ:GetUInt32(0),
				name = LZ:GetString(1),
				count = LZ:GetUInt32(2)
											};
			LottoEntries["SERVER"].pot = ((LottoEntries["SERVER"].pot)+(LZ:GetUInt32(2)))				
		until not LZ:NextRow()
	end
end

LoadLottoEntriez(1)

local function GetId(name)
	for id=1, #LottoEntries do
		if(LottoEntries[id].name==name)then
			return id;
		end
	end
end

local function EnterLotto(name)
local elid = GetId(name)
local elcount = LottoEntries[elid].count + 1
	WorldDBQuery("UPDATE lotto.entries SET `count` = '"..elcount.."' WHERE `name`='"..name.."';")
	LottoEntries[GetId(name)].count = elcount
	GetPlayerByName(name):SendBroadcastMessage("You have entered "..elcount.." times.")
    LottoEntries["SERVER"].pot = elcount
end

local function NewLottoEntry(name, chain)
local NLEID = (#LottoEntries+1)
	WorldDBExecute("REPLACE INTO lotto.entries SET `name`='"..name.."';")
	LottoEntries[NLEID] = {
				id = NLEID,
				name = name,
				count = 0
						};
	if(chain==1)then
		EnterLotto(name)
	else
	end
end

local function FlushLotto(id)
	WorldDBQuery("UPDATE lotto.entries SET `count` = '0' WHERE `id` = '"..id.."';")
	LottoEntries[id].count = 0
end

local function FirstLotto(event, gametime)
	if(event==(0 or nil))then
	else
		local nlid = (1)
		WorldDBQuery("INSERT INTO lotto.history SET `id` = '"..nlid.."';")
		WorldDBQuery("UPDATE lotto.history SET `start` = '"..gametime.."' WHERE `id` = '"..nlid.."';")
		LottoHistory[nlid] = {
					id = nlid,
					initdate = gametime
							};
		print("First Loco Lotto Started.")
	end
end

local function LottoStart(event, gametime)
	if(event==(0 or nil))then
	else
		local lhid = (#LottoHistory + 1)
		WorldDBQuery("REPLACE INTO lotto.history SET `start` = '"..gametime.."';") 
		LottoHistory[lhid] = {
			initdate = gametime
							};
		print("New Loco Lotto Started.")
	end
end

local function Lotto()
	if(LottoSettings["SERVER"].operation==1)then
		if(#LottoHistory < 1)then
			FirstLotto(1, GetGameTime())
			CreateLuaEvent(Tally, LottoSettings["SERVER"].timer, 1)
		else
			LottoStart(1, GetGameTime())
		end
	end	
end

local function Tally(event)
LoadLottoEntriez()
print("tally")
	if(#LottoEntriez < 4)then
		SendWorldMessage("Not enough Loco Lotto Entries.")
	else
		local multiplier = math.random(1, LottoSettings["SERVER"].mumax)
		local win = math.random(1, 1) -- #LottoEntriez)
		local name = LottoEntriez[win].name
		local player = GetPlayerByName(name)

			if(player)then
				local bet = ((LottoEntriez[win].count)*multiplier)
				SendWorldMessage("Contgratulations to "..LottoEntriez[win].name.." our #"..#LottoHistory.." winner. Total:"..(LottoEntries["SERVER"].pot+bet)..". Its LOCO!!")
				player:AddItem(LottoSettings["SERVER"].item, (LottoEntries["SERVER"].pot+bet))
			
				for a=1, #LottoEntries do
					FlushLotto(a)
				end
			LottoEntries["SERVER"] = {0};
			else
				SendWorldMessage("No Winners this Loco lotto round.")
			end
	end
	if(LottoSettings["SERVER"].operation==1)then
		CreateLuaEvent(Tally, LottoSettings["SERVER"].timer, 1)
		Lotto(1)
	end
end


local function LottoOnHello(event, player, unit)
local lohid = GetId(player:GetName())
	if(lohid==nil)then
		NewLottoEntry(player:GetName(), 0)
		LottoOnHello(event, player, unit)
	else
	VendorRemoveAllItems(npcid)
	player:GossipClearMenu()
	player:GossipMenuAddItem(0, "You have entered "..LottoEntries[lohid].count.." times", 0, 10)
	player:GossipMenuAddItem(0, "Enter the lotto.", 0, 100)
	player:GossipMenuAddItem(0, "never mind.", 0, 11)
	player:GossipSendMenu(1, unit)
	end
end

local function LottoOnSelect(event, player, unit, sender, intid, code)
	if(intid<=10)then
		LottoOnHello(1, player, unit)
	end
	if(intid==11)then
		player:GossipComplete()
	end

	if(intid==100)then
		if(player:GetItemCount(LottoSettings["SERVER"].item)==0)then
			player:SendBroadcastMessage("You Loco .. you dont have enough currency to enter.")
		else
			local id = GetId(player:GetName())
			player:RemoveItem(LottoSettings["SERVER"].item, 1)
			if(id)then
				local count = (LottoEntries[id].count + 1)
				EnterLotto(player:GetName())
			else
				NewLottoEntry(player:GetName(), 1)
			end
		LottoOnHello(1, player, unit)
		end
	end
end

RegisterCreatureGossipEvent(npcid, 1, LottoOnHello)
RegisterCreatureGossipEvent(npcid, 2, LottoOnSelect)

print("Grumbo'z Loco Lottery Online.")

if(LottoSettings["SERVER"].operation==1)then
	CreateLuaEvent(Tally, LottoSettings["SERVER"].timer, 1)
	Lotto(1)
end