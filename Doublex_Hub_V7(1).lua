-- DOUBLEX HUB V7 | Roblox LocalScript / Delta Mobile
-- Interface e recursos locais. Sem dependencias externas.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local TeleportService=game:GetService('TeleportService')
local HttpService=game:GetService('HttpService')
local VirtualUser=game:GetService('VirtualUser')
local LP=Players.LocalPlayer
local PG=LP:WaitForChild('PlayerGui')
if _G.NossaGUIV2Cleanup then pcall(_G.NossaGUIV2Cleanup) end
local previous=PG:FindFirstChild('DoublexHub_V6')
if previous then previous:Destroy() end
local old=PG:FindFirstChild('DoublexHub_V7')
if old then old:Destroy() end
local alive=true
local connections={}
local function connect(sig,fn) local c=sig:Connect(fn);table.insert(connections,c);return c end
local function character() return LP.Character end
local function root() local c=character();return c and c:FindFirstChild('HumanoidRootPart') end
local function humanoid() local c=character();return c and c:FindFirstChildOfClass('Humanoid') end
local cam=workspace.CurrentCamera
local defaults={gravity=workspace.Gravity,brightness=Lighting.Brightness,clock=Lighting.ClockTime,fog=Lighting.FogEnd,ambient=Lighting.Ambient,zoom=LP.CameraMaxZoomDistance}
local S={espTeam=true,aim=false,fov=140,smooth=0.2,targetPart='Head',wall=true,team=true,esp=true,espName=true,espDistance=true,espHealth=true,espBox=true,espSkeleton=false,espItems=false,tracers=false,fullbright=false,noFog=false,speed=false,speedValue=24,jump=false,jumpValue=70,infiniteJump=false,fly=false,flySpeed=35,noclip=false,gravity=false,gravityValue=120,antiVoid=false,touchTP=false,antiAFK=false,lowGraphics=false,stats=false,crosshair=false,zoom=128,notifications=true}
local originalWalk,originalJump,originalUseJump
local savedCFrame=nil
local spectateTarget=nil
local flyBV,flyBG
local flyVertical=0
local aimTarget=nil
local lastAimScan=0
local AIM_SCAN_INTERVAL=0.14
local AIM_LOCK_MARGIN=1.35
local fps=0
local frameCount=0
local lastFPS=os.clock()
local oldV5=PG:FindFirstChild('DoublexHub_V5')
if oldV5 then oldV5:Destroy() end
local oldV4=PG:FindFirstChild('DoublexHub_V4')
if oldV4 then oldV4:Destroy() end
local oldV2=PG:FindFirstChild('NossaGUI_V2')
if oldV2 then oldV2:Destroy() end
local gui=Instance.new('ScreenGui')
gui.Name='DoublexHub_V7';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=PG
local function new(class,props,parent)
 local x=Instance.new(class)
 for k,v in pairs(props or {}) do x[k]=v end
 x.Parent=parent
 return x
end
local purple=Color3.fromRGB(25,139,255)
-- Substitua 0 pelo ID da imagem do lobo publicada no Roblox.
local WOLF_ASSET_ID = 6273118495
local wolfImage = WOLF_ASSET_ID > 0 and ('rbxassetid://'..WOLF_ASSET_ID) or ''
local bg=Color3.fromRGB(19,19,29)
local panel=Color3.fromRGB(30,29,44)
local white=Color3.fromRGB(236,231,250)
local muted=Color3.fromRGB(174,168,194)
local function round(obj,r) new('UICorner',{CornerRadius=UDim.new(0,r or 9)},obj) end
local function stroke(obj,color) new('UIStroke',{Color=color or purple,Thickness=1},obj) end
local function label(parent,txt,size,height)
 return new('TextLabel',{BackgroundTransparency=1,Text=txt,TextColor3=white,Font=Enum.Font.Gotham,TextSize=size or 13,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,height or 26)},parent)
end
local main=new('Frame',{Size=UDim2.fromOffset(320,260),Position=UDim2.new(.5,-160,.5,-130),BackgroundColor3=bg,BorderSizePixel=0,Active=true},gui)
round(main,13);stroke(main)
-- Adaptar o tamanho para telas pequenas sem perder a proporcao.
local viewport=workspace.CurrentCamera.ViewportSize
main.Size=UDim2.fromOffset(math.min(320,math.max(240,viewport.X-24)),math.min(260,math.max(190,viewport.Y-40)))
main.Position=UDim2.new(.5,-main.Size.X.Offset/2,.5,-main.Size.Y.Offset/2)
local top=new('Frame',{Size=UDim2.new(1,0,0,43),BackgroundColor3=panel,BorderSizePixel=0,Active=true},main);round(top,13)
local logo=new('ImageLabel',{Name='WolfLogo',Size=UDim2.fromOffset(31,31),Position=UDim2.fromOffset(8,6),BackgroundTransparency=1,Image=wolfImage,Visible=WOLF_ASSET_ID>0,ScaleType=Enum.ScaleType.Fit},top)
local title=label(top,'DOUBLEX HUB  |  V6',15,43);title.Font=Enum.Font.GothamBold;title.Position=UDim2.fromOffset(WOLF_ASSET_ID>0 and 43 or 12,0);title.Size=UDim2.new(1,WOLF_ASSET_ID>0 and -135 or -104,1,0);title.TextColor3=Color3.fromRGB(84,180,255)
local function topButton(txt,x,color)
 local b=new('TextButton',{Size=UDim2.fromOffset(32,29),Position=UDim2.new(1,x,0,7),Text=txt,TextSize=18,Font=Enum.Font.GothamBold,TextColor3=white,BackgroundColor3=color},top);round(b,7);return b
