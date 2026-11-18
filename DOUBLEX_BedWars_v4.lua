-- DOUBLEX HUB BEDWARS v4 | Delta Android | independent from Universal
-- Original UI inspired by feature categories shown in screenshots, not MeritHub source code.
-- Server-side combat, bed destruction and purchases cannot be guaranteed by a client script.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local LP=Players.LocalPlayer
local rootGui=(gethui and gethui()) or LP:WaitForChild('PlayerGui')
local previous=getgenv and getgenv().DOUBLEX_BW_V4
if previous and previous.stop then pcall(previous.stop) end
local old=rootGui:FindFirstChild('DOUBLEX_BW_V4');if old then old:Destroy() end
local defaults={jump=true,esp=false,beds=false,allies=false,names=true,distance=true,health=true,espRange=350,bedRange=600,sprint=false,sprintSpeed=20,fov=false,fovValue=80,scale=.85,quick=true,shopSword=false,shopArmor=false,shopAxe=false,shopPick=false,priority='balanced',theme='purple'}
local cfg={};for k,v in pairs(defaults) do cfg[k]=v end
local path='DOUBLEX_BedWars_v4_settings.json'
local function load()
 if readfile and isfile and isfile(path) then local ok,t=pcall(function()return Http:JSONDecode(readfile(path))end);if ok and type(t)=='table' then for k,v in pairs(defaults) do if type(t[k])==type(v) then cfg[k]=t[k] end end end end
end
load()
local function save() if writefile then pcall(function()writefile(path,Http:JSONEncode(cfg))end)end end
local function make(class,props,parent)
 local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local C={bg=Color3.fromRGB(20,20,32),surface=Color3.fromRGB(34,35,52),button=Color3.fromRGB(45,46,66),accent=Color3.fromRGB(182,135,240),white=Color3.fromRGB(240,238,255),muted=Color3.fromRGB(173,171,194)}
local gui=make('ScreenGui',{Name='DOUBLEX_BW_V4',ResetOnSpawn=false,DisplayOrder=2000,IgnoreGuiInset=false},rootGui)
local panel=make('Frame',{Size=UDim2.fromOffset(490,330),Position=UDim2.new(.5,-245,.5,-165),BackgroundColor3=C.bg,BorderSizePixel=0,Active=true,Draggable=true},gui)
make('UICorner',{CornerRadius=UDim.new(0,12)},panel)
make('UIStroke',{Color=C.accent,Transparency=.65,Thickness=1},panel)
local scale=make('UIScale',{Scale=math.clamp(cfg.scale,.55,1.1)},panel)
make('TextLabel',{Size=UDim2.new(1,-105,0,40),Position=UDim2.fromOffset(14,0),BackgroundTransparency=1,Text='DOUBLEX  |  BEDWARS v4',TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.white},panel)
local function btn(parent,text,pos,size,fn)
 local b=make('TextButton',{Text=text,Position=pos,Size=size,BackgroundColor3=C.button,TextColor3=C.white,TextSize=12,Font=Enum.Font.GothamSemibold,BorderSizePixel=0,AutoButtonColor=true},parent)
 make('UICorner',{CornerRadius=UDim.new(0,7)},b)
 if fn then b.MouseButton1Click:Connect(fn) end
 return b
end
local live=true;local connections={};local visuals={};local bedVisuals={};local current='Movimento'
local function cleanup(t)for k,arr in pairs(t) do for _,v in ipairs(arr) do pcall(function()v:Destroy()end)end;t[k]=nil end end
local function stop()
 if not live then return end;live=false
 for _,c in ipairs(connections) do pcall(function()c:Disconnect()end)end
 cleanup(visuals);cleanup(bedVisuals);save();gui:Destroy()
