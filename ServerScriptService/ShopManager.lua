
local RS=game:GetService("ReplicatedStorage"); local SSS=game:GetService("ServerScriptService")
local PlayerData=require(SSS:WaitForChild("PlayerDataManager")); local ShopConfig=require(RS:WaitForChild("ShopConfig"))
local UpdateCurrency=RS:WaitForChild("UpdateCurrency"); local UpdateInventory=RS:WaitForChild("UpdateInventory")
local M={}
local function ok(t)t=t or{};t.Success=true;return t end local function fail(m)return{Success=false,Error=tostring(m or"Error")}end
local function buyPrice(cat,it) local c=ShopConfig.buy and ShopConfig.buy[cat]; return (c and tonumber(c[it])) or 0 end
local function sellPrice(it) for _,b in pairs(ShopConfig.sell or {}) do local p=tonumber(b[it]); if p and p>0 then return p end end return 0 end
function M.HandleGetShopData(p) local s=PlayerData.Snapshot(p) return ok({Config=ShopConfig,PlayerCoins=s and s.Currency.Coins or 0}) end
function M.HandleBuyItem(p,cat,it,q) if type(cat)~="string" or type(it)~="string" then return fail("Bad args") end q=math.max(1,math.floor(tonumber(q) or 1))
 local pp=buyPrice(cat,it); if pp<=0 then return fail("Item is not purchasable") end local total=pp*q local oksp=PlayerData.TrySpendCoins(p,total) if type(oksp)=="table" then oksp=oksp[1] end if not oksp then return fail("Not enough coins") end
 PlayerData.AddItem(p,it,q); local s=PlayerData.Snapshot(p); UpdateCurrency:FireClient(p,"Coins",s.Currency.Coins); UpdateInventory:FireClient(p,s.Inventory)
 return ok({ItemName=it,Quantity=q,NewBalance=s.Currency.Coins,NewInventory=s.Inventory}) end
function M.HandleSellItem(p,it,q) if type(it)~="string" then return fail("Bad args") end q=math.max(1,math.floor(tonumber(q) or 1))
 if not PlayerData.HasItem(p,it,q) then return fail("Not enough items") end local pp=sellPrice(it); if pp<=0 then return fail("Item cannot be sold") end
 local rem=PlayerData.TryConsumeItem(p,it,q); if not rem then return fail("Failed to remove") end local earned=pp*q; PlayerData.AddCoins(p,earned)
 local s=PlayerData.Snapshot(p); UpdateCurrency:FireClient(p,"Coins",s.Currency.Coins); UpdateInventory:FireClient(p,s.Inventory)
 return ok({ItemName=it,Quantity=q,TotalEarned=earned,NewBalance=s.Currency.Coins,NewInventory=s.Inventory}) end
return M