end
local minBtn=topButton('−',-75,Color3.fromRGB(22,88,172))
local closeBtn=topButton('×',-38,Color3.fromRGB(163,52,77))
local bubble=new('TextButton',{Name='Bubble',Size=UDim2.fromOffset(56,56),Position=UDim2.new(0,12,.5,-28),BackgroundColor3=purple,Text=WOLF_ASSET_ID>0 and '' or 'DX',Font=Enum.Font.GothamBold,TextSize=17,TextColor3=white,Visible=false,Active=true},gui);round(bubble,28);stroke(bubble,Color3.fromRGB(65,185,255))
local bubbleLogo=new('ImageLabel',{Name='WolfLogo',Size=UDim2.new(1,-8,1,-8),Position=UDim2.fromOffset(4,4),BackgroundTransparency=1,Image=wolfImage,Visible=WOLF_ASSET_ID>0,ScaleType=Enum.ScaleType.Fit},bubble)
local search=new('TextBox',{Position=UDim2.fromOffset(9,50),Size=UDim2.new(1,-18,0,31),Text='',PlaceholderText='Pesquisar funcionalidades...',ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=13,TextColor3=white,PlaceholderColor3=muted,BackgroundColor3=panel},main);round(search,8)
local tabs=new('ScrollingFrame',{Position=UDim2.fromOffset(8,88),Size=UDim2.new(1,-16,0,33),BackgroundTransparency=1,ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.X,CanvasSize=UDim2.fromOffset(0,0)},main)
local tabLayout=new('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},tabs)
local body=new('ScrollingFrame',{Position=UDim2.fromOffset(9,128),Size=UDim2.new(1,-18,1,-137),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=purple,CanvasSize=UDim2.fromOffset(0,0)},main)
local layout=new('UIListLayout',{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},body)
connect(layout:GetPropertyChangedSignal('AbsoluteContentSize'),function()body.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+10)end)
connect(tabLayout:GetPropertyChangedSignal('AbsoluteContentSize'),function()tabs.CanvasSize=UDim2.fromOffset(tabLayout.AbsoluteContentSize.X+4,0)end)
local function draggable(handle,target,onTap)
 local start,origin,dragInput,moved
 connect(handle.InputBegan,function(input)
  if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
   start=input.Position;origin=target.Position;dragInput=input;moved=false
  end
 end)
 connect(UIS.InputChanged,function(input)
  if not dragInput then return end
  if input==dragInput or (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then
   local d=input.Position-start
   if d.Magnitude>8 then moved=true end
   target.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
  end
 end)
 connect(UIS.InputEnded,function(input)
  if input==dragInput then dragInput=nil;if not moved and onTap then onTap() end end
 end)
end
draggable(top,main)
draggable(bubble,bubble,function()main.Visible=true;bubble.Visible=false end)
connect(minBtn.MouseButton1Click,function()main.Visible=false;bubble.Visible=true end)
local function notify(t)
 if S.notifications then pcall(function()game:GetService('StarterGui'):SetCore('SendNotification',{Title='DOUBLEX HUB V7',Text=t,Duration=3})end) end
end
local entries={}
local categories={'AimBot','Equipes','ESP','Player','Teleporte','Utilidades','Config'}
local current='AimBot'
local tabButtons={}
for _,cat in ipairs(categories) do
 local b=new('TextButton',{Size=UDim2.fromOffset(cat=='Utilidades' and 88 or 76,30),BackgroundColor3=panel,Text=cat,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=white},tabs);round(b,7);tabButtons[cat]=b
 connect(b.MouseButton1Click,function()current=cat;search.Text='';end)
end
local function entry(cat,name,kind,key,options,action)
 table.insert(entries,{cat=cat,name=name,kind=kind,key=key,options=options,action=action})
end
local function toggle(cat,name,key,action)entry(cat,name,'toggle',key,nil,action)end
local function number(cat,name,key,min,max,step,action)entry(cat,name,'number',key,{min,max,step},action)end
local function button(cat,name,action)entry(cat,name,'button',nil,nil,action)end
local function select(cat,name,key,opts,action)entry(cat,name,'select',key,opts,action)end
local function restoreFly()
 if flyBV then flyBV:Destroy();flyBV=nil end
 if flyBG then flyBG:Destroy();flyBG=nil end
 local h=humanoid();if h then h.PlatformStand=false end
end
local flyControls=new('Frame',{Size=UDim2.fromOffset(60,115),Position=UDim2.new(1,-70,.5,-55),BackgroundTransparency=1,Visible=false},gui)
for i,data in ipairs({{'SUBIR',1},{'DESCER',-1}}) do
 local b=new('TextButton',{Size=UDim2.fromOffset(60,50),Position=UDim2.fromOffset(0,(i-1)*58),Text=data[1],TextSize=11,Font=Enum.Font.GothamBold,TextColor3=white,BackgroundColor3=purple},flyControls);round(b,9)
 connect(b.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then flyVertical=data[2] end end)
 connect(b.InputEnded,function(input)if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then flyVertical=0 end end)
end
local function setFly(on)
 restoreFly();flyControls.Visible=on;flyVertical=0
 if not on then return end
 local r=root();local h=humanoid();if not r or not h then return end
 flyBV=new('BodyVelocity',{MaxForce=Vector3.new(1e8,1e8,1e8),Velocity=Vector3.zero,P=5000},r)
 flyBG=new('BodyGyro',{MaxTorque=Vector3.new(1e8,1e8,1e8),CFrame=cam.CFrame,P=8000},r)
 h.PlatformStand=true
end
local function resetMovement()
 S.speed=false;S.jump=false;S.fly=false;S.noclip=false;S.gravity=false;S.infiniteJump=false
 restoreFly();flyControls.Visible=false;workspace.Gravity=defaults.gravity
 local h=humanoid()
 if h then h.WalkSpeed=originalWalk or 16;h.UseJumpPower=originalUseJump==nil and true or originalUseJump;h.JumpPower=originalJump or 50 end
end
-- Filtros por equipe: todas as equipes adversarias permitidas por padrao.
-- Chaves por nome para preservar selecoes mesmo apos Team ser recriada.
local teamAllowed={}
local function teamKey(team) return team and team.Name or nil end
local function teamEnabled(team)
 if not team then return false end -- neutros nao sao alvos automaticos
 local key=teamKey(team)
 if teamAllowed[key]==nil then return true end
 return teamAllowed[key]
end
local function teamLabel(p)
 local team=p.Team
 if team then return '['..team.Name..']',team.TeamColor.Color end
 return '[NEUTRO]',Color3.fromRGB(175,175,175)
end
local function validPlayer(p)
 if p==LP or not p.Character then return false end
 local h=p.Character:FindFirstChildOfClass('Humanoid')
 local r=p.Character:FindFirstChild('HumanoidRootPart')
 if not h or h.Health<=0 or not r then return false end
 if S.team and LP.Team~=nil and p.Team==LP.Team then return false end
 if not teamEnabled(p.Team) then return false end
 return true
end
local function visiblePart(part,p)
 if not S.wall then return true end
 local c=character()
 local ray=workspace:Raycast(cam.CFrame.Position,part.Position-cam.CFrame.Position,RaycastParams.new())
 if not ray then return true end
 return p.Character and ray.Instance:IsDescendantOf(p.Character)
end
-- Selecao automatica com persistencia de alvo e custo limitado.
-- Prioridade: menor distancia em pixels ao centro da tela; distancia fisica
-- nao limita a selecao. Alvos fora da tela nao sao selecionados.
local function aimPartFor(p)
 if not validPlayer(p) then return nil end
 return p.Character:FindFirstChild(S.targetPart) or p.Character:FindFirstChild('HumanoidRootPart')
end
local function aimScore(part)
 if not part or not part.Parent then return nil end
 local projected,onScreen=cam:WorldToViewportPoint(part.Position)
 if not onScreen or projected.Z<=0 then return nil end
 local center=cam.ViewportSize/2
 local score=(Vector2.new(projected.X,projected.Y)-center).Magnitude
 if score>S.fov then return nil end
 return score
end
local function bestTarget()
 local winner,score=nil,math.huge
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LP then
   local part=aimPartFor(p)
   if part then
    local d=aimScore(part)
    if d and d<score and visiblePart(part,p) then
     winner,score=part,d
    end
   end
  end
 end
 return winner,score
end
local function updateAimTarget()
 -- Mantem o alvo atual enquanto ele for valido, visivel e dentro do FOV.
 local previous=aimTarget
 local owner=previous and Players:GetPlayerFromCharacter(previous.Parent)
 local stillValid=owner and aimPartFor(owner)==previous and aimScore(previous)~=nil
 if stillValid and not visiblePart(previous,owner) then stillValid=false end
 if stillValid then return previous end
 aimTarget=bestTarget()
 return aimTarget
end
-- ESP por Drawing quando disponivel, com fallback de BillboardGui
local drawings={}
local function clearDrawings()
 for _,objs in pairs(drawings) do for _,o in ipairs(objs) do pcall(function()o:Remove()end) end end
 drawings={}
end
local espFolder=new('Folder',{Name='ESP_Overlays'},gui)
local function clearBillboards()espFolder:ClearAllChildren()end
local function makeBillboard(p)
 local r=p.Character and p.Character:FindFirstChild('Head')
 if not r then return end
 local b=new('BillboardGui',{Name=tostring(p.UserId),Adornee=r,Size=UDim2.fromOffset(150,70),StudsOffset=Vector3.new(0,2.5,0),AlwaysOnTop=true,MaxDistance=1500},espFolder)
 local l=label(b,'',12,70);l.TextXAlignment=Enum.TextXAlignment.Center;l.TextYAlignment=Enum.TextYAlignment.Center;l.TextColor3=Color3.fromRGB(203,166,255)
 return b,l
end
local fallbackLabels={}
local function drawObject(t)
 local ok,obj=pcall(function()return Drawing.new(t)end)
 if ok then return obj end
end
local function setESP(enabled)
 clearDrawings();clearBillboards();fallbackLabels={}
 if not enabled then return end
 if not Drawing or type(Drawing.new)~='function' then
  for _,p in ipairs(Players:GetPlayers()) do
   if p~=LP then local b,l=makeBillboard(p);if b then fallbackLabels[p]={b,l} end end
  end
 end
end
local function drawLine(obj,a,b,color)
 obj.From=a;obj.To=b;obj.Color=color;obj.Thickness=1.5;obj.Visible=true
end
local function getDrawings(p)
 if drawings[p] then return drawings[p] end
 local objs={}
 local types={'Text','Square','Line','Line','Line','Line','Line','Line','Line','Line','Line','Line','Line','Line','Line','Line','Line','Line'}
 for _,t in ipairs(types) do local o=drawObject(t);if not o then return nil end;table.insert(objs,o) end
 drawings[p]=objs
 return objs
end
local skeletonPairs={{'Head','UpperTorso'},{'UpperTorso','LowerTorso'},{'UpperTorso','LeftUpperArm'},{'LeftUpperArm','LeftLowerArm'},{'LeftLowerArm','LeftHand'},{'UpperTorso','RightUpperArm'},{'RightUpperArm','RightLowerArm'},{'RightLowerArm','RightHand'},{'LowerTorso','LeftUpperLeg'},{'LeftUpperLeg','LeftLowerLeg'},{'LowerTorso','RightUpperLeg'},{'RightUpperLeg','RightLowerLeg'}}
local function updateESP()
 if not S.esp then return end
 local hasDrawing=Drawing and type(Drawing.new)=='function'
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LP then
   local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
   if hasDrawing then
    local objs=getDrawings(p)
    if objs then
     for _,o in ipairs(objs) do o.Visible=false end
     if h and r and h.Health>0 then
      local v,on=cam:WorldToViewportPoint(r.Position)
      if on then
       local head=c:FindFirstChild('Head')
       local top=head and cam:WorldToViewportPoint(head.Position+Vector3.new(0,0.6,0)) or v
       local bottom=cam:WorldToViewportPoint(r.Position-Vector3.new(0,3,0))
       local height=math.max(12,math.abs(bottom.Y-top.Y));local width=height*.55
       local x=v.X-width/2;local y=top.Y
       local teamText,color=teamLabel(p)
       if S.espName or S.espDistance or S.espHealth then
        local lines={}
        if S.espName then table.insert(lines,(S.espTeam and teamText..' ' or '')..p.DisplayName) end
        if S.espDistance then table.insert(lines,math.floor((r.Position-cam.CFrame.Position).Magnitude)..' studs') end
        if S.espHealth then table.insert(lines,math.floor(h.Health)..'/'..math.floor(h.MaxHealth)..' HP') end
        objs[1].Text=table.concat(lines,' | ');objs[1].Size=13;objs[1].Center=true;objs[1].Outline=true;objs[1].Color=color;objs[1].Position=Vector2.new(v.X,y-18);objs[1].Visible=true
       end
       if S.espBox then objs[2].Position=Vector2.new(x,y);objs[2].Size=Vector2.new(width,height);objs[2].Color=color;objs[2].Thickness=1.5;objs[2].Filled=false;objs[2].Visible=true end
       local idx=3
       if S.tracers then drawLine(objs[idx],Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y),Vector2.new(v.X,bottom.Y),color);idx=idx+1 end
       if S.espSkeleton then
        for _,pair in ipairs(skeletonPairs) do
         local a=c:FindFirstChild(pair[1]);local b=c:FindFirstChild(pair[2])
         if a and b and idx<=#objs then
          local av,ao=cam:WorldToViewportPoint(a.Position);local bv,bo=cam:WorldToViewportPoint(b.Position)
          if ao and bo then drawLine(objs[idx],Vector2.new(av.X,av.Y),Vector2.new(bv.X,bv.Y),color) end
         end
         idx=idx+1
        end
       end
      end
     end
    end
   else
    local pair=fallbackLabels[p]
    if not pair and c then local b,l=makeBillboard(p);if b then pair={b,l};fallbackLabels[p]=pair end end
    if pair then
     pair[1].Adornee=c and c:FindFirstChild('Head')
     pair[1].Enabled=h~=nil and h.Health>0
     if h and r then
      local teamText,teamColor=teamLabel(p)
      local lines={}
      if S.espName then table.insert(lines,(S.espTeam and teamText..' ' or '')..p.DisplayName) end
      if S.espDistance then table.insert(lines,math.floor((r.Position-cam.CFrame.Position).Magnitude)..' studs') end
      if S.espHealth then table.insert(lines,math.floor(h.Health)..' HP') end
      pair[2].Text=table.concat(lines,'\n')
      pair[2].TextColor3=teamColor
     end
    end
   end
  end
 end