end
if getgenv then getgenv().DOUBLEX_BW_V4={stop=stop} end
btn(panel,'X',UDim2.new(1,-38,0,6),UDim2.fromOffset(31,28),stop).BackgroundColor3=Color3.fromRGB(154,59,79)
local bubble=btn(gui,'DX',UDim2.new(0,18,.43,0),UDim2.fromOffset(45,45),function()panel.Visible=true end)
bubble.Visible=false;bubble.Active=true;bubble.Draggable=true;bubble.BackgroundColor3=C.bg
make('UICorner',{CornerRadius=UDim.new(1,0)},bubble)
btn(panel,'–',UDim2.new(1,-74,0,6),UDim2.fromOffset(31,28),function()panel.Visible=false;bubble.Visible=true end)
bubble.MouseButton1Click:Connect(function()panel.Visible=true;bubble.Visible=false end)
local side=make('Frame',{Position=UDim2.fromOffset(9,46),Size=UDim2.fromOffset(105,273),BackgroundTransparency=1},panel)
local content=make('ScrollingFrame',{Position=UDim2.fromOffset(123,48),Size=UDim2.new(1,-134,1,-59),BackgroundColor3=C.surface,BackgroundTransparency=.18,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0)},panel)
make('UICorner',{CornerRadius=UDim.new(0,8)},content)
local layout=make('UIListLayout',{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},content)
make('UIPadding',{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},content)
local function teamColor(p)return p.TeamColor and p.TeamColor.Color or Color3.fromRGB(255,115,115)end
local function enemy(p)return p~=LP and (not LP.Team or p.Team~=LP.Team)end
local function labelAt(part,text,color,range)
 local b=make('BillboardGui',{Adornee=part,AlwaysOnTop=true,Size=UDim2.fromOffset(175,39),StudsOffset=Vector3.new(0,3.2,0),MaxDistance=range},gui)
 local l=make('TextLabel',{Size=UDim2.fromScale(1,1),Text=text,TextColor3=color,TextStrokeTransparency=.25,BackgroundColor3=C.bg,BackgroundTransparency=.3,TextWrapped=true,TextSize=11,Font=Enum.Font.GothamBold},b)
 make('UICorner',{CornerRadius=UDim.new(0,5)},l);return b
end
local function updateESP()
 cleanup(visuals);if not cfg.esp then return end
 local myRoot=LP.Character and LP.Character:FindFirstChild('HumanoidRootPart')
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LP and (cfg.allies or enemy(p)) then
   local char=p.Character;local r=char and char:FindFirstChild('HumanoidRootPart');local h=char and char:FindFirstChildOfClass('Humanoid')
   if r and h and h.Health>0 then
    local d=myRoot and math.floor((r.Position-myRoot.Position).Magnitude) or 0
    if not myRoot or d<=cfg.espRange then
     local col=teamColor(p);local team=p.Team and p.Team.Name or 'Sem time';local parts={}
     local hl=make('Highlight',{Adornee=char,FillColor=col,OutlineColor=col,FillTransparency=.88,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},gui)
     table.insert(parts,hl)
     local words={};if cfg.names then table.insert(words,p.DisplayName..' ['..team..']') end
     if cfg.distance then table.insert(words,tostring(d)..' studs') end
     if cfg.health then table.insert(words,math.floor(h.Health)..' HP') end
     if #words>0 then table.insert(parts,labelAt(r,table.concat(words,' | '),col,cfg.espRange)) end
     visuals[p]=parts
    end
   end
  end
 end
end
local function isBed(o)
 if not (o:IsA('BasePart') or o:IsA('Model')) then return false end
 local n=o.Name:lower()
 return n=='bed' or n:find('bed_',1,true) or n:find('_bed',1,true) or n:find('bedmodel',1,true)
