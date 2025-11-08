
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local M={_runtime={}}
function M.InitPlayer(plr) M._runtime[plr]={Currency={Coins=50,DreamSeeds=0},Inventory={["carrot_seed"]=5,["basic_watering_can"]=1,["basic_lantern"]=1},Plots={["Plot1"]={State="Empty",GrowthProgress=0}},Stats={}} end
function M.RemovePlayer(plr) M._runtime[plr]=nil end
function M.BindPlayerLifecycle() Players.PlayerAdded:Connect(M.InitPlayer) Players.PlayerRemoving:Connect(M.RemovePlayer) for _,p in ipairs(Players:GetPlayers())do M.InitPlayer(p) end end
function M.Get(plr) return M._runtime[plr] end
function M.Snapshot(plr) local r=M.Get(plr) if not r then return nil end local s={} for k,v in pairs(r)do if type(v)=="table"then local t={} for kk,vv in pairs(v)do t[kk]=vv end s[k]=t else s[k]=v end end return s end
function M.AddCoins(p,a) local r=M.Get(p) r.Currency.Coins=r.Currency.Coins+(a or 0) return r.Currency.Coins end
function M.TrySpendCoins(p,a) local r=M.Get(p) if r.Currency.Coins<(a or 0) then return false,r.Currency.Coins end r.Currency.Coins=r.Currency.Coins-a return true,r.Currency.Coins end
function M.AddItem(p,i,q) local r=M.Get(p) q=math.max(1,math.floor(q or 1)) r.Inventory[i]=(r.Inventory[i] or 0)+q return r.Inventory[i] end
function M.HasItem(p,i,q) local r=M.Get(p) q=math.max(1,math.floor(q or 1)) return (r.Inventory[i] or 0)>=q end
function M.TryConsumeItem(p,i,q) local r=M.Get(p) q=math.max(1,math.floor(q or 1)) local have=r.Inventory[i] or 0 if have<q then return false end r.Inventory[i]=(have-q)>0 and (have-q) or nil return true end
function M.GetPlot(p,id) local r=M.Get(p) r.Plots[id]=r.Plots[id] or {State="Empty",GrowthProgress=0} return r.Plots[id] end
return M