end
local itemFolder=new('Folder',{Name='ItemLabels'},gui)
local function updateItems()
 itemFolder:ClearAllChildren()
 if not S.espItems then return end
 local count=0
 for _,obj in ipairs(workspace:GetDescendants()) do
  if count>=50 then break end
  if obj:IsA('Tool') then
   local part=obj:FindFirstChild('Handle')
   if part and part:IsA('BasePart') then
    local b=new('BillboardGui',{Adornee=part,Size=UDim2.fromOffset(130,26),AlwaysOnTop=true,MaxDistance=300},itemFolder)
    local l=label(b,obj.Name,12,26);l.TextColor3=Color3.fromRGB(255,210,116);l.TextXAlignment=Enum.TextXAlignment.Center
    count=count+1
   end
  end
 end
end
local fovCircle
if Drawing and type(Drawing.new)=='function' then
 fovCircle=drawObject('Circle')
 if fovCircle then fovCircle.Filled=false;fovCircle.Thickness=1.5;fovCircle.Color=purple;fovCircle.NumSides=64 end
end
local cross=new('Frame',{Size=UDim2.fromOffset(20,20),Position=UDim2.new(.5,-10,.5,-10),BackgroundTransparency=1,Visible=false},gui)
new('Frame',{Size=UDim2.fromOffset(2,20),Position=UDim2.new(.5,-1,0,0),BackgroundColor3=purple,BorderSizePixel=0},cross)
new('Frame',{Size=UDim2.fromOffset(20,2),Position=UDim2.new(0,0,.5,-1),BackgroundColor3=purple,BorderSizePixel=0},cross)
local statsLabel=new('TextLabel',{Size=UDim2.fromOffset(180,28),Position=UDim2.new(0,8,0,8),BackgroundColor3=panel,TextColor3=white,TextSize=12,Font=Enum.Font.Gotham,Visible=false},gui);round(statsLabel,6)
local function fullbright()
 if S.fullbright then Lighting.Brightness=3;Lighting.ClockTime=14;Lighting.Ambient=Color3.new(1,1,1)
 else Lighting.Brightness=defaults.brightness;Lighting.ClockTime=defaults.clock;Lighting.Ambient=defaults.ambient end