end
local function updateBeds()
 cleanup(bedVisuals);if not cfg.beds then return end
 local myRoot=LP.Character and LP.Character:FindFirstChild('HumanoidRootPart');local count=0
 for _,o in ipairs(workspace:GetDescendants()) do
  if count>=30 then break end
  if isBed(o) then
   local ancestor=o.Parent;local nested=false
   while ancestor and ancestor~=workspace do if isBed(ancestor) then nested=true;break end;ancestor=ancestor.Parent end
   if not nested then
    local part=o:IsA('BasePart') and o or o.PrimaryPart or o:FindFirstChildWhichIsA('BasePart',true)
    if part and (not myRoot or (part.Position-myRoot.Position).Magnitude<=cfg.bedRange) then
     count=count+1
     local hl=make('Highlight',{Adornee=o,FillColor=Color3.fromRGB(255,203,92),OutlineColor=Color3.fromRGB(255,230,110),FillTransparency=.78,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},gui)
     local b=labelAt(part,'CAMA (equipe nao confirmada)',Color3.fromRGB(255,220,120),cfg.bedRange)
     bedVisuals[o]={hl,b}
    end
   end
  end
 end
end
local function row(text,key)
 local b=btn(content,'',UDim2.new(),UDim2.new(1,-2,0,34))
 local function paint()b.Text=text..'   '..(cfg[key] and 'ON' or 'OFF');b.BackgroundColor3=cfg[key] and Color3.fromRGB(81,67,119) or C.button end
 b.MouseButton1Click:Connect(function()cfg[key]=not cfg[key];save();paint();if key=='esp' or key=='allies' or key=='names' or key=='distance' or key=='health' then updateESP() elseif key=='beds' then updateBeds()end end);paint();return b
end
local function note(text)
 local l=make('TextLabel',{Size=UDim2.new(1,-4,0,43),BackgroundTransparency=1,Text=text,TextWrapped=true,TextColor3=C.muted,Font=Enum.Font.Gotham,TextSize=11},content);return l
end
local function slider(title,key,min,max,step,after)
 local wrap=make('Frame',{Size=UDim2.new(1,-2,0,49),BackgroundColor3=C.button,BorderSizePixel=0},content)
 make('UICorner',{CornerRadius=UDim.new(0,7)},wrap)
 local label=make('TextLabel',{Size=UDim2.new(1,-12,0,22),Position=UDim2.fromOffset(6,0),BackgroundTransparency=1,TextColor3=C.white,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},wrap)
 local track=make('Frame',{Size=UDim2.new(1,-24,0,7),Position=UDim2.fromOffset(12,32),BackgroundColor3=C.bg,BorderSizePixel=0},wrap)
 make('UICorner',{CornerRadius=UDim.new(1,0)},track)
 local fill=make('Frame',{BackgroundColor3=C.accent,BorderSizePixel=0},track);make('UICorner',{CornerRadius=UDim.new(1,0)},fill)
 local function paint()label.Text=title..': '..tostring(cfg[key]);fill.Size=UDim2.fromScale(math.clamp((cfg[key]-min)/(max-min),0,1),1)end
 local dragging=false
 local function setAt(x)
  local frac=math.clamp((x-track.AbsolutePosition.X)/math.max(track.AbsoluteSize.X,1),0,1)
  cfg[key]=math.clamp(math.floor((min+frac*(max-min))/step+.5)*step,min,max);paint();save();if after then after()end
 end
 local hit=make('TextButton',{Size=UDim2.new(1,10,0,24),Position=UDim2.fromOffset(-5,-8),BackgroundTransparency=1,Text=''},track)
 table.insert(connections,hit.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;setAt(i.Position.X)end end))
 table.insert(connections,UIS.InputChanged:Connect(function(i)if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then setAt(i.Position.X)end end))
 table.insert(connections,UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end))
 paint()
