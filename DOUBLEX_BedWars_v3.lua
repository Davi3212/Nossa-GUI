-- DOUBLEX HUB BEDWARS v3 | Delta Android | standalone from Universal
-- Client-side interface, jump and visual overlays. Combat is server-authoritative.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local RS=game:GetService('RunService')
local Http=game:GetService('HttpService')
local LP=Players.LocalPlayer
local parent=(gethui and gethui()) or LP:WaitForChild('PlayerGui')
local old=parent:FindFirstChild('DOUBLEX_BEDWARS_V3'); if old then old:Destroy() end
local file='DOUBLEX_BedWars_v3_settings.json'
local cfg={jump=true,players=true,beds=false,showAll=false,autoSword=false,autoArmor=false,autoUpgrade=false,priority='balanced'}
if readfile and isfile and isfile(file) then
 local ok,t=pcall(function() return Http:JSONDecode(readfile(file)) end)
 if ok and type(t)=='table' then for k,v in pairs(cfg) do if type(t[k])==type(v) then cfg[k]=t[k] end end end
end
local function save() if writefile then pcall(function() writefile(file,Http:JSONEncode(cfg)) end) end end
local function mk(class,props,par)
 local o=Instance.new(class); for k,v in pairs(props) do o[k]=v end; o.Parent=par;return o
end
local gui=mk('ScreenGui',{Name='DOUBLEX_BEDWARS_V3',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=1000},parent)
local dark=Color3.fromRGB(22,24,34);local green=Color3.fromRGB(35,137,102)
local panel=mk('Frame',{Size=UDim2.fromOffset(280,244),Position=UDim2.new(.5,-140,.48,-122),BackgroundColor3=dark,BorderSizePixel=0,Active=true,Draggable=true},gui)
mk('UICorner',{CornerRadius=UDim.new(0,10)},panel)
mk('TextLabel',{Size=UDim2.new(1,-80,0,33),Position=UDim2.fromOffset(10,2),BackgroundTransparency=1,Text='DOUBLEX | BEDWARS v3',Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left},panel)
local close=mk('TextButton',{Size=UDim2.fromOffset(29,27),Position=UDim2.new(1,-34,0,5),Text='X',TextSize=15,Font=Enum.Font.GothamBold,BackgroundColor3=Color3.fromRGB(156,48,60),TextColor3=Color3.new(1,1,1)},panel)
mk('UICorner',{CornerRadius=UDim.new(0,6)},close)
local minimize=mk('TextButton',{Size=UDim2.fromOffset(29,27),Position=UDim2.new(1,-67,0,5),Text='-',TextSize=18,BackgroundColor3=Color3.fromRGB(54,60,77),TextColor3=Color3.new(1,1,1)},panel)
mk('UICorner',{CornerRadius=UDim.new(0,6)},minimize)
local tabs=mk('Frame',{Position=UDim2.fromOffset(8,40),Size=UDim2.new(1,-16,0,30),BackgroundTransparency=1},panel)
local body=mk('Frame',{Position=UDim2.fromOffset(9,77),Size=UDim2.new(1,-18,0,155),BackgroundTransparency=1},panel)
local current='Movimento';local alive=true;local conns={};local playerVisuals={};local bedVisuals={}
local function clear(tbl)
 for k,o in pairs(tbl) do if o then o:Destroy() end;tbl[k]=nil end
end
local function teamColor(p)
 if p.TeamColor then return p.TeamColor.Color end
 return Color3.fromRGB(255,85,85)
end
local function addBillboard(adornee,text,color,offset)
 local b=mk('BillboardGui',{Name='DOUBLEX_INFO',Adornee=adornee,AlwaysOnTop=true,Size=UDim2.fromOffset(160,39),StudsOffset=offset or Vector3.new(0,3.5,0),MaxDistance=350},gui)
 mk('TextLabel',{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(12,15,24),BackgroundTransparency=.25,Text=text,TextColor3=color,TextStrokeTransparency=.35,TextSize=12,Font=Enum.Font.GothamBold,TextWrapped=true},b)
 return b
end
local function enemy(p) return p~=LP and (not LP.Team or p.Team~=LP.Team) end
local function renderPlayers()
 if not cfg.players then return end
 local root=LP.Character and LP.Character:FindFirstChild('HumanoidRootPart')
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LP and (cfg.showAll or enemy(p)) then
   local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
   if r and h and h.Health>0 then
    local col=teamColor(p);local dist=root and math.floor((root.Position-r.Position).Magnitude) or 0
    local team=p.Team and p.Team.Name or 'Sem time'
    local b=addBillboard(r,p.DisplayName..' | '..team..' | '..dist..'m',col)
    local hl=mk('Highlight',{Name='DOUBLEX_PLAYER',Adornee=c,FillColor=col,OutlineColor=col,FillTransparency=.83,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},gui)
    playerVisuals[p]={b,hl}
   end
  end
 end