end
local function setFog()Lighting.FogEnd=S.noFog and 1e9 or defaults.fog end
local function lowGraphics()
 if not S.lowGraphics then notify('Graficos reduzidos: restaurar exige reentrar') return end
 for _,v in ipairs(workspace:GetDescendants()) do
  pcall(function()
   if v:IsA('ParticleEmitter') or v:IsA('Trail') or v:IsA('Beam') then v.Enabled=false
   elseif v:IsA('BasePart') then v.Material=Enum.Material.Plastic;v.Reflectance=0
   elseif v:IsA('Decal') or v:IsA('Texture') then v.Transparency=1 end
  end)
 end
 notify('Graficos simplificados')
end
local function getPlayers()
 local t={}
 for _,p in ipairs(Players:GetPlayers()) do if p~=LP then table.insert(t,p) end end
 table.sort(t,function(a,b)return a.Name:lower()<b.Name:lower() end)
 return t
end
local selectedPlayer=nil
local function selectPlayerName()
 local t=getPlayers()
 if #t==0 then return 'Nenhum jogador' end
 local idx=1
 for i,p in ipairs(t) do if p==selectedPlayer then idx=i+1;break end end
 selectedPlayer=t[idx] or t[1]
 return selectedPlayer.DisplayName..' (@'..selectedPlayer.Name..')'