end
local function render()
 for _,o in ipairs(content:GetChildren()) do if o~=layout and not o:IsA('UIPadding') then o:Destroy()end end
 if current=='Movimento' then
  row('Infinite Jump','jump');row('Sprint local (experimental)','sprint');slider('Velocidade local','sprintSpeed',16,26,1)
  note('Sem Fly. O servidor pode restaurar velocidade e movimento.')
 elseif current=='Visual' then
  row('ESP jogadores','esp');row('ESP camas (beta)','beds');row('Mostrar aliados','allies');row('Mostrar nomes/equipes','names');row('Mostrar distancia','distance');row('Mostrar vida','health');slider('Alcance ESP','espRange',50,1000,50,updateESP);slider('Alcance camas','bedRange',100,1000,50,updateBeds)
  note('Camas: identificacao por nome do objeto; time nao garantido.')
 elseif current=='Combate' then
  note('KillAura, Aimbot, AutoClicker e Bed Nuker exigem integracao especifica com o jogo. Nao foram simulados com botoes falsos.')
  note('Ataques, alcance e destruicao de camas sao validados pelo servidor.')
 elseif current=='Loja' then
  row('Preferencia: espada','shopSword');row('Preferencia: armadura','shopArmor');row('Preferencia: machado','shopAxe');row('Preferencia: picareta','shopPick')
  btn(content,'Prioridade: '..cfg.priority,UDim2.new(),UDim2.new(1,-2,0,34),function()cfg.priority=cfg.priority=='balanced' and 'sword' or cfg.priority=='sword' and 'armor' or 'balanced';save();render()end)
  note('Estas sao preferencias salvas, NAO compras automaticas. Sem integracao validada com a loja, nenhum item sera comprado.')
 elseif current=='GUI' then
  row('Quick Bar','quick');slider('Tamanho do menu','scale',.55,1.1,.05,function()scale.Scale=cfg.scale end)
  row('FOV personalizado','fov');slider('Campo de visao','fovValue',70,110,5)
  btn(content,'Restaurar configuracoes',UDim2.new(),UDim2.new(1,-2,0,34),function()for k,v in pairs(defaults) do cfg[k]=v end;scale.Scale=cfg.scale;save();render()end)
 elseif current=='Sobre' then
  note('DOUBLEX HUB BedWars v4 | Delta Android. Codigo original, separado do HUB Universal.')
  note('X encerra funcoes nesta sessao. Minimize para abrir pelo botao DX. Salva ajustes se o executor permitir.')
 end
end
for i,name in ipairs({'Movimento','Visual','Combate','Loja','GUI','Sobre'}) do
 local b=btn(side,name,UDim2.fromOffset(0,(i-1)*43),UDim2.fromOffset(103,36),function()current=name;render()end)
 b.TextXAlignment=Enum.TextXAlignment.Left;b.Text='  '..name
end
render()
local quick=make('Frame',{Size=UDim2.fromOffset(110,36),Position=UDim2.new(0,14,1,-52),BackgroundColor3=C.bg,BackgroundTransparency=.12,Active=true,Draggable=true},gui)
make('UICorner',{CornerRadius=UDim.new(0,8)},quick)
local function quickToggle(key)
 cfg[key]=not cfg[key];save();if key=='esp' then updateESP()end
end
local q1=btn(quick,'JUMP',UDim2.fromOffset(4,3),UDim2.fromOffset(49,30),function()quickToggle('jump')end)
local q2=btn(quick,'ESP',UDim2.fromOffset(57,3),UDim2.fromOffset(49,30),function()quickToggle('esp')end)
local last=0
local originalFOV=workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
local function step(dt)
 if not live then return end
 quick.Visible=cfg.quick
 q1.BackgroundColor3=cfg.jump and Color3.fromRGB(81,67,119) or C.button
 q2.BackgroundColor3=cfg.esp and Color3.fromRGB(81,67,119) or C.button
 local camera=workspace.CurrentCamera
 if camera then camera.FieldOfView=cfg.fov and cfg.fovValue or originalFOV end
 local h=LP.Character and LP.Character:FindFirstChildOfClass('Humanoid')
 if h and cfg.sprint and h.Health>0 then h.WalkSpeed=cfg.sprintSpeed end
 last=last+dt;if last>=1.5 then last=0;updateESP();updateBeds()end
end
table.insert(connections,UIS.JumpRequest:Connect(function()
 if not live or not cfg.jump then return end
 local h=LP.Character and LP.Character:FindFirstChildOfClass('Humanoid')
 if h and h.Health>0 then h:ChangeState(Enum.HumanoidStateType.Jumping)end
end))
table.insert(connections,Run.Heartbeat:Connect(step))