end
local function clearPlayerVisuals()
 for k,objects in pairs(playerVisuals) do for _,o in ipairs(objects) do o:Destroy() end;playerVisuals[k]=nil end
end
-- Bed discovery is intentionally heuristic: BedWars map object names can change.
local function isBed(o)
 local n=o.Name:lower()
 return (n=='bed' or n:find('bed_') or n:find('_bed') or n:find('bedmodel')) and (o:IsA('Model') or o:IsA('BasePart'))
end
local function renderBeds()
 if not cfg.beds then return end
 local found=0
 for _,o in ipairs(workspace:GetDescendants()) do
  if found>=35 then break end
  if isBed(o) then
   local part=o:IsA('BasePart') and o or o.PrimaryPart or o:FindFirstChildWhichIsA('BasePart',true)
   if part and part:IsDescendantOf(workspace) then
    local ancestor=o.Parent;local duplicate=false
    while ancestor and ancestor~=workspace do if isBed(ancestor) then duplicate=true;break end;ancestor=ancestor.Parent end
    if not duplicate then
     found=found+1
     local hl=mk('Highlight',{Name='DOUBLEX_BED',Adornee=o,FillColor=Color3.fromRGB(255,208,65),OutlineColor=Color3.fromRGB(255,225,80),FillTransparency=.75,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},gui)
     local b=addBillboard(part,'CAMA (verificar time)',Color3.fromRGB(255,216,82),Vector3.new(0,2.5,0))
     bedVisuals[o]={hl,b}
    end
   end
  end
 end
end
local function clearBeds()
 for k,objects in pairs(bedVisuals) do for _,o in ipairs(objects) do o:Destroy() end;bedVisuals[k]=nil end
end
local function option(label,key,y)
 local b=mk('TextButton',{Size=UDim2.new(1,0,0,34),Position=UDim2.fromOffset(0,y),Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=Color3.new(1,1,1)},body)
 mk('UICorner',{CornerRadius=UDim.new(0,6)},b)
 local function paint() b.Text=label..'  '..(cfg[key] and 'ON' or 'OFF');b.BackgroundColor3=cfg[key] and green or Color3.fromRGB(53,57,72) end
 b.MouseButton1Click:Connect(function() cfg[key]=not cfg[key];save();paint();if key=='players' or key=='showAll' then clearPlayerVisuals();renderPlayers() elseif key=='beds' then clearBeds();renderBeds() end end)
 paint()
end
local function info(text,y)
 mk('TextLabel',{Size=UDim2.new(1,0,0,44),Position=UDim2.fromOffset(0,y),BackgroundTransparency=1,Text=text,TextColor3=Color3.fromRGB(198,201,212),TextSize=11,TextWrapped=true,Font=Enum.Font.Gotham},body)
end
-- Shop integration: uses only visible, explicitly matched purchase buttons in the game's own shop UI.
-- This is experimental; server-authoritative pricing, stock and prerequisites are not bypassed.
local purchaseStatus='Aguardando loja aberta'
local lastPurchase=0
local function visibleTree(o)
 while o and o~=LP.PlayerGui do
  if o:IsA('GuiObject') and not o.Visible then return false end
  o=o.Parent
 end
 return true
end
local function categoryFor(text)
 text=text:lower()
 if text:find('sword',1,true) or text:find('espada',1,true) then return 'sword' end
 if text:find('armor',1,true) or text:find('armadura',1,true) then return 'armor' end
 if text:find('upgrade',1,true) or text:find('melhoria',1,true) then return 'upgrade' end