end
-- Procura solo proximo ao alvo, evitando sobreposicao com paredes e quedas.
local function safeTeleport(targetPosition)
 local r=root();local h=humanoid()
 if not r or not h or h.Health<=0 then return false end
 local char=character()
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={char}
 local offsets={Vector3.new(5,0,0),Vector3.new(-5,0,0),Vector3.new(0,0,5),Vector3.new(0,0,-5),Vector3.new(8,0,8)}
 for _,offset in ipairs(offsets) do
  local pos=targetPosition+offset
  local hit=workspace:Raycast(pos+Vector3.new(0,14,0),Vector3.new(0,-40,0),params)
  if hit and hit.Normal.Y>0.65 and hit.Position.Y>workspace.FallenPartsDestroyHeight+10 then
   local destination=hit.Position+Vector3.new(0,4.5,0)
   local obstruction=workspace:Raycast(destination,Vector3.new(0,3,0),params)
   if not obstruction then
    r.AssemblyLinearVelocity=Vector3.zero
    r.CFrame=CFrame.new(destination)
    return true
   end
  end
 end
 notify('Nao encontrei solo seguro proximo ao destino')
 return false
end
-- Registro das funcionalidades
 toggle('AimBot','AimBot ON/OFF','aim')
 number('AimBot','FOV da mira','fov',10,2000,10)
 number('AimBot','Suavizacao da mira','smooth',0.01,1,0.05)
 select('AimBot','Alvo: cabeca / corpo','targetPart',{'Head','HumanoidRootPart'})
 toggle('AimBot','Verificacao de parede','wall')
 toggle('AimBot','Ignorar minha equipe','team',function()aimTarget=nil end)
 button('AimBot','Atualizar alvo automaticamente',function()aimTarget=nil;lastAimScan=0;notify('Selecao automatica ativada')end)
 toggle('ESP','ESP principal','esp',setESP)
 toggle('ESP','Mostrar equipe e cor','espTeam',function()end)
 toggle('ESP','Mostrar nomes','espName')
 toggle('ESP','Mostrar distancia','espDistance')
 toggle('ESP','Mostrar vida','espHealth')
 toggle('ESP','ESP Box (caixas)','espBox')
 toggle('ESP','ESP Skeleton (R15)','espSkeleton')
 toggle('ESP','ESP de itens no mapa','espItems',updateItems)
 toggle('ESP','Tracers (linhas)','tracers')
 toggle('ESP','Fullbright','fullbright',fullbright)
 toggle('ESP','Remover neblina','noFog',setFog)
 toggle('Player','Speed ON/OFF','speed')
 number('Player','Velocidade','speedValue',0,500,2)
 toggle('Player','Jump Power ON/OFF','jump')
 number('Player','Forca do pulo','jumpValue',0,500,5)
 toggle('Player','Infinite Jump','infiniteJump')
 toggle('Player','Fly mobile (analogico + subir/descer)','fly',setFly)
 number('Player','Velocidade do Fly','flySpeed',1,500,5)
 toggle('Player','Noclip','noclip')
 toggle('Player','Gravidade ON/OFF','gravity',function(v)workspace.Gravity=v and S.gravityValue or defaults.gravity end)
 number('Player','Gravidade ajustavel','gravityValue',0,500,4,function(v)if S.gravity then workspace.Gravity=v end end)
 toggle('Player','Anti-Void','antiVoid')
 button('Player','Resetar movimento',function()resetMovement();notify('Movimento restaurado')end)
 button('Teleporte','Atualizar lista de jogadores',function()render();notify('Lista atualizada')end)
 button('Teleporte','Teleporte para jogador',function()
  local r=root();local t=selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild('HumanoidRootPart')
  if r and t then if safeTeleport(t.Position) then notify('Teleporte solicitado (destino verificado)') end else notify('Selecione um jogador valido') end
 end)
 button('Teleporte','Salvar posicao',function()local r=root();if r then savedCFrame=r.CFrame;notify('Posicao salva')end end)
 button('Teleporte','Voltar a posicao salva',function()local r=root();if r and savedCFrame then r.CFrame=savedCFrame;notify('Posicao restaurada')else notify('Nenhuma posicao salva')end end)
 toggle('Teleporte','Teleporte por toque (toque no mundo)','touchTP')
 button('Teleporte','Lista de jogadores',function()
  local names={};for _,p in ipairs(getPlayers()) do table.insert(names,p.Name) end
  notify(#names>0 and table.concat(names,', '):sub(1,160) or 'Nenhum outro jogador')
 end)
 button('Teleporte','Spectate jogador selecionado',function()
  local h=selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChildOfClass('Humanoid')
  if h then spectateTarget=selectedPlayer;cam.CameraSubject=h;notify('Observando '..selectedPlayer.Name)else notify('Selecione um jogador')end
 end)
 button('Teleporte','Parar Spectate',function()spectateTarget=nil;local h=humanoid();if h then cam.CameraSubject=h end end)
 toggle('Utilidades','Anti-AFK','antiAFK')
 toggle('Utilidades','FPS e Ping','stats',function(v)statsLabel.Visible=v end)
 toggle('Utilidades','Reduzir lag (nao reversivel)','lowGraphics',function(v)if v then lowGraphics()end end)
 button('Utilidades','Reentrar no servidor',function()TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP)end)
 button('Utilidades','Trocar de servidor (aleatorio)',function()
  local ok,data=pcall(function()return HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder=Asc&limit=100'))end)
  if not ok or not data or not data.data then notify('Consulta de servidores indisponivel');return end
  for _,s in ipairs(data.data) do if s.id~=game.JobId and s.playing<s.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId,s.id,LP);return end end
  notify('Nenhum servidor alternativo encontrado')
 end)
 button('Utilidades','Resetar camera',function()spectateTarget=nil;cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Custom;local h=humanoid();if h then cam.CameraSubject=h end end)
 number('Utilidades','Zoom maximo','zoom',1,1000,10,function(v)LP.CameraMaxZoomDistance=v end)
 toggle('Utilidades','Crosshair personalizado','crosshair',function(v)cross.Visible=v end)
 toggle('Config','Notificacoes ON/OFF','notifications')
 button('Config','Salvar preferencias',function()
  if not writefile then notify('Executor sem writefile');return end
  local ok=pcall(function()writefile('Doublex_Hub_V7_Config.json',HttpService:JSONEncode({settings=S,teamAllowed=teamAllowed}))end)
  notify(ok and 'Preferencias salvas' or 'Erro ao salvar')
 end)
 button('Config','Carregar preferencias',function()
  if not readfile or not isfile or not isfile('Doublex_Hub_V7_Config.json') then notify('Nenhum arquivo salvo');return end
  local ok,data=pcall(function()return HttpService:JSONDecode(readfile('Doublex_Hub_V7_Config.json'))end)
  if ok and type(data)=='table' then
   if type(data.teamAllowed)=='table' then teamAllowed=data.teamAllowed end
   data=data.settings or data
   for k,v in pairs(data) do if S[k]~=nil and type(S[k])==type(v) then S[k]=v end end
   setESP(S.esp);setFly(S.fly);fullbright();setFog();cross.Visible=S.crosshair;statsLabel.Visible=S.stats
   LP.CameraMaxZoomDistance=S.zoom
   notify('Preferencias carregadas')
  else notify('Arquivo invalido') end
 end)
 button('Config','Tema roxo e preto',function()notify('Tema roxo e preto ativo')end)
local function syncTeamEntries()
 for i=#entries,1,-1 do if entries[i].dynamicTeam then table.remove(entries,i) end end
 local teams=game:GetService('Teams'):GetTeams()
 local known={}
 for _,t in ipairs(teams) do known[t.Name]=true end
 for _,p in ipairs(Players:GetPlayers()) do if p.Team and not known[p.Team.Name] then table.insert(teams,p.Team);known[p.Team.Name]=true end end
 table.sort(teams,function(a,b)return a.Name:lower()<b.Name:lower() end)
 for _,team in ipairs(teams) do
  local key=team.Name
  local e={cat='Equipes',name='Alvo: '..key,kind='teamToggle',teamName=key,dynamicTeam=true}
  table.insert(entries,e)
 end
end
local function render()
 syncTeamEntries()
 for i=#entries,1,-1 do if entries[i].dynamicPlayer then table.remove(entries,i) end end
 for _,p in ipairs(getPlayers()) do
  table.insert(entries,{cat='Teleporte',name=(p.Team and '['..p.Team.Name..'] ' or '[Neutro] ')..p.DisplayName..' (@'..p.Name..')',kind='playerSelect',player=p,dynamicPlayer=true})
 end
 body:ClearAllChildren()
 -- UIListLayout foi removido junto com filhos: recriar
 layout=new('UIListLayout',{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},body)
 connect(layout:GetPropertyChangedSignal('AbsoluteContentSize'),function()if alive then body.CanvasSize=UDim2.fromOffset(0,layout.AbsoluteContentSize.Y+10)end end)
 for cat,b in pairs(tabButtons) do b.BackgroundColor3=cat==current and purple or panel end
 local query=search.Text:lower()
 for _,e in ipairs(entries) do
  if (e.cat==current or query~='') and (query=='' or e.name:lower():find(query,1,true)) then
   local row=new('Frame',{Size=UDim2.new(1,-4,0,39),BackgroundColor3=panel,BorderSizePixel=0},body);round(row,8)
   local txt=label(row,e.name,12,39);txt.Position=UDim2.fromOffset(9,0);txt.Size=UDim2.new(1,-115,1,0);txt.TextTruncate=Enum.TextTruncate.AtEnd
   local b=new('TextButton',{Position=UDim2.new(1,-108,0,5),Size=UDim2.fromOffset(101,29),TextColor3=white,Font=Enum.Font.GothamBold,TextSize=12,BackgroundColor3=purple},row);round(b,7)
   if e.kind=='number' then
    -- Campo editavel: teclado numerico no celular; confirma com Enter/Concluido.
    b.Visible=false
    local lo,hi=e.options[1],e.options[2]
    local input=new('TextBox',{
     Name='NumericInput',Position=UDim2.new(1,-108,0,5),Size=UDim2.fromOffset(101,29),
     BackgroundColor3=Color3.fromRGB(22,88,172),TextColor3=white,
     Font=Enum.Font.GothamBold,TextSize=13,ClearTextOnFocus=false,
     Text=tostring(S[e.key]),PlaceholderText='Digite valor',
     TextTruncate=Enum.TextTruncate.AtEnd
    },row);round(input,7)
    connect(input.FocusLost,function()
     local raw=input.Text:gsub(',', '.')
     local value=tonumber(raw)
     if value and value==value and value~=math.huge and value~=-math.huge then
      value=math.clamp(value,lo,hi)
      value=math.floor(value*1000+0.5)/1000
      S[e.key]=value
      if e.action then pcall(e.action,value)end
     else
      notify('Digite um numero valido')
     end
     input.Text=tostring(S[e.key])
    end)
   else
    local function update()
     if e.kind=='playerSelect' then b.Text=selectedPlayer==e.player and 'ESCOLHIDO' or 'ESCOLHER';b.BackgroundColor3=selectedPlayer==e.player and purple or Color3.fromRGB(77,69,95)
     elseif e.kind=='teamToggle' then b.Text=teamAllowed[e.teamName]~=false and 'ALVO' or 'IGNORAR';b.BackgroundColor3=teamAllowed[e.teamName]~=false and purple or Color3.fromRGB(77,69,95)
     elseif e.kind=='toggle' then b.Text=S[e.key] and 'ON' or 'OFF';b.BackgroundColor3=S[e.key] and purple or Color3.fromRGB(77,69,95)
     elseif e.kind=='select' then b.Text=S[e.key]=='Head' and 'Cabeca' or 'Corpo'
     else b.Text='EXECUTAR' end
    end
    update()
    connect(b.MouseButton1Click,function()
     if e.kind=='playerSelect' then selectedPlayer=e.player;notify('Selecionado: '..e.player.Name);render();return
     elseif e.kind=='teamToggle' then teamAllowed[e.teamName]=not (teamAllowed[e.teamName]~=false);aimTarget=nil
     elseif e.kind=='toggle' then S[e.key]=not S[e.key];if e.action then pcall(e.action,S[e.key])end
     elseif e.kind=='select' then S[e.key]=S[e.key]==e.options[1] and e.options[2] or e.options[1];if e.action then pcall(e.action,S[e.key])end
     else if e.action then local ok,err=pcall(e.action);if not ok then notify('Falha: '..tostring(err):sub(1,80))end end end
     update()
    end)
   end
  end
 end