end
local function shopScan()
 if not (cfg.autoSword or cfg.autoArmor or cfg.autoUpgrade) then return end
 local pg=LP:FindFirstChild('PlayerGui');if not pg then return end
 local candidates={}
 for _,o in ipairs(pg:GetDescendants()) do
  if o:IsA('GuiButton') and visibleTree(o) then
   local parents={o.Parent,o.Parent and o.Parent.Parent}
   local words={o.Name,o:IsA('TextButton') and o.Text or ''}
   for _,par in ipairs(parents) do
    if par then
     for _,ch in ipairs(par:GetChildren()) do
      if ch:IsA('TextLabel') or ch:IsA('TextButton') then words[#words+1]=ch.Text end
     end
    end
   end
   local t=table.concat(words,' '):lower()
   local cat=categoryFor(t)
   local name=(o.Name..' '..(o:IsA('TextButton') and o.Text or '')):lower()
   local buy=name:find('buy',1,true) or name:find('comprar',1,true) or name:find('purchase',1,true)
   local disabled=t:find('not enough',1,true) or t:find('insuficiente',1,true) or t:find('owned',1,true) or t:find('equipado',1,true)
   if buy and cat and not disabled and ((cat=='sword' and cfg.autoSword) or (cat=='armor' and cfg.autoArmor) or (cat=='upgrade' and cfg.autoUpgrade)) then
    candidates[#candidates+1]={button=o,category=cat}
   end
  end
 end
 local order=cfg.priority=='sword' and {'sword','armor','upgrade'} or cfg.priority=='armor' and {'armor','sword','upgrade'} or {'armor','sword','upgrade'}
 for _,category in ipairs(order) do
  for _,item in ipairs(candidates) do
   if item.category==category then
    local ok=pcall(function() item.button:Activate() end)
    purchaseStatus=ok and ('Tentativa: '..category..' (verifique a compra)') or 'Botao nao aceitou ativacao'
    return
   end
  end
 end
 purchaseStatus='Nenhum botao de compra compativel encontrado'
end
local function priorityButton(y)
 local b=mk('TextButton',{Size=UDim2.new(1,0,0,28),Position=UDim2.fromOffset(0,y),Font=Enum.Font.GothamSemibold,TextSize=11,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(54,60,77)},body)
 mk('UICorner',{CornerRadius=UDim.new(0,6)},b)
 local function paint() b.Text='Prioridade: '..({balanced='Equilibrado',sword='Espada',armor='Armadura'})[cfg.priority] end
 b.MouseButton1Click:Connect(function() cfg.priority=cfg.priority=='balanced' and 'sword' or cfg.priority=='sword' and 'armor' or 'balanced';save();paint() end)
 paint()
end
local function renderTab()
 for _,o in ipairs(body:GetChildren()) do o:Destroy() end
 if current=='Movimento' then option('Infinite Jump','jump',0);info('Pule varias vezes no ar usando o botao normal do Roblox. Fly removido.',44)
 elseif current=='Visual' then option('ESP jogadores','players',0);option('ESP camas (beta)','beds',40);option('Mostrar aliados','showAll',80)
 elseif current=='Combate' then info('Aura removida: ataques sao validados pelo servidor. Infinite Jump segue na aba Movimento.',4)
 elseif current=='Loja' then option('Auto espada (beta)','autoSword',0);option('Auto armadura (beta)','autoArmor',37);option('Auto melhoria (beta)','autoUpgrade',74);priorityButton(111)
 else info('DOUBLEX BEDWARS v3 | Delta Android\nX fecha o HUB nesta sessao. Configuracoes sao salvas se o Delta permitir.',4) end
end
for i,name in ipairs({'Movimento','Visual','Combate','Loja','Sobre'}) do
 local b=mk('TextButton',{Size=UDim2.new(.2,-2,1,0),Position=UDim2.new((i-1)*.2,0,0,0),BackgroundColor3=Color3.fromRGB(45,49,65),Text=name,TextColor3=Color3.new(1,1,1),TextSize=9,Font=Enum.Font.GothamSemibold},tabs)
 mk('UICorner',{CornerRadius=UDim.new(0,5)},b)
 b.MouseButton1Click:Connect(function() current=name;renderTab() end)
end
renderTab()
local bubble=mk('TextButton',{Visible=false,Size=UDim2.fromOffset(48,48),Position=UDim2.new(0,14,.45,0),Text='DX',TextSize=16,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=dark,Active=true,Draggable=true},gui)
mk('UICorner',{CornerRadius=UDim.new(1,0)},bubble)
minimize.MouseButton1Click:Connect(function() panel.Visible=false;bubble.Visible=true end)
bubble.MouseButton1Click:Connect(function() panel.Visible=true;bubble.Visible=false end)
conns[#conns+1]=UIS.JumpRequest:Connect(function()
 if not alive or not cfg.jump then return end
 local c=LP.Character;local h=c and c:FindFirstChildOfClass('Humanoid')
 if h and h.Health>0 then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
local elapsed=0
conns[#conns+1]=RS.Heartbeat:Connect(function(dt)
 if not alive then return end
 elapsed=elapsed+dt
 if elapsed>=1 then elapsed=0;clearPlayerVisuals();renderPlayers();clearBeds();renderBeds();shopScan() end
end)
close.MouseButton1Click:Connect(function()
 alive=false;for _,c in ipairs(conns) do c:Disconnect() end
 clearPlayerVisuals();clearBeds();save();gui:Destroy()
end)