end
connect(game:GetService('Teams').ChildAdded,function()if current=='Equipes' then render() end end)
connect(game:GetService('Teams').ChildRemoved,function()if current=='Equipes' then render() end end)
connect(Players.PlayerAdded,function()if current=='Equipes' or current=='Teleporte' then render() end end)
connect(Players.PlayerRemoving,function()if current=='Equipes' or current=='Teleporte' then render() end end)
for _,cat in ipairs(categories) do
 connect(tabButtons[cat].MouseButton1Click,function()render()end)
end
connect(search:GetPropertyChangedSignal('Text'),render)
setESP(S.esp) -- ESP ativo ao iniciar; nomes e equipes visiveis automaticamente
local lastItemUpdate=0
local lastESPUpdate=0
local lastSafe
connect(UIS.JumpRequest,function()if S.infiniteJump then local h=humanoid();if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end end end)
connect(UIS.TouchTapInWorld,function(position,processed)
 if not S.touchTP or processed then return end
 local r=root();if not r then return end
 local ray=cam:ViewportPointToRay(position.X,position.Y)
 local result=workspace:Raycast(ray.Origin,ray.Direction*1000)
 if result then r.CFrame=CFrame.new(result.Position+Vector3.new(0,4,0)) end
end)
connect(LP.Idled,function()
 if S.antiAFK then pcall(function()VirtualUser:CaptureController();VirtualUser:ClickButton2(Vector2.new(0,0))end) end
end)
connect(LP.CharacterAdded,function(c)
 restoreFly()
 local h=c:WaitForChild('Humanoid',8)
 if h then originalWalk=h.WalkSpeed;originalJump=h.JumpPower;originalUseJump=h.UseJumpPower end
 if S.fly then task.delay(.8,function()if alive then setFly(true)end end) end
end)
local function onFrame(dt)
 if not alive then return end
 cam=workspace.CurrentCamera or cam
 frameCount=frameCount+1
 if os.clock()-lastFPS>=1 then fps=math.floor(frameCount/(os.clock()-lastFPS)+.5);frameCount=0;lastFPS=os.clock() end
 if S.stats then
  local ping='?';pcall(function()ping=math.floor(LP:GetNetworkPing()*1000)..'ms' end)
  statsLabel.Text='FPS: '..fps..'  |  Ping: '..ping
 end
 local h=humanoid();local r=root()
 if h then
  if S.speed then h.WalkSpeed=S.speedValue end
  if S.jump then h.UseJumpPower=true;h.JumpPower=S.jumpValue end
 end
 if S.noclip and character() then for _,part in ipairs(character():GetDescendants()) do if part:IsA('BasePart') then part.CanCollide=false end end end
 if S.fly and r and h then
  if not flyBV or flyBV.Parent~=r then setFly(true) end
  if flyBV then
   local move=h.MoveDirection
   local vertical=0
   if UIS:IsKeyDown(Enum.KeyCode.Space) then vertical=1 end
   if flyVertical~=0 then vertical=flyVertical end
   if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vertical=-1 end
   flyBV.Velocity=(move+Vector3.new(0,vertical,0))*S.flySpeed
   flyBG.CFrame=cam.CFrame
  end
 end
 if S.antiVoid and r then
  if r.Position.Y>workspace.FallenPartsDestroyHeight+35 and math.abs(r.AssemblyLinearVelocity.Y)<90 then lastSafe=r.CFrame end
  if r.Position.Y<workspace.FallenPartsDestroyHeight+25 and lastSafe then r.CFrame=lastSafe*CFrame.new(0,5,0);r.AssemblyLinearVelocity=Vector3.zero end
 end
 if S.aim then
  local now=os.clock()
  if now-lastAimScan>=AIM_SCAN_INTERVAL then
   lastAimScan=now
   updateAimTarget()
  end
  local t=aimTarget
  if t and t.Parent then
   local desired=CFrame.lookAt(cam.CFrame.Position,t.Position)
   -- Suavizacao independente do FPS, sem recalcular candidatos a cada frame.
   local alpha=1-math.pow(1-math.clamp(S.smooth,0.01,1),math.min(dt,0.1)*60)
   cam.CFrame=cam.CFrame:Lerp(desired,math.clamp(alpha,0.01,1))
  end
 else
  aimTarget=nil
 end
 if fovCircle then fovCircle.Visible=S.aim;fovCircle.Radius=S.fov;fovCircle.Position=cam.ViewportSize/2 end
 if S.esp and os.clock()-lastESPUpdate>.08 then lastESPUpdate=os.clock();updateESP()end
 if S.espItems and os.clock()-lastItemUpdate>5 then lastItemUpdate=os.clock();updateItems()end
end
connect(Run.RenderStepped,onFrame)
local function cleanup()
 if not alive then return end
 alive=false
 resetMovement();setESP(false);clearDrawings();itemFolder:ClearAllChildren()
 if fovCircle then pcall(function()fovCircle:Remove()end)end
 if spectateTarget then local h=humanoid();if h then cam.CameraSubject=h end end
 Lighting.Brightness=defaults.brightness;Lighting.ClockTime=defaults.clock;Lighting.FogEnd=defaults.fog;Lighting.Ambient=defaults.ambient
 LP.CameraMaxZoomDistance=defaults.zoom
 for _,c in ipairs(connections) do pcall(function()c:Disconnect()end)end
 gui:Destroy()
end
_G.NossaGUIV2Cleanup=cleanup
connect(closeBtn.MouseButton1Click,cleanup)
local h=humanoid();if h then originalWalk=h.WalkSpeed;originalJump=h.JumpPower;originalUseJump=h.UseJumpPower end
render()
notify('DOUBLEX HUB V7 carregado!')
