-- DOUBLEX HUB | Dandy's World v11.0 | Delta Android
-- Script independente do DOUBLEX HUB Universal/BedWars.
-- Nenhum ESP, Speed ou autopiloto e ativado sozinho.
-- A estrutura interna do jogo pode mudar. Funcoes sao locais e nao garantem vitoria.

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

if _G.DOUBLEXDandyCleanup then pcall(_G.DOUBLEXDandyCleanup) end
local live = true
local connections, markers = {}, {}
local state = {monsters=false, machines=false, items=false, elevator=false, players=false,
    danger=false, bright=false, antiAFK=false, autoElev=false,
    speed=false, speedValue=26, autoPlay=false, autoSkill=false}
local navSerial = 0
local autoRunId = 0
local DANGER_RANGE=65
local SAFE_RANGE=92
local originalSpeed, speedHumanoid=nil,nil
local lastAutoElevatorMap=nil
local oldLighting = {
    Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
    FogEnd=Lighting.FogEnd, Ambient=Lighting.Ambient
}

local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end
local function inst(class, props, parent)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o,r)
    inst("UICorner", {CornerRadius=UDim.new(0,r or 9)}, o)
end
local function modelPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart",true)
            or obj:FindFirstChildWhichIsA("BasePart",true)
    end
    return obj:FindFirstChildWhichIsA("BasePart",true)
end
local function positionOf(obj)
    local p = modelPart(obj)
    return p and p.Position or nil
end
local function charRoot()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function currentMap()
    local room = workspace:FindFirstChild("CurrentRoom")
    return room and room:FindFirstChildWhichIsA("Model") or nil
end
local function getObjects(kind)
    if kind=="players" then
        local folder = workspace:FindFirstChild("InGamePlayers")
        if folder then
            local result = {}
            for _,v in ipairs(folder:GetChildren()) do
                if v:IsA("Model") and (not LP.Character or v~=LP.Character) then
                    table.insert(result,v)
                end
            end
            return result
        end
        local result={}
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LP and plr.Character then table.insert(result,plr.Character) end
        end
        return result
    end
    if kind=="elevator" then
        local elevators=workspace:FindFirstChild("Elevators")
        local real=elevators and elevators:FindFirstChild("Elevator")
        return real and {real} or {}
    end
    local map = currentMap()
    if not map then return {} end
    local folders={monsters="Monsters", machines="Generators", items="Items"}
    local folder=map:FindFirstChild(folders[kind] or "")
    if not folder then return {} end
    return folder:GetChildren()
end
-- V10: freeze visual removido: o servidor ainda processa dano dos Twisteds.

local function machineFinished(obj)
    local stats=obj:FindFirstChild("Stats")
    local v=stats and stats:FindFirstChild("Completed")
    return v and v:IsA("BoolValue") and v.Value or false
end
local function machinePercent(obj)
    local s=obj:FindFirstChild("Stats")
    if not s then return nil end
    local current=s:FindFirstChild("CurrentAmount")
    local needed=s:FindFirstChild("RequiredAmount")
    if not current or not needed then return nil end
    if not current:IsA("NumberValue") and not current:IsA("IntValue") then return nil end
    if not needed:IsA("NumberValue") and not needed:IsA("IntValue") then return nil end
    if needed.Value<=0 then return nil end
    return math.floor(math.clamp(current.Value/needed.Value,0,1)*100+.5)
end
local function nearest(kind)
    local me=charRoot()
    if not me then return nil,math.huge end
    local best,bestDistance=nil,math.huge
    for _,obj in ipairs(getObjects(kind)) do
        if obj.Parent and (kind~="machines" or not machineFinished(obj)) then
            local p=positionOf(obj)
            if p then
                local d=(p-me.Position).Magnitude
                if d<bestDistance then best,bestDistance=obj,d end
            end
        end
    end
    return best,bestDistance
end

local gui = inst("ScreenGui",{
    Name="DOUBLEX_Dandy_GUI",ResetOnSpawn=false,IgnoreGuiInset=false,
    DisplayOrder=35,ZIndexBehavior=Enum.ZIndexBehavior.Sibling
},PG)
local C={bg=Color3.fromRGB(20,22,31),card=Color3.fromRGB(30,33,44),
    accent=Color3.fromRGB(133,90,245),off=Color3.fromRGB(53,57,71),
    white=Color3.fromRGB(246,246,251),mute=Color3.fromRGB(186,190,206),
    green=Color3.fromRGB(80,198,132),danger=Color3.fromRGB(240,84,95)}
local main=inst("Frame",{
    Size=UDim2.fromOffset(282,316),Position=UDim2.new(1,-293,.5,-158),
    BackgroundColor3=C.bg,BorderSizePixel=0,Active=true
},gui)
round(main,11)
inst("UIStroke",{Color=C.accent,Thickness=1,Transparency=.25},main)
local top=inst("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Active=true},main)
local title=inst("TextLabel",{
    Position=UDim2.fromOffset(11,3),Size=UDim2.new(1,-83,0,20),
    BackgroundTransparency=1,Text="DOUBLEX  |  DANDY'S WORLD",
    Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.white,TextXAlignment=Enum.TextXAlignment.Left
},top)
inst("TextLabel",{
    Position=UDim2.fromOffset(12,22),Size=UDim2.new(1,-84,0,15),
    BackgroundTransparency=1,Text="v11.0  •  Delta Mobile  •  Tudo OFF",
    Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.mute,TextXAlignment=Enum.TextXAlignment.Left
},top)
local function topButton(text,x,action)
    local b=inst("TextButton",{
        Size=UDim2.fromOffset(29,28),Position=UDim2.new(1,x,0,7),
        BackgroundColor3=C.card,Text=text,TextColor3=C.white,
        Font=Enum.Font.GothamBold,TextSize=16,BorderSizePixel=0
    },top)
    round(b,7)
    bind(b.MouseButton1Click,action)
    return b
end
local status=inst("TextLabel",{
    Position=UDim2.fromOffset(9,43),Size=UDim2.new(1,-18,0,36),
    BackgroundColor3=C.card,Text="Aguardando partida...",TextWrapped=true,
    Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.mute,BorderSizePixel=0
},main)
round(status,7)
local scroll=inst("ScrollingFrame",{
    Position=UDim2.fromOffset(8,84),Size=UDim2.new(1,-16,0,192),
    ScrollBarThickness=3,ScrollBarImageColor3=C.accent,
    BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y
},main)
local layout=inst("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
inst("UIPadding",{PaddingBottom=UDim.new(0,4)},scroll)
local foot=inst("TextLabel",{
    Size=UDim2.new(1,-18,0,27),Position=UDim2.new(0,9,1,-31),
    BackgroundColor3=C.card,BorderSizePixel=0,
    Text="Ative um recurso por vez • X fecha tudo",TextWrapped=true,
    TextColor3=C.mute,Font=Enum.Font.Gotham,TextSize=10
},main)
round(foot,7)
local float=inst("TextButton",{
    Size=UDim2.fromOffset(45,45),Position=UDim2.new(1,-57,.56,0),
    BackgroundColor3=C.accent,Text="DX",TextColor3=C.white,Font=Enum.Font.GothamBold,
    TextSize=17,Visible=false,BorderSizePixel=0,Active=true
},gui)
round(float,13)
local function drag(handle, target)
    local moving,started,origin=false,nil,nil
    bind(handle.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            moving=true;started=input.Position;origin=target.Position
            local c
            c=input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then
                    moving=false;c:Disconnect()
                end
            end)
        end
    end)
    bind(UserInputService.InputChanged,function(input)
        if moving and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) and started and origin then
            local d=input.Position-started
            target.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
        end
    end)
end
drag(top,main)
drag(float,float)
local function say(msg)
    if live then foot.Text=msg end
end
local buttonList={}
local function heading(text)
    inst("TextLabel",{Size=UDim2.new(1,-4,0,19),BackgroundTransparency=1,
        Text="  "..text,TextColor3=C.mute,TextSize=11,
        Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},scroll)
end
local function addButton(label,fn,key)
    local b=inst("TextButton",{Size=UDim2.new(1,-4,0,32),BackgroundColor3=C.off,
        Text=label,TextColor3=C.white,Font=Enum.Font.GothamMedium,
        TextSize=12,BorderSizePixel=0,TextWrapped=true},scroll)
    round(b,8)
    local function redraw()
        if not key then return end
        b.Text=(state[key] and "[ON]  " or "[OFF]  ")..label
        b.BackgroundColor3=state[key] and C.accent or C.off
    end
    redraw()
    bind(b.MouseButton1Click,function()
        if not live then return end
        local ok,err=pcall(fn)
        if not ok then say("Falha: "..tostring(err):sub(1,75)) end
        redraw()
    end)
    if key then buttonList[key]=redraw end
end
local colors={monsters=Color3.fromRGB(252,85,100),machines=Color3.fromRGB(85,217,165),
    items=Color3.fromRGB(248,208,88),elevator=Color3.fromRGB(100,170,255),
    players=Color3.fromRGB(181,137,255)}
local names={monsters="TWISTED",machines="MAQUINA",items="ITEM",
    elevator="ELEVADOR",players="JOGADOR"}
local function clearMarker(obj)
    local v=markers[obj]
    if v then
        if v.highlight then pcall(function()v.highlight:Destroy()end) end
        if v.billboard then pcall(function()v.billboard:Destroy()end) end
        markers[obj]=nil
    end
end
local function clearAllMarkers()
    for obj in pairs(markers) do clearMarker(obj) end
end
local function makeMarker(obj,kind)
    local part=modelPart(obj)
    if not part then return end
    local rec={kind=kind}
    local ok,hl=pcall(function()
        return inst("Highlight",{Name="DOUBLEX_DANDY_ESP",Adornee=obj,
            FillColor=colors[kind],OutlineColor=colors[kind],FillTransparency=.83,
            OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},obj)
    end)
    if ok then rec.highlight=hl end
    local bb=inst("BillboardGui",{
        Name="DOUBLEX_DANDY_LABEL",Adornee=part,
        AlwaysOnTop=true,Size=UDim2.fromOffset(148,34),StudsOffset=Vector3.new(0,3,0),
        MaxDistance=400,Enabled=true
    },gui)
    local lbl=inst("TextLabel",{
        Size=UDim2.fromScale(1,1),BackgroundTransparency=.38,
        BackgroundColor3=C.bg,TextColor3=colors[kind],
        Font=Enum.Font.GothamBold,TextSize=10,TextWrapped=true,
        BorderSizePixel=0,Text=""
    },bb)
    round(lbl,6)
    rec.billboard=bb;rec.label=lbl
    markers[obj]=rec
end
local function refreshMarkers()
    local wanted={}
    local count=0
    for _,kind in ipairs({"monsters","machines","items","elevator","players"}) do
        if state[kind] then
            for _,obj in ipairs(getObjects(kind)) do
                if count>=100 then break end
                if obj.Parent and (kind~="machines" or not machineFinished(obj)) and modelPart(obj) then
                    wanted[obj]=kind
                    count=count+1
                    if not markers[obj] or markers[obj].kind~=kind then
                        clearMarker(obj)
                        makeMarker(obj,kind)
                    end
                    local rec=markers[obj]
                    if rec then
                        local base=obj.Name:gsub("Monster$","")
                        if kind=="machines" then
                            local pct=machinePercent(obj)
                            base=pct and (pct.."%") or obj.Name
                        end
                        local me=charRoot()
                        local p=positionOf(obj)
                        local distance=me and p and math.floor((me.Position-p).Magnitude) or nil
                        rec.label.Text=names[kind].."  "..base..(distance and ("\n"..distance.." studs") or "")
                        rec.billboard.Adornee=modelPart(obj)
                    end
                end
            end
        end
    end
    for obj in pairs(markers) do
        if not wanted[obj] then clearMarker(obj) end
    end
end
local function setBright(value)
    state.bright=value
    if value then
        Lighting.Brightness=3;Lighting.ClockTime=14;Lighting.FogEnd=100000
        Lighting.Ambient=Color3.fromRGB(200,200,200)
    else
        for k,v in pairs(oldLighting) do Lighting[k]=v end
    end
end
-- V3: navegacao por piso, caminhos alternativos, deteccao de travamento e fuga real.
local function human()
    local c=LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function freezeMove()
    local h,r=human(),charRoot()
    if h and r then pcall(function() h:MoveTo(r.Position) end) end
end
local function stopNav()
    navSerial=navSerial+1
    freezeMove()
end
local function movementAlive(serial)
    local h=human()
    return live and navSerial==serial and h and h.Parent and h.Health>0 and charRoot()
end
local function setSpeed(enabled)
    state.speed=enabled
    local h=human()
    if enabled then
        if h and h~=speedHumanoid then
            originalSpeed=h.WalkSpeed
            speedHumanoid=h
        end
        if h then h.WalkSpeed=state.speedValue end
    else
        if speedHumanoid and speedHumanoid.Parent and originalSpeed then
            pcall(function()speedHumanoid.WalkSpeed=originalSpeed end)
        end
        speedHumanoid=nil;originalSpeed=nil
    end
end
-- Catalogo cauteloso de comportamentos conhecidos (nao presume que todo
-- monstro parado seja inofensivo; alguns usam ataques de area).
local function twistedClass(obj)
    local name=tostring(obj.Name or ""):lower():gsub("[^%a%d]","")
    if name:find("razzle") or name:find("dazzle") then
        return "stationary_ribbon"
    elseif name:find("blot") then
        return "stationary_hands"
    elseif name:find("rodger") then
        return "stationary_reactive"
    elseif name:find("squirm") then
        return "stationary_reactive"
    elseif name:find("connie") then
        return "machine_possessor"
    else
        return "pursuer"
    end
end
local function monsterAngry(obj)
    if not obj or not obj.Parent then return false end
    for _,key in ipairs({"Chasing","Aggro","Aggressive","IsChasing","Enraged"}) do
        local v=obj:GetAttribute(key)
        if v==true then return true end
        local child=obj:FindFirstChild(key,true)
        if child and child:IsA("BoolValue") and child.Value then return true end
    end
    return false
end
local function flatThreatDistance(a,b)
    return (Vector3.new(a.X-b.X,0,a.Z-b.Z)).Magnitude
end
local function nearestPursuer()
    local root=charRoot()
    if not root then return nil,math.huge end
    local best,dist=nil,math.huge
    for _,obj in ipairs(getObjects("monsters")) do
        if obj.Parent then
            local kind=twistedClass(obj)
            if kind=="pursuer" or (kind=="machine_possessor" and monsterAngry(obj)) then
                local p=positionOf(obj)
                if p then
                    local d=flatThreatDistance(p,root.Position)
                    if d<dist then best,dist=obj,d end
                end
            end
        end
    end
    return best,dist
end
-- A fuga reage a inimigos que perseguem; Razzle e Blot nao bloqueiam
-- automaticamente TODAS as maquinas so porque estao perto delas.
local function enemyAt(point)
    local closest=math.huge
    for _,obj in ipairs(getObjects("monsters")) do
        if obj.Parent then
            local kind=twistedClass(obj)
            local p=positionOf(obj)
            if p then
                local d=flatThreatDistance(point,p)
                if kind=="pursuer" or
                    (kind=="machine_possessor" and (monsterAngry(obj) or d<10)) then
                    closest=math.min(closest,d)
                end
            end
        end
    end
    return closest
end
-- Distancia aos riscos de toque/area: nao confundir com perseguidor.
local function staticDanger(point)
    local risk=0
    for _,obj in ipairs(getObjects("monsters")) do
        if obj.Parent then
            local kind=twistedClass(obj)
            local p=positionOf(obj)
            if p then
                local dist=flatThreatDistance(point,p)
                if kind=="stationary_ribbon" then
                    if dist<42 then risk=risk+(42-dist)*2.5 end
                elseif kind=="stationary_reactive" then
                    if dist<17 then risk=risk+(17-dist)*5 end
                elseif kind=="stationary_hands" then
                    if dist<18 then risk=risk+(18-dist)*.8 end
                end
            end
        end
    end
    return risk
end

local NAV_AGENT={
    AgentRadius=1.5,AgentHeight=4,AgentCanJump=true,
    AgentCanClimb=true,WaypointSpacing=3
}
local function flatDistance(a,b)
    return (Vector3.new(a.X-b.X,0,a.Z-b.Z)).Magnitude
end
local function onFloor(pos,ignoreTarget)
    local root,h=charRoot(),human()
    if not root or not h then return nil end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    local excludes={LP.Character}
    if ignoreTarget then table.insert(excludes,ignoreTarget) end
    params.FilterDescendantsInstances=excludes
    params.IgnoreWater=true
    local hit=workspace:Raycast(pos+Vector3.new(0,13,0),Vector3.new(0,-48,0),params)
    if not hit or hit.Normal.Y<.65 then return nil end
    return Vector3.new(pos.X,hit.Position.Y+h.HipHeight+root.Size.Y*.5+.15,pos.Z)
end
local function buildPath(startPos,goal)
    local path=PathfindingService:CreatePath(NAV_AGENT)
    local ok=pcall(function() path:ComputeAsync(startPos,goal) end)
    if not ok or path.Status~=Enum.PathStatus.Success then return nil,nil end
    local wps=path:GetWaypoints()
    if #wps<1 then return nil,nil end
    return path,wps
end
local function lengthOf(wps)
    local d=0
    for i=2,#wps do d=d+(wps[i].Position-wps[i-1].Position).Magnitude end
    return d
end
local function requestJump(h)
    if h and h.Health>0 and h.FloorMaterial~=Enum.Material.Air then
        h.Jump=true
        pcall(function()h:ChangeState(Enum.HumanoidStateType.Jumping)end)
    end
end
-- Desce apenas de bordas baixas, com chao detectado e sem parede na frente.
-- Sem teleportes e nunca tenta descer para o void.
local function trySafeDrop(goal,serial,checkDanger)
    local root,h=charRoot(),human()
    if not movementAlive(serial) or not root or not h then return false end
    local v=Vector3.new(goal.X-root.Position.X,0,goal.Z-root.Position.Z)
    if v.Magnitude<1 then return false end
    local base=v.Unit
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={LP.Character}
    params.IgnoreWater=true
    for _,angle in ipairs({0,45,-45,85,-85}) do
        if not movementAlive(serial) then return false end
        local direction=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(angle)):VectorToWorldSpace(base)
        local sample=root.Position+direction*6
        local landing=onFloor(sample)
        if landing then
            local drop=root.Position.Y-landing.Y
            if drop>=2 and drop<=8 and (not checkDanger or enemyAt(landing)>DANGER_RANGE) then
                local sightStart=root.Position+Vector3.new(0,.5,0)
                local barrier=workspace:Raycast(sightStart,direction*5,params)
                if not barrier then
                    h:MoveTo(landing)
                    local startY=root.Position.Y
                    local untilTime=os.clock()+2.1
                    while movementAlive(serial) and os.clock()<untilTime do
                        if checkDanger and enemyAt(charRoot().Position)<DANGER_RANGE then
                            freezeMove();return false
                        end
                        local here=charRoot().Position
                        if startY-here.Y>=1.6 then
                            -- Deixar o avatar terminar a queda antes de recalcular.
                            local limit=os.clock()+1.2
                            while movementAlive(serial) and human().FloorMaterial==Enum.Material.Air and os.clock()<limit do
                                task.wait(.08)
                            end
                            return true
                        end
                        task.wait(.08)
                    end
                end
            end
        end
    end
    return false
end
local function walkPath(goal,serial,checkDanger,arrivalRadius)
    arrivalRadius=arrivalRadius or 4
    local waypointRadius=arrivalRadius<=2 and 1.45 or 2.5
    for attempt=1,3 do
        if not movementAlive(serial) then return "cancelled" end
        local root,h=charRoot(),human()
        if checkDanger and enemyAt(root.Position)<DANGER_RANGE then
            freezeMove();return "danger"
        end
        -- Nao calcula inicio de rota em queda livre.
        local airborneUntil=os.clock()+1.4
        while movementAlive(serial) and h.FloorMaterial==Enum.Material.Air and os.clock()<airborneUntil do
            if checkDanger and enemyAt(charRoot().Position)<DANGER_RANGE then return "danger" end
            task.wait(.08)
        end
        if not movementAlive(serial) then return "cancelled" end
        root,h=charRoot(),human()
        local path,wps=buildPath(root.Position,goal)
        if not path then
            if attempt==1 and trySafeDrop(goal,serial,checkDanger) then
                -- Tentar novamente da parte inferior do obstaculo.
            else
                return "no_path"
            end
        else
            local currentIndex=2
            local pathBlocked=false
            local con=path.Blocked:Connect(function(blockedAt)
                if blockedAt>=currentIndex then pathBlocked=true end
            end)
            local stalled=false
            for i=2,#wps do
                currentIndex=i
                if not movementAlive(serial) then con:Disconnect();return "cancelled" end
                local wp=wps[i]
                local bestDistance=math.huge
                local lastProgress=os.clock()
                local started=os.clock()
                local lastMove=0
                local lastJump=0
                repeat
                    if not movementAlive(serial) then con:Disconnect();return "cancelled" end
                    root,h=charRoot(),human()
                    if checkDanger and enemyAt(root.Position)<DANGER_RANGE then
                        con:Disconnect();freezeMove();return "danger"
                    end
                    if pathBlocked then stalled=true;break end
                    local horizontal=flatDistance(root.Position,wp.Position)
                    local vertical=math.abs(root.Position.Y-wp.Position.Y)
                    if horizontal<=waypointRadius and vertical<=4 then break end
                    local now=os.clock()
                    if horizontal<bestDistance-.6 then
                        bestDistance=horizontal
                        lastProgress=now
                    end
                    if wp.Action==Enum.PathWaypointAction.Jump and now-lastJump>.65 then
                        requestJump(h)
                        lastJump=now
                    end
                    if now-lastProgress>1.15 and now-lastJump>1.15 then
                        requestJump(h)
                        lastJump=now
                    end
                    -- Radar em 3 alturas: pega grades baixas que o raio no tronco nao via.
                    if horizontal>3.2 and now-lastMove>.24 then
                        local travel=Vector3.new(wp.Position.X-root.Position.X,0,
                            wp.Position.Z-root.Position.Z)
                        if travel.Magnitude>1 then
                            local d=travel.Unit
                            local params=RaycastParams.new()
                            params.FilterType=Enum.RaycastFilterType.Exclude
                            params.FilterDescendantsInstances={LP.Character}
                            params.IgnoreWater=true
                            pcall(function()params.RespectCanCollide=true end)
                            for _,dy in ipairs({-.3,-1.2,-2.1}) do
                                local hit=workspace:Raycast(root.Position+Vector3.new(0,dy,0),
                                    d*math.min(3.4,horizontal),params)
                                if hit and hit.Normal.Y<.58 and
                                    hit.Distance<math.min(2.9,horizontal-1) then
                                    stalled=true
                                    break
                                end
                            end
                            if stalled then break end
                        end
                    end
                    if now-lastProgress>1.25 or now-started>6.0 then
                        stalled=true
                        break
                    end
                    if now-lastMove>.45 then
                        h:MoveTo(wp.Position)
                        lastMove=now
                    end
                    task.wait(.09)
                until false
                if stalled then break end
            end
            con:Disconnect()
            if not stalled then
                if flatDistance(charRoot().Position,goal)<=arrivalRadius then
                    freezeMove()
                    return "arrived"
                end
            end
            -- Caminho dinamicamente bloqueado: recalcular do local atual.
            if attempt==2 and trySafeDrop(goal,serial,checkDanger) then
                say("Descendo obstaculo seguro e recalculando...")
            end
            task.wait(.12)
        end
    end
    freezeMove()
    return "blocked"
end
-- V4 | Radar continuo de fuga. Raycasts leves verificam paredes e saidas.
-- O planejamento completo de Pathfinding roda em outra tarefa: nunca interrompe a fuga.
local function escapeRayParams()
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    local excluded={LP.Character}
    local map=currentMap()
    local monsters=map and map:FindFirstChild("Monsters")
    if monsters then table.insert(excluded,monsters) end
    params.FilterDescendantsInstances=excluded
    params.IgnoreWater=true
    pcall(function()params.RespectCanCollide=true end)
    return params
end
local function radarClearance(pos,direction,range,params)
    if direction.Magnitude<.01 then return 0 end
    local distance=range
    for _,y in ipairs({-2.1,-1.05,.3,1.35}) do
        local hit=workspace:Raycast(pos+Vector3.new(0,y,0),direction.Unit*range,params)
        if hit then distance=math.min(distance,hit.Distance) end
    end
    return distance
end
local function escapeLanding(pos,referenceY,params,maxDrop)
    local root,h=charRoot(),human()
    if not root or not h then return nil end
    local origin=Vector3.new(pos.X,referenceY+3.5,pos.Z)
    local hit=workspace:Raycast(origin,Vector3.new(0,-17,0),params)
    if not hit or hit.Normal.Y<.7 then return nil end
    local expectedY=hit.Position.Y+h.HipHeight+root.Size.Y*.5+.12
    if expectedY>referenceY+2.7 or expectedY<referenceY-(maxDrop or 5.5) then return nil end
    return Vector3.new(pos.X,expectedY,pos.Z)
end
local function rotateFlat(v,degrees)
    return CFrame.fromAxisAngle(Vector3.yAxis,math.rad(degrees)):VectorToWorldSpace(v)
end
local function gridCell(p)
    return tostring(math.floor(p.X/6))..":"..tostring(math.floor(p.Z/6))
end
-- Planejador de longo alcance. Calcula no maximo cinco alternativas por rodada,
-- e publica o resultado sem bloquear as leituras do radar.
-- V5 | Mapeamento dinamico do andar atualmente carregado.
-- Este cache e local. Ele nao baixa modelos nem descobre andares nao carregados.
local navigationMap={room=nil,byCell={},samples={},count=0,cycle=0}
local function resetNavigationMap()
    local room=currentMap()
    if navigationMap.room~=room then
        navigationMap={room=room,byCell={},samples={},count=0,cycle=0}
    end
end
local function rememberWalkable(point,referenceY,params)
    resetNavigationMap()
    local landing=escapeLanding(point,referenceY,params,6.5)
    if not landing then return nil end
    local key=gridCell(landing)
    local old=navigationMap.byCell[key]
    if old then return old end
    local directions={
        Vector3.new(1,0,0),Vector3.new(-1,0,0),
        Vector3.new(0,0,1),Vector3.new(0,0,-1)
    }
    local exits,clearance=0,0
    for _,dir in ipairs(directions) do
        local free=radarClearance(landing,dir,9,params)
        if free>5.4 then exits=exits+1 end
        clearance=clearance+free
    end
    -- Nao registra pontos completamente cercados como refúgios.
    if exits==0 then return nil end
    local rec={point=landing,exits=exits,clearance=clearance/4,key=key}
    navigationMap.byCell[key]=rec
    navigationMap.count=navigationMap.count+1
    table.insert(navigationMap.samples,rec)
    -- Cache limitado para nao sobrecarregar memoria do Android.
    if #navigationMap.samples>420 then
        local removed=table.remove(navigationMap.samples,1)
        if navigationMap.byCell[removed.key]==removed then
            navigationMap.byCell[removed.key]=nil
        end
    end
    return rec
end
-- Faz pequenas amostragens ao redor do jogador em vez de escanear tudo em um frame.
task.spawn(function()
    while live do
        if state.autoPlay and charRoot() and currentMap() then
            resetNavigationMap()
            local root=charRoot()
            local params=escapeRayParams()
            for _=1,10 do
                if not live or not state.autoPlay or not root or not root.Parent then break end
                navigationMap.cycle=navigationMap.cycle+1
                local n=navigationMap.cycle
                local angle=(n%20)*18
                local ring=math.floor((n/20)%5)+1
                local radius=ring*10
                local heading=rotateFlat(Vector3.new(1,0,0),angle)
                rememberWalkable(root.Position+heading*radius,root.Position.Y,params)
                task.wait(.035)
            end
        end
        task.wait(.45)
    end
end)

local function escapeCandidates(pos,foeDistance,params,visited)
    local candidates={}
    local used={}
    local function add(rec)
        if not rec or used[rec.key] then return end
        local travel=flatDistance(pos,rec.point)
        if travel<10 or travel>73 then return end
        local enemyDistance=enemyAt(rec.point)
        if enemyDistance<foeDistance+7 then return end
        used[rec.key]=true
        local score=(enemyDistance-foeDistance)*1.6+
            rec.exits*4+rec.clearance*1.3-
            travel*.17-(visited[rec.key] or 0)*7-staticDanger(rec.point)*1.5
        table.insert(candidates,{rec=rec,score=score})
    end
    for _,rec in ipairs(navigationMap.samples) do add(rec) end
    local foe=nearestPursuer()
    local enemyPos=foe and positionOf(foe)
    if enemyPos then
        local away=Vector3.new(pos.X-enemyPos.X,0,pos.Z-enemyPos.Z)
        if away.Magnitude<.2 then away=Vector3.new(1,0,0) end
        away=away.Unit
        for _,radius in ipairs({18,30,43,55}) do
            for _,a in ipairs({0,50,-50,90,-90,135,-135,180}) do
                local proposed=pos+rotateFlat(away,a)*radius
                add(rememberWalkable(proposed,pos.Y,params))
            end
        end
    end
    table.sort(candidates,function(a,b)return a.score>b.score end)
    return candidates
end
local function corridorClear(pos,dir,maxRange,params)
    if dir.Magnitude<.05 then return true end
    local direction=dir.Unit
    local side=Vector3.new(-direction.Z,0,direction.X)
    local range=math.min(maxRange,5.5)
    -- Grade baixa, base de estante e porta estreita: 5 raios em altura
    -- e 3 na largura. O raycast ja usa as pecas com colisao.
    return radarClearance(pos,direction,range,params)>=range-.45
        and radarClearance(pos+side*1.15,direction,range,params)>=range-.45
        and radarClearance(pos-side*1.15,direction,range,params)>=range-.45
end
local function cancelEscapeRoute(ctx)
    ctx.route=nil
    ctx.routeIndex=2
    ctx.needRoute=true
    if ctx.blockConnection then
        ctx.blockConnection:Disconnect()
        ctx.blockConnection=nil
    end
end
local function setEscapeRoute(ctx,path,waypoints,score)
    if not ctx.active then return end
    cancelEscapeRoute(ctx)
    ctx.route=waypoints
    ctx.routeIndex=2
    ctx.routeScore=score
    ctx.routeTime=os.clock()
    ctx.needRoute=false
    ctx.blockConnection=path.Blocked:Connect(function(i)
        if ctx.active and i>=ctx.routeIndex then
            ctx.blocked=true
            ctx.needRoute=true
        end
    end)
end
local function planEscapeRoutes(ctx,serial)
    task.spawn(function()
        while ctx.active and movementAlive(serial) and os.clock()<ctx.deadline do
            local root=charRoot()
            local foe,distance=nearestPursuer()
            if not root or not foe or distance>=SAFE_RANGE then break end
            local now=os.clock()
            if ctx.needRoute or not ctx.route then
                local start=root.Position
                local options=escapeCandidates(start,distance,escapeRayParams(),ctx.visited)
                local selectedPath,selectedWaypoints,selectedScore=nil,nil,-math.huge
                for i=1,math.min(4,#options) do
                    if not ctx.active or not movementAlive(serial) then return end
                    local target=options[i]
                    local path,wps=buildPath(start,target.rec.point)
                    if path and wps and #wps>1 then
                        local shortest=lengthOf(wps)
                        local minimumSafety=math.huge
                        local dangerPenalty=0
                        for _,wp in ipairs(wps) do
                            local d=enemyAt(wp.Position)
                            minimumSafety=math.min(minimumSafety,d)
                            if d<18 then dangerPenalty=dangerPenalty+(18-d)*3 end
                        end
                        -- Penaliza desvios muito compridos, perigosos e que terminam em becos.
                        local score=target.score+math.min(90,minimumSafety)*.75-
                            shortest*.45-dangerPenalty
                        if target.rec.exits<2 then score=score-17 end
                        for _,wp in ipairs(wps) do
                            score=score-staticDanger(wp.Position)*.13
                        end
                        if score>selectedScore then
                            selectedPath,selectedWaypoints,selectedScore=path,wps,score
                        end
                    end
                end
                local current=charRoot()
                -- Nao aplica rota se o avatar ja saiu muito do ponto de calculo.
                if ctx.active and current and movementAlive(serial) and selectedPath then
                    if flatDistance(current.Position,start)<15 then
                        local changed=(not ctx.route or ctx.needRoute or ctx.blocked)
                        if changed then
                            setEscapeRoute(ctx,selectedPath,selectedWaypoints,selectedScore)
                            ctx.blocked=false
                        end
                    else
                        ctx.needRoute=true
                    end
                end
            end
            task.wait(.33)
        end
    end)
end

local function emergencyDirection(ctx,pos,params,foe)
    local enemyPos=foe and positionOf(foe)
    local away=enemyPos and Vector3.new(pos.X-enemyPos.X,0,pos.Z-enemyPos.Z)
        or Vector3.new(1,0,0)
    if away.Magnitude<.15 then away=Vector3.new(1,0,0) end
    away=away.Unit
    local best,scoreBest=nil,-math.huge
    local d=enemyAt(pos)
    for _,a in ipairs({0,38,-38,75,-75,110,-110,155,-155,180}) do
        local dir=rotateFlat(away,a)
        local clear=radarClearance(pos,dir,11,params)
        if clear>5.7 and corridorClear(pos,dir,4.2,params) then
            local step=math.min(clear-1.4,6)
            local landing=escapeLanding(pos+dir*step,pos.Y,params,5.5)
            if landing then
                local rec=rememberWalkable(landing,pos.Y,params)
                if rec then
                    local safe=enemyAt(landing)
                    local memory=ctx.visited[gridCell(landing)] or 0
                    local score=(safe-d)*3+clear*.9+
                        rec.exits*2.5+rec.clearance*.45-memory*5.5
                        -staticDanger(landing)*1.2
                    -- Manter a direcao viavel evita zigue-zague junto a paredes.
                    if ctx.heading and dir:Dot(ctx.heading)>.82 then
                        score=score+8
                    end
                    if ctx.lastBlocked and os.clock()<ctx.blockedUntil
                        and dir:Dot(ctx.lastBlocked)>.6 then
                        score=score-42
                    end
                    if score>scoreBest and safe>=math.max(5,d-5) then
                        best=dir
                        scoreBest=score
                    end
                end
            end
        end
    end
    return best
end

local function startContinuousFleeMotor(ctx,serial)
    -- RenderStepped apos o controle padrao: produz deslocamento constante,
    -- sem MoveTo de 4.5 studs a cada 0.38s.
    local key="DOUBLEX_DANDY_ESCAPE_"..tostring(serial)
    local bound=pcall(function()
        RunService:BindToRenderStep(key,Enum.RenderPriority.Input.Value+2,function()
            if not ctx.active or not movementAlive(serial) then return end
            local h=human()
            if not h then return end
            if state.speed and h.WalkSpeed~=state.speedValue then
                h.WalkSpeed=state.speedValue
            end
            local direction=ctx.desiredDirection
            if direction and direction.Magnitude>.05 then
                h:Move(direction.Unit,false)
            else
                h:Move(Vector3.zero,false)
            end
        end)
    end)
    ctx.motorBound=bound
    ctx.motorKey=key
end
local function stopContinuousFleeMotor(ctx)
    ctx.desiredDirection=nil
    if ctx.motorBound and ctx.motorKey then
        pcall(function()RunService:UnbindFromRenderStep(ctx.motorKey)end)
    end
    local h=human()
    if h and h.Parent then pcall(function()h:Move(Vector3.zero,false)end)end
    ctx.motorBound=false
end

local function escapeDanger(serial)
    if not movementAlive(serial) then return "cancelled" end
    resetNavigationMap()
    say("FUGA V5: lendo o andar e planejando rotas...")
    local ctx={
        active=true,deadline=os.clock()+27,route=nil,routeIndex=2,
        routeTime=0,routeScore=-math.huge,needRoute=true,
        blockConnection=nil,blocked=false,visited={},
        heading=nil,lastBlocked=nil,blockedUntil=0,
        lastPos=nil,lastProgress=os.clock(),lastVisit=0,lastMove=0,
        lastWarn=0,lastEmergencyScan=0,emergencyHeading=nil,
        lastOpenPos=nil,lastOpenTime=0,
        desiredDirection=nil,lastMotorFallback=0,motorBound=false
    }
    startContinuousFleeMotor(ctx,serial)
    planEscapeRoutes(ctx,serial)
    local function finish(reason,message,stop)
        ctx.active=false
        cancelEscapeRoute(ctx)
        stopContinuousFleeMotor(ctx)
        if stop then freezeMove() end
        say(message)
        return reason
    end
    while movementAlive(serial) and os.clock()<ctx.deadline do
        local root,h=charRoot(),human()
        if not root or not h then return finish("cancelled","Fuga cancelada",false) end
        local foe,dist=nearestPursuer()
        local info=workspace:FindFirstChild("Info")
        local complete=info and info:FindFirstChild("GeneratorsCompleted")
        local needed=info and info:FindFirstChild("RequiredGenerators")
        if complete and needed and tonumber(complete.Value) and tonumber(needed.Value)
            and needed.Value>0 and complete.Value>=needed.Value then
            return finish("elevator","Maquinas prontas! Indo para o elevador.",false)
        end
        if not foe or dist>=SAFE_RANGE then
            return finish("safe","Distancia segura. Fuga concluida.",true)
        end
        local pos=root.Position
        local now=os.clock()
        local params=escapeRayParams()
        if ctx.heading and radarClearance(pos,ctx.heading,5,params)>4.5 then
            if now-ctx.lastOpenTime>.45 then
                ctx.lastOpenPos=pos
                ctx.lastOpenTime=now
            end
        end
        if not ctx.lastPos then ctx.lastPos=pos end
        if flatDistance(pos,ctx.lastPos)>1.1 then
            ctx.lastProgress=now
            ctx.lastPos=pos
        elseif ctx.heading and now-ctx.lastProgress>1.05 then
            ctx.lastBlocked=ctx.heading
            ctx.blockedUntil=now+1.5
            ctx.heading=nil
            cancelEscapeRoute(ctx)
            ctx.lastProgress=now
            ctx.lastPos=pos
        end
        if now-ctx.lastVisit>.65 then
            local key=gridCell(pos)
            ctx.visited[key]=math.min(15,(ctx.visited[key] or 0)+1)
            ctx.lastVisit=now
        end
        if ctx.blocked then cancelEscapeRoute(ctx);ctx.blocked=false end

        -- Seguir um percurso inteiro, sem trocar de direcao em cada frame.
        local command=nil
        if ctx.route and now-ctx.routeTime<18 then
            while ctx.routeIndex<=#ctx.route do
                local wp=ctx.route[ctx.routeIndex]
                if flatDistance(pos,wp.Position)<=2.8 then
                    ctx.routeIndex=ctx.routeIndex+1
                else
                    local delta=Vector3.new(wp.Position.X-pos.X,0,wp.Position.Z-pos.Z)
                    if delta.Magnitude>.15 then
                        local dir=delta.Unit
                        -- O proprio Pathfinding ja calculou um corredor valido.
                        -- Raycast lateral antes de cada waypoint causava falsos bloqueios
                        -- em portas/estantes e fazia abandonar a rota a cada instante.
                        -- So descarta se a geometria realmente mudou ou ficar preso.
                        local scan=radarClearance(pos,dir,
                            math.min(3.8,delta.Magnitude),params)
                        if delta.Magnitude>3.3 and scan<2.25 then
                            -- Grade/estante bloqueou o corredor da rota calculada.
                            ctx.lastBlocked=dir
                            ctx.blockedUntil=now+2
                            ctx.emergencyHeading=nil
                            cancelEscapeRoute(ctx)
                        else
                            command=wp.Position
                            ctx.heading=dir
                            if wp.Action==Enum.PathWaypointAction.Jump then
                                requestJump(h)
                            end
                        end
                    end
                    break
                end
            end
            if ctx.route and ctx.routeIndex>#ctx.route then
                cancelEscapeRoute(ctx)
            end
        elseif ctx.route then
            cancelEscapeRoute(ctx)
        end

        -- Enquanto planeja outra rota, faz pequenos movimentos em direcoes verificadas.
        if not command then
            -- Se preso numa grade, primeiro tente retornar ao ultimo corredor
            -- realmente aberto; sem teleportar ou bater na mesma estrutura.
            if ctx.lastOpenPos and ctx.lastBlocked and now<ctx.blockedUntil then
                local back=Vector3.new(ctx.lastOpenPos.X-pos.X,0,
                    ctx.lastOpenPos.Z-pos.Z)
                if back.Magnitude>3 and back.Magnitude<17 and
                    corridorClear(pos,back.Unit,math.min(4,back.Magnitude),params) then
                    command=ctx.lastOpenPos
                    ctx.heading=back.Unit
                    ctx.lastOpenPos=nil
                end
            end
        end
        if not command then
            -- Limita varreduras pesadas no celular sem perder o sensor frontal.
            local dir=ctx.emergencyHeading
            local valid=dir and corridorClear(pos,dir,4.5,params)
            if not valid or now-ctx.lastEmergencyScan>1.0 then
                dir=emergencyDirection(ctx,pos,params,foe)
                ctx.emergencyHeading=dir
                ctx.lastEmergencyScan=now
            end
            if dir and corridorClear(pos,dir,4.5,params) then
                ctx.heading=dir
                command=pos+dir*4.5
            else
                ctx.heading=nil
                ctx.needRoute=true
                if now-ctx.lastWarn>1.5 then
                    say("Fuga sem passagem confirmada: assuma o controle se necessario!")
                    ctx.lastWarn=now
                end
            end
        end
        if command then
            local delta=Vector3.new(command.X-pos.X,0,command.Z-pos.Z)
            ctx.desiredDirection=delta.Magnitude>.2 and delta.Unit or nil
            if not ctx.motorBound and now-ctx.lastMotorFallback>1.1 then
                -- Fallback para clientes que bloqueiam BindToRenderStep.
                if ctx.desiredDirection then
                    h:MoveTo(pos+ctx.desiredDirection*15)
                end
                ctx.lastMotorFallback=now
            end
        else
            ctx.desiredDirection=nil
        end
        task.wait(.10)
    end
    if not movementAlive(serial) then return finish("cancelled","Fuga cancelada.",false) end
    return finish("timeout","Fuga sem caminho garantido; controle manual.",true)
end

-- Ponto de extracao: filtra alvos proximos que estao atras de parede.
local function machineAccess(target,candidate,focus,limit)
    if not target or not candidate or not focus then return false end
    if flatDistance(candidate,focus)>(limit or 10) then return false end
    if staticDanger(candidate)>92 then return false end
    local ray=RaycastParams.new()
    ray.FilterType=Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances={LP.Character,target}
    ray.IgnoreWater=true
    pcall(function()ray.RespectCanCollide=true end)
    local begin=candidate+Vector3.new(0,.55,0)
    local endpoint=Vector3.new(focus.X,focus.Y+.55,focus.Z)
    local delta=endpoint-begin
    if delta.Magnitude<.6 then return true end
    local hit=workspace:Raycast(begin,delta,ray)
    -- Se um objeto nao pertencente a maquina esta entre eles, e parede.
    return not hit
end

-- Encontra piso real da cabine por nomes ou geometria; evita parede/porta.
local function elevatorFloor(target)
    if not target then return nil end
    local root=charRoot()
    local best,bestScore=nil,-math.huge
    for _,part in ipairs(target:GetDescendants()) do
        if part:IsA("BasePart") and part.Size.X>4 and part.Size.Z>4 then
            local n=part.Name:lower()
            local flat=part.Size.Y<3.5
            local named=n:find("floor") or n:find("platform")
                or n:find("base") or n:find("interior") or n:find("inside")
            if flat or named then
                local area=part.Size.X*part.Size.Z
                if area>=28 and area<=2200 then
                    local diff=root and math.abs(root.Position.Y-part.Position.Y) or 0
                    local score=(named and 120 or 0)+(flat and 32 or 0)
                        +math.min(area,500)*.06-math.max(0,diff-3)*6
                    if score>bestScore then best,bestScore=part,score end
                end
            end
        end
    end
    return best
end
local function elevatorInside(target)
    local root=charRoot()
    if not root or not target then return false end
    local floor=elevatorFloor(target)
    if floor then
        local p=floor.CFrame:PointToObjectSpace(root.Position)
        return math.abs(p.X)<math.max(1,floor.Size.X*.5-1.2)
            and math.abs(p.Z)<math.max(1,floor.Size.Z*.5-1.2)
            and p.Y>-1.0 and p.Y<11
    end
    if target:IsA("Model") then
        local cf,size=target:GetBoundingBox()
        local p=cf:PointToObjectSpace(root.Position)
        return math.abs(p.X)<size.X*.22 and math.abs(p.Z)<size.Z*.22
            and math.abs(p.Y)<math.max(8,size.Y*.45)
    end
    return false
end
local function elevatorInteriorGoal(target,root)
    local h=human()
    if not root or not h then return nil,nil end
    local floor=elevatorFloor(target)
    if floor then
        local rise=floor.Size.Y*.5+h.HipHeight+root.Size.Y*.5+.15
        return floor.Position+floor.CFrame.UpVector*rise,floor.CFrame
    end
    if target:IsA("Model") then
        local cf=select(1,target:GetBoundingBox())
        return onFloor(cf.Position) or cf.Position,cf
    end
    return onFloor(positionOf(target)),target.CFrame
end
-- Aproximacao final sem teleporte: apenas move o Humanoid para dentro.
local function finishElevatorEntry(target,serial)
    if elevatorInside(target) then freezeMove();return true end
    local root=charRoot()
    local destination=select(1,elevatorInteriorGoal(target,root))
    if not root or not destination or flatDistance(root.Position,destination)>31 then
        return false
    end
    local start=os.clock()
    local progress=root.Position
    local stagnated=start
    while movementAlive(serial) and os.clock()-start<3.2 do
        if elevatorInside(target) then freezeMove();return true end
        local r,h=charRoot(),human()
        if flatDistance(r.Position,progress)>.5 then
            stagnated=os.clock()
            progress=r.Position
        end
        if os.clock()-stagnated>1.2 then
            -- Nao atravessa parede: caso bloqueado, deixa para um novo caminho.
            freezeMove()
            return false
        end
        h:MoveTo(destination)
        task.wait(.12)
    end
    if elevatorInside(target) then freezeMove();return true end
    return false
end
local function elevatorDiagnostic()
    local root=charRoot()
    local elevator=select(1,nearest("elevator"))
    local rows={"DOUBLEX DANDY V10 - DIAGNOSTICO ELEVADOR"}
    table.insert(rows,"Player: "..(root and tostring(root.Position) or "ausente"))
    if elevator then
        table.insert(rows,"Modelo: "..elevator:GetFullName())
        table.insert(rows,"Dentro: "..tostring(elevatorInside(elevator)))
        local floor=elevatorFloor(elevator)
        table.insert(rows,"Piso detectado: "..(floor and floor:GetFullName() or "nenhum"))
        local goal=select(1,elevatorInteriorGoal(elevator,root))
        table.insert(rows,"Objetivo interno: "..(goal and tostring(goal) or "nenhum"))
        local count=0
        for _,part in ipairs(elevator:GetDescendants()) do
            if part:IsA("BasePart") and count<45 then
                count=count+1
                table.insert(rows,part.Name.." | "..tostring(part.Position).." | "..tostring(part.Size))
            end
        end
    else
        table.insert(rows,"Elevador nao encontrado.")
    end
    local report=table.concat(rows,"\n")
    print(report)
    if type(setclipboard)=="function" then
        local ok=pcall(function()setclipboard(report)end)
        say(ok and "Diagnostico do elevador copiado!" or "Falha ao copiar diagnostico.")
    else
        say("Diagnostico no console Delta.")
    end
end

local function pickReachableGoal(kind,target,serial,dropTries)
    local root=charRoot()
    local center=positionOf(target)
    if not root or not center then return nil end
    if kind=="elevator" then
        local interior,orientation=elevatorInteriorGoal(target,root)
        if interior then
            local best,bestScore=nil,math.huge
            for _,offset in ipairs({Vector3.new(0,0,0),Vector3.new(1.7,0,0),
                    Vector3.new(-1.7,0,0),Vector3.new(0,0,1.7),
                    Vector3.new(0,0,-1.7)}) do
                if not movementAlive(serial) then return nil end
                local targetPos=interior+orientation:VectorToWorldSpace(offset)
                if math.abs(targetPos.Y-root.Position.Y)<14 then
                    local _,wps=buildPath(root.Position,targetPos)
                    if wps then
                        local score=lengthOf(wps)+offset.Magnitude
                        if score<bestScore then best,bestScore=targetPos,score end
                    end
                end
            end
            if best then return best end
        end
        -- Fallback: encontra a entrada, mas NAO considera isso como ter entrado.
        local doors={}
        for _,piece in ipairs(target:GetDescendants()) do
            if piece:IsA("BasePart") then
                local title=piece.Name:lower()
                if title:find("door") or title:find("entrance") or
                   title:find("entry") or title:find("enter") then
                    table.insert(doors,piece.Position)
                    if #doors>=3 then break end
                end
            end
        end
        if #doors==0 then table.insert(doors,center) end
        local best,bestScore=nil,math.huge
        local params=escapeRayParams()
        for _,anchor in ipairs(doors) do
            for _,degrees in ipairs({0,90,180,270}) do
                if not movementAlive(serial) then return nil end
                local direction=rotateFlat(Vector3.new(1,0,0),degrees)
                local candidate=escapeLanding(anchor+direction*4.8,root.Position.Y,params,9)
                if candidate then
                    local _,wps=buildPath(root.Position,candidate)
                    if wps then
                        local score=lengthOf(wps)+flatDistance(candidate,anchor)
                        if score<bestScore then best,bestScore=candidate,score end
                    end
                end
            end
        end
        return best
    end
    if kind~="machines" then
        return onFloor(center,target) or center
    end
    -- Testa pontos EM VOLTA da maquina, nunca apenas o centro do modelo.
    -- Isso impede tentar cruzar parede/caixa ou parar na cerca.
    local toward=Vector3.new(root.Position.X-center.X,0,root.Position.Z-center.Z)
    if toward.Magnitude<.2 then toward=Vector3.new(1,0,0) end
    toward=toward.Unit
    local baseRadius=4.6
    local part=modelPart(target)
    if part then
        baseRadius=math.clamp(math.max(part.Size.X,part.Size.Z)*.5+2.6,4.6,7)
    end
    local best,bestScore=nil,math.huge
    local preferred=nil
    local interactionRange=10
    for _,desc in ipairs(target:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local parent=desc.Parent
            if parent and parent:IsA("BasePart") then
                preferred=parent.Position
                interactionRange=math.max(5,desc.MaxActivationDistance+2)
                break
            elseif parent and parent:IsA("Attachment") then
                preferred=parent.WorldPosition
                interactionRange=math.max(5,desc.MaxActivationDistance+2)
                break
            end
        end
    end
    preferred=preferred or center
    for _,radius in ipairs({baseRadius,baseRadius+3}) do
        for _,angle in ipairs({0,45,-45,90,-90,135,-135,180}) do
            if not movementAlive(serial) then return nil end
            if enemyAt(charRoot().Position)<DANGER_RANGE then return nil,"danger" end
            local direction=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(angle)):VectorToWorldSpace(toward)
            local sample=center+direction*radius
            local candidate=onFloor(sample,target)
            if candidate and math.abs(candidate.Y-root.Position.Y)<16
                and machineAccess(target,candidate,preferred,interactionRange) then
                local path,wps=buildPath(root.Position,candidate)
                if path then
                    local goalGap=flatDistance(candidate,preferred)
                    local score=lengthOf(wps)+goalGap*1.1+staticDanger(candidate)*.65
                    if score<bestScore then
                        best,bestScore=candidate,score
                    end
                end
            end
        end
        -- Segunda faixa so se nenhuma entrada foi encontrada na primeira.
        if best then break end
    end
    -- Se comecou em cima de cerca/mesa e nenhum caminho existe,
    -- tenta uma descida curta antes de procurar as entradas novamente.
    if not best and (dropTries or 0)<2 and movementAlive(serial) then
        say("Sem rota deste nivel; buscando descida segura...")
        if trySafeDrop(center,serial,true) then
            return pickReachableGoal(kind,target,serial,(dropTries or 0)+1)
        end
    end
    return best
end
local function walkToTarget(kind,target,serial,prioritizeElevator)
    if not movementAlive(serial) then return "cancelled" end
    if not target or not target.Parent then return "missing" end
    local urgent=kind=="elevator" and prioritizeElevator
    if not urgent and enemyAt(charRoot().Position)<DANGER_RANGE then
        escapeDanger(serial)
        return "danger"
    end
    say("Buscando rota livre ate "..(names[kind] or kind).."...")
    local goal,reason=pickReachableGoal(kind,target,serial)
    if reason=="danger" or (not urgent and movementAlive(serial) and enemyAt(charRoot().Position)<DANGER_RANGE) then
        escapeDanger(serial)
        return "danger"
    end
    if not goal then
        if kind=="elevator" and finishElevatorEntry(target,serial) then return "arrived" end
        say(kind=="elevator" and "Entrada nao navegavel; tentarei de novo."
            or "Sem entrada acessivel. Tentarei outra maquina.")
        return "no_path"
    end
    say((urgent and "ELEVADOR PRIORITARIO: rota mais segura..." or "Caminhando ate "..(names[kind] or kind).." (anti-trava ON)"))
    if kind=="elevator" and finishElevatorEntry(target,serial) then return "arrived" end
    local result=walkPath(goal,serial,not urgent,kind=="elevator" and 1.35 or 4)
    if result=="danger" and not urgent then
        escapeDanger(serial)
        return "danger"
    end
    if kind=="elevator" and not elevatorInside(target) then
        if finishElevatorEntry(target,serial) then
            say("Entrada confirmada: dentro da cabine!")
            return "arrived"
        end
        say("Ainda fora da cabine. Recalculando sem teleporte.")
        return "entrance"
    end
    if result=="arrived" then say("Cheguei ao lado da "..(names[kind] or kind)..".")
    elseif result=="blocked" then say("Rota travada apos 3 tentativas. Outra rota sera buscada.")
    elseif result=="no_path" then say("Sem caminho caminhavel; ignorando essa rota.") end
    return result
end

local function walkToward(kind)
    state.autoPlay=false
    autoRunId=autoRunId+1
    if buttonList.autoPlay then buttonList.autoPlay()end
    stopNav()
    local serial=navSerial
    local target=nearest(kind)
    if not target then say("Nao encontrei "..(names[kind] or kind).." nesta sala.");return end
    task.spawn(function()walkToTarget(kind,target,serial)end)
end
-- Auto assistente: escolhe maquina longe de inimigos, anda, tenta prompt se houver.
-- Skill checks e interacoes personalizadas permanecem manuais.
local ignored={}
local function safeMachine()
    local r=charRoot()
    if not r then return nil,"sem personagem" end
    local best,score=nil,math.huge
    local waiting,unsafe,occupiedCount,available=0,0,0,0
    for _,o in ipairs(getObjects("machines"))do
        if o.Parent and not machineFinished(o) then
            available=available+1
            if (ignored[o] or 0)>=os.clock() then
                waiting=waiting+1
            else
                local p=positionOf(o)
                if p then
                    local safety=enemyAt(p)
                    local dist=flatThreatDistance(p,r.Position)
                    local stillRisk=staticDanger(p)
                    local movingPenalty=math.max(0,90-safety)*3
                    local scoreHere=dist+movingPenalty+stillRisk*1.5
                    local occupied=false
                    local stats=o:FindFirstChild("Stats")
                    for _,key in ipairs({"Possessed","Possessing","IsPossessed","Haunted"}) do
                        local v=o:GetAttribute(key)
                        local child=(stats and stats:FindFirstChild(key)) or o:FindFirstChild(key)
                        if v==true or (child and child:IsA("BoolValue") and child.Value) then
                            occupied=true
                            break
                        end
                    end
                    for _,monster in ipairs(getObjects("monsters")) do
                        if twistedClass(monster)=="machine_possessor" then
                            local cp=positionOf(monster)
                            if cp and flatThreatDistance(cp,p)<10 then occupied=true end
                        end
                    end
                    if occupied then
                        occupiedCount=occupiedCount+1
                    elseif safety<=19 or stillRisk>92 then
                        unsafe=unsafe+1
                    elseif scoreHere<score then
                        best,score=o,scoreHere
                    end
                end
            end
        end
    end
    if best then return best,"ok" end
    if available==0 then return nil,"sem maquinas restantes" end
    if waiting>0 then
        return nil,string.format("%d maquina(s) em espera de nova rota; %d com risco; %d ocupadas",
            waiting,unsafe,occupiedCount)
    end
    return nil,string.format("%d maquina(s) com risco; %d ocupadas",unsafe,occupiedCount)
end

local function attemptPrompt(machine)
    local r=charRoot()
    if not r then return false end
    for _,obj in ipairs(machine:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local pp=obj.Parent
            local ppPos=(pp and pp:IsA("BasePart") and pp.Position)
                or (pp and pp:IsA("Attachment") and pp.WorldPosition) or positionOf(machine)
            if ppPos and (r.Position-ppPos).Magnitude<=(obj.MaxActivationDistance+1)
                and machineAccess(machine,r.Position,ppPos,obj.MaxActivationDistance+1) then
                if type(fireproximityprompt)=="function" then
                    local ok=pcall(function()fireproximityprompt(obj)end)
                    if ok then return true end
                end
            end
        end
    end
    return false
end
local function allMachinesDone()
    local info=workspace:FindFirstChild("Info")
    local d=info and info:FindFirstChild("GeneratorsCompleted")
    local t=info and info:FindFirstChild("RequiredGenerators")
    if d and t and tonumber(d.Value) and tonumber(t.Value) and t.Value>0 then
        return d.Value>=t.Value
    end
    return false
end
local function automaticLoop(runId)
    local doneMap=nil
    local lastRoom=nil
    while live and state.autoPlay and runId==autoRunId do
        local room=currentMap()
        if not room then
            task.wait(1)
        else
            if room~=lastRoom then ignored={};doneMap=nil;lastRoom=room end
            if allMachinesDone() then
                -- Elevador nunca e tentativa unica: repete ao falhar.
                -- A chegada a borda externa pode exigir entrada manual.
                local target=nearest("elevator")
                if target and elevatorInside(target) then
                    say("Dentro do elevador. Aguardando a partida.")
                    task.wait(.65)
                elseif target then
                    stopNav()
                    local result=walkToTarget("elevator",target,navSerial,true)
                    if result=="arrived" and elevatorInside(target) then
                        say("Dentro do elevador! Aguardando proximo andar.")
                    elseif result=="entrance" then
                        say("Ainda na entrada; procurando caminho para DENTRO.")
                    else
                        say("Recalculando entrada do elevador...")
                    end
                else
                    say("Elevador nao localizado neste andar.")
                end
                task.wait(.25)
            elseif enemyAt((charRoot() and charRoot().Position) or Vector3.zero)<DANGER_RANGE then
                stopNav()
                escapeDanger(navSerial)
                task.wait(.15)
            else
                local target,reason=safeMachine()
                if not target then
                    say("Auto: "..tostring(reason or "nenhuma maquina liberada"))
                    task.wait(.8)
                else
                    stopNav()
                    local result=walkToTarget("machines",target,navSerial)
                    if result=="arrived" then
                        local activated=attemptPrompt(target)
                        if activated then say("Auto: prompt acionado; skill checks manuais.")
                        else say("Auto: toque para extrair; nao achei prompt compativel.") end
                        local startTime=os.clock()
                        local initial=machinePercent(target)
                        local progressed=false
                        while live and state.autoPlay and runId==autoRunId and not machineFinished(target) and os.clock()-startTime<110 do
                            local r=charRoot()
                            if not r or enemyAt(r.Position)<DANGER_RANGE then
                                stopNav();escapeDanger(navSerial);break
                            end
                            local pct=machinePercent(target)
                            if pct and initial and pct>initial then progressed=true end
                            if not progressed and os.clock()-startTime>12 then break end
                            task.wait(.25)
                        end
                        if not machineFinished(target) then ignored[target]=os.clock()+7 end
                    elseif result=="no_path" or result=="blocked" then
                        ignored[target]=os.clock()+9
                    end
                    task.wait(.3)
                end
            end
        end
    end
end
local function setAutoPlay(value)
    state.autoPlay=value
    autoRunId=autoRunId+1
    stopNav()
    if value then
        say("Auto V10 ON: entrada precisa no elevador e fuga!")
        local id=autoRunId
        task.spawn(function()automaticLoop(id)end)
    else
        say("Auto Beta desligado.")
    end
end

heading("LOCALIZADOR (ESP)")
for _,entry in ipairs({
    {"Twisteds / inimigos","monsters"},{"Maquinas incompletas","machines"},
    {"Itens no chao","items"},{"Elevador real","elevator"},
    {"Outros jogadores","players"}
}) do
    local label,key=entry[1],entry[2]
    addButton(label,function()
        state[key]=not state[key]
        if not state[key] then
            for obj,mark in pairs(markers) do
                if mark.kind==key then clearMarker(obj) end
            end
        else refreshMarkers() end
    end,key)
end
heading("SOBREVIVENCIA")

addButton("Aviso de Twisted proximo",function()state.danger=not state.danger end,"danger")
addButton("Iluminacao clara (Fullbright)",function()setBright(not state.bright)end,"bright")
addButton("Anti-AFK opcional",function()state.antiAFK=not state.antiAFK end,"antiAFK")
heading("VELOCIDADE")
addButton("Speed ON / OFF",function()
    setSpeed(not state.speed)
    say("Speed "..(state.speed and "ON" or "OFF").." | "..state.speedValue)
end,"speed")
-- Valor digitavel no teclado do celular, como no DOUBLEX Universal.
local speedBoxRow=inst("Frame",{
    Size=UDim2.new(1,-4,0,39),BackgroundColor3=C.card,BorderSizePixel=0
},scroll)
round(speedBoxRow,8)
inst("TextLabel",{
    Size=UDim2.new(.56,-2,1,0),Position=UDim2.fromOffset(9,0),
    BackgroundTransparency=1,Text="Speed (16 a 120):",Font=Enum.Font.GothamMedium,
    TextSize=12,TextColor3=C.white,TextXAlignment=Enum.TextXAlignment.Left
},speedBoxRow)
local speedInput=inst("TextBox",{
    Size=UDim2.new(.35,0,1,-7),Position=UDim2.new(.63,0,0,3),
    BackgroundColor3=C.off,BorderSizePixel=0,Text=tostring(state.speedValue),
    Font=Enum.Font.GothamBold,TextSize=15,TextColor3=C.white,
    PlaceholderText="26",ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Center
},speedBoxRow)
round(speedInput,7)
bind(speedInput.FocusLost,function()
    if not live then return end
    local raw=tostring(speedInput.Text or ""):gsub(",",".")
    local value=tonumber(raw)
    if not value or value~=value or value<16 or value>120 then
        speedInput.Text=tostring(state.speedValue)
        say("Digite um numero de 16 a 120 para o Speed.")
        return
    end
    state.speedValue=math.floor(value+.5)
    speedInput.Text=tostring(state.speedValue)
    if state.speed then setSpeed(true) end
    say("Speed configurado: "..tostring(state.speedValue))
end)

-- AUTO SKILLCHECK BETA (somente UI de PlayerGui; nao dispara remotes nem inventa acertos)
-- O jogo pode desenhar a barra com imagens nao divididas em Frames. Sem indicador e
-- alvo visiveis separados, o script NAO clica; use diagnostico para calibrar.
local function visibleGui(o)
    if not o or not o:IsA("GuiObject") or not o.Visible then return false end
    local p=o.Parent
    while p and p~=PG do
        if p:IsA("GuiObject") and not p.Visible then return false end
        if p:IsA("ScreenGui") and not p.Enabled then return false end
        p=p.Parent
    end
    return p==PG
end
local function skillText(o)
    if not o or not (o:IsA("TextButton") or o:IsA("TextLabel")) then
        return ""
    end
    return tostring(o.Text or ""):lower()
end
local function isSkillPrompt(o)
    local t=skillText(o)
    return t:find("verifica") or t:find("skillcheck") or t:find("skill check")
end
local function skillColor(o)
    if not o:IsA("GuiObject") then return nil end
    if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.ImageTransparency<.6 then
        return o.ImageColor3
    end
    if o.BackgroundTransparency<.7 then return o.BackgroundColor3 end
    return nil
end
local function redNeedle(o)
    local color=skillColor(o)
    local size=o.AbsoluteSize
    if not color or size.X<1 or size.X>17 or size.Y<13 or size.Y>110 then return false end
    local n=o.Name:lower()
    return n:find("cursor") or n:find("needle") or n:find("indicator")
        or (color.R>.62 and color.R>color.G*1.4 and color.R>color.B*1.45)
end
local function goldZone(o)
    local color=skillColor(o)
    local size=o.AbsoluteSize
    if not color or size.X<5 or size.X>100 or size.Y<7 or size.Y>90 then return false end
    local n=o.Name:lower()
    return n:find("yellow") or n:find("perfect") or n:find("gold")
        or (color.R>.66 and color.G>.4 and color.B<.5)
end
-- Seleciona botao clicavel ou texto do prompt, para o modo circular no Delta.
local function findSkillButton(all)
    local fallback=nil
    for _,o in ipairs(all) do
        if isSkillPrompt(o) and o.AbsoluteSize.X>85 then
            if o:IsA("TextButton") or o:IsA("ImageButton") then return o end
            if not fallback then fallback=o end
        end
    end
    return fallback
end
-- Detector de barra horizontal do novo HUD (diagnostico fornecido pelo jogador).
-- Shared.TapButton e um TextButton SEM texto. Seu filho Label contem o texto.
-- Nao procurar por botao cujo Text mencione "skillcheck".
local function findSkillElements()
    local screen=PG:FindFirstChild("Skillchecks")
    if not screen or not screen:IsA("ScreenGui") or not screen.Enabled then
        return nil,"ScreenGui Skillchecks indisponivel"
    end
    local horizontal=screen:FindFirstChild("Horizontal")
    local shared=screen:FindFirstChild("Shared")
    if not horizontal or not shared then
        return nil,"Horizontal ou Shared nao carregados"
    end
    local marker=horizontal:FindFirstChild("Marker")
    local required=horizontal:FindFirstChild("RequiredArea")
    local gold=horizontal:FindFirstChild("GoldArea")
    local sharedTap=shared:FindFirstChild("TapButton")
    local horizontalTap=horizontal:FindFirstChild("TapButton")
    if not marker or not gold or not required then
        return nil,"Marker, RequiredArea ou GoldArea ausentes"
    end
    if not (visibleGui(horizontal) and visibleGui(marker) and
        visibleGui(gold) and visibleGui(required)) then
        return nil,"barra horizontal oculta"
    end
    local button=nil
    if sharedTap and sharedTap:IsA("GuiButton") and visibleGui(sharedTap) then
        button=sharedTap
    elseif horizontalTap and horizontalTap:IsA("GuiButton") and visibleGui(horizontalTap) then
        button=horizontalTap
    end
    if not button then return nil,"TapButton nao disponivel" end
    if horizontal.AbsoluteSize.X<170 or gold.AbsoluteSize.X<5 or
        marker.AbsoluteSize.X<1 then
        return nil,"barra sem dimensoes validas"
    end
    return {
        bar=horizontal,needle=marker,required=required,gold=gold,
        button=button,screen=screen
    },nil
end

-- CIRCLE MACHINES: anel vermelho fica menor ate tocar zona cinza/dourada.
-- Heuristica por cores/UIStroke/nome e tamanho animado (sem remotes do servidor).
local circleSizes=setmetatable({}, {__mode="k"})
local circleScanAt=0
local circleInfo=nil
local circleLastWidth=nil
local circleLastAt=nil
local circleArmed=true
local circleActive=false
local function isRingRed(c)
    return c and c.R>.46 and c.R>c.G*1.48 and c.R>c.B*1.45
end
local function isRingGold(c)
    return c and c.R>.67 and c.G>.35 and c.R>c.B*1.42
end
local function ringColors(o)
    local colors={}
    if (o:IsA("ImageLabel") or o:IsA("ImageButton"))
        and o.ImageTransparency<.85 then
        table.insert(colors,o.ImageColor3)
    end
    if o.BackgroundTransparency<.85 then
        table.insert(colors,o.BackgroundColor3)
    end
    for _,c in ipairs(o:GetChildren()) do
        if c:IsA("UIStroke") and c.Enabled and c.Transparency<.8 then
            table.insert(colors,c.Color)
        end
    end
    return colors
end
local function circleElementScore(o)
    local p,z=o.AbsolutePosition,o.AbsoluteSize
    if z.X<65 or z.Y<65 or z.X>970 or z.Y>970
        or z.X/z.Y<.76 or z.X/z.Y>1.24 then
        return nil
    end
    local name=o.Name:lower()
    local red=0
    local target=0
    for _,color in ipairs(ringColors(o)) do
        if isRingRed(color) then red=math.max(red,6) end
        if isRingGold(color) then target=math.max(target,7) end
    end
    if name:find("red") or name:find("shrink") or name:find("moving") then
        red=math.max(red,5)
    end
    if name:find("gold") or name:find("yellow") or name:find("perfect") then
        target=math.max(target,6)
    elseif name:find("white") or name:find("grey") or
        name:find("gray") or name:find("target") then
        target=math.max(target,3)
    end
    if (name:find("circle") or name:find("ring")) and target==0 then
        target=1
    end
    local now=os.clock()
    local previous=circleSizes[o]
    local shrinking=previous and now-previous.t<.5
        and previous.w-z.X>.65 and previous.w-z.X<z.X*.4
    circleSizes[o]={w=z.X,t=now}
    if shrinking then red=math.max(red,4) end
    if red==0 and target==0 then
        -- Imagens nao tintadas podem carregar as faixas no proprio PNG.
        if (o:IsA("ImageLabel") or o:IsA("ImageButton"))
            and z.X>=100 and z.X<=350 then target=1 end
    end
    return {
        obj=o,red=red,target=target,width=z.X,
        cx=p.X+z.X*.5,cy=p.Y+z.Y*.5,shrinking=shrinking
    }
end
local function findCircleElements()
    if select(1,findSkillElements()) then return nil,"barra horizontal ativa" end
    local all,rounds={},{}
    for _,o in ipairs(PG:GetDescendants()) do
        if o:IsA("GuiObject") and not o:IsDescendantOf(gui) and visibleGui(o) then
            table.insert(all,o)
            local record=circleElementScore(o)
            if record then table.insert(rounds,record) end
        end
    end
    local button=findSkillButton(all)
    if not button then return nil,"prompt da verificacao nao encontrado" end
    local best,bestScore=nil,-math.huge
    for _,r in ipairs(rounds) do
        if r.red>0 then
            for _,g in ipairs(rounds) do
                if g.obj~=r.obj and g.target>0 and
                    g.width>=72 and g.width<=370 and
                    math.abs(r.cx-g.cx)<math.max(25,g.width*.14) and
                    math.abs(r.cy-g.cy)<math.max(25,g.width*.14) and
                    r.width>g.width*.73 and r.width<g.width*3.6 then
                    local score=r.red*5+g.target*5
                        +(r.shrinking and 9 or 0)
                        -math.abs(r.width-g.width)*.018
                    -- Prefere a faixa amarela real sobre o disco escuro.
                    if score>bestScore then
                        best,bestScore={red=r.obj,gold=g.obj,button=button},score
                    end
                end
            end
        end
    end
    if best then return best,nil end
    return nil,"anel vermelho e faixa circular ainda nao identificados"
end
local skillInfo=nil
local lastSkillScan=0
local skillNeedleLastX=nil
local skillNeedleLastAt=nil
local skillPressedAt=0
local skillStatusAt=0
local skillArmed=true
local function clickRealSkillButton(btn,preferSpace)
    local x=btn and (btn.AbsolutePosition.X+btn.AbsoluteSize.X*.5) or 0
    local y=btn and (btn.AbsolutePosition.Y+btn.AbsoluteSize.Y*.5) or 0
    local vim
    pcall(function()vim=game:GetService("VirtualInputManager")end)
    local function space()
        if vim then
            return pcall(function()
                vim:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
                vim:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
            end)
        end
        if type(keypress)=="function" and type(keyrelease)=="function" then
            return pcall(function()keypress(0x20);keyrelease(0x20)end)
        end
        return false
    end
    local function tap()
        if not btn or not vim then return false end
        return pcall(function()
            vim:SendMouseButtonEvent(x,y,0,true,game,0)
            vim:SendMouseButtonEvent(x,y,0,false,game,0)
        end)
    end
    if preferSpace then return space() or tap() end
    return tap() or space()
end
-- Loop circular independente do SkillCheck de linha.
bind(RunService.RenderStepped,function()
    if not live or not state.autoSkill then
        circleInfo=nil;circleLastWidth=nil;circleLastAt=nil
        circleArmed=true;circleActive=false
        return
    end
    local now=os.clock()
    if select(1,findSkillElements()) then
        circleInfo=nil;circleLastWidth=nil;circleLastAt=nil
        circleArmed=true;circleActive=false
        return
    end
    local valid=circleInfo and circleInfo.red.Parent and circleInfo.gold.Parent
        and circleInfo.button.Parent and visibleGui(circleInfo.red)
        and visibleGui(circleInfo.gold) and visibleGui(circleInfo.button)
    if not valid then
        circleInfo=nil;circleLastWidth=nil;circleLastAt=nil
        circleArmed=true;circleActive=false
    end
    if not circleInfo and now-circleScanAt>.105 then
        circleInfo=select(1,findCircleElements())
        circleScanAt=now
    end
    if not circleInfo then return end
    circleActive=true
    local red=circleInfo.red
    local gold=circleInfo.gold
    local rw=red.AbsoluteSize.X
    local gw=gold.AbsoluteSize.X
    if circleLastWidth and circleLastAt then
        local change=circleLastWidth-rw
        local shrink=change>.12 and now-circleLastAt<.22
        local diff=rw-gw
        local onTarget=diff<=math.max(9,gw*.085)
            and diff>=-math.max(9,gw*.13)
        local nearTarget=diff<=math.max(23,gw*.16)
            and diff>=-math.max(10,gw*.08)
        if circleArmed and shrink and (onTarget or
            (nearTarget and change>4))
            and now-skillPressedAt>.45 then
            local ok=clickRealSkillButton(circleInfo.button,true)
            if ok then
                circleArmed=false
                skillPressedAt=now
            end
            if now-skillStatusAt>1.3 then
                say(ok and "SkillCheck CIRCULAR: toque no anel (BETA)."
                    or "SkillCheck circular: toque nao enviado, use manual.")
                skillStatusAt=now
            end
        end
        if not circleArmed and rw>gw*1.45
            and now-skillPressedAt>.4 then
            circleArmed=true
        end
    end
    circleLastWidth=rw;circleLastAt=now
end)
-- Resposta a cada frame enquanto a faixa esta na tela. Busca rapida somente
-- quando nao localizada; conserva amostras de movimento entre frames.
bind(RunService.RenderStepped,function()
    if not live or not state.autoSkill then
        skillInfo=nil
        skillNeedleLastX=nil
        skillNeedleLastAt=nil
        skillArmed=true
        return
    end
    if circleActive then return end
    local now=os.clock()
    local valid=skillInfo and skillInfo.needle.Parent and skillInfo.gold.Parent
        and skillInfo.button.Parent and visibleGui(skillInfo.needle)
        and visibleGui(skillInfo.gold) and visibleGui(skillInfo.button)
    if not valid then
        skillInfo=nil
        skillNeedleLastX=nil
        skillNeedleLastAt=nil
        skillArmed=true
        if now-lastSkillScan>.09 then
            skillInfo=select(1,findSkillElements())
            lastSkillScan=now
        end
    end
    if not skillInfo then return end
    local needle=skillInfo.needle
    local gold=skillInfo.gold
    local nx=needle.AbsolutePosition.X+needle.AbsoluteSize.X*.5
    local gx=gold.AbsolutePosition.X+gold.AbsoluteSize.X*.5
    local width=gold.AbsoluteSize.X
    local margin=math.clamp(width*.35,2,11)
    if skillNeedleLastX and skillNeedleLastAt then
        local dt=now-skillNeedleLastAt
        if dt>.003 and dt<.18 then
            local velocity=(nx-skillNeedleLastX)/dt
            local moving=math.abs(nx-skillNeedleLastX)>.28
            -- Pequena antecipacao para compensar frames perdidos em Delta.
            local lead=math.clamp(dt*.6,.012,.032)
            local predicted=nx+velocity*lead
            local near=math.abs(nx-gx)<=margin
            local approaching=(gx-nx)*velocity>0
            local predictedNear=approaching and math.abs(predicted-gx)<=margin
                and math.abs(nx-gx)<math.max(width,14)
            if moving and skillArmed and (near or predictedNear)
                and now-skillPressedAt>.58 then
                local ok=clickRealSkillButton(skillInfo.button)
                if ok then
                    skillArmed=false
                    skillPressedAt=now
                end
                if now-skillStatusAt>1.2 then
                    say(ok and "SkillCheck V11: toque na zona verde (BETA)."
                        or "SkillCheck: Delta bloqueou entrada automatica.")
                    skillStatusAt=now
                end
            end
            -- Rearmar apenas quando o marcador reiniciar no inicio da barra,
            -- nao enquanto ele ainda se afasta do alvo apos um clique.
            if not skillArmed and now-skillPressedAt>.30
                and math.abs(nx-skillNeedleLastX)>skillInfo.bar.AbsoluteSize.X*.42
                and nx<skillInfo.bar.AbsolutePosition.X+
                    skillInfo.bar.AbsoluteSize.X*.25 then
                skillArmed=true
            end
        end
    end
    skillNeedleLastX=nx
    skillNeedleLastAt=now
end)

local function skillDiagnostic()
    local rows={"DOUBLEX DANDY V11 - UI SKILLCHECK","Visivel no momento do skillcheck", ""}
    local found,reason=findSkillElements()
    local foundCircle,reasonCircle=findCircleElements()
    table.insert(rows,found and "BARRA DETECTADA" or ("BARRA: "..tostring(reason)))
    table.insert(rows,foundCircle and "CIRCULO DETECTADO" or ("CIRCULO: "..tostring(reasonCircle)))
    local count=0
    for _,o in ipairs(PG:GetDescendants()) do
        if count>=95 then break end
        if o:IsA("GuiObject") and not o:IsDescendantOf(gui) and visibleGui(o) then
            local p,z=o.AbsolutePosition,o.AbsoluteSize
            local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
            local screenH=viewport and viewport.Y or 800
            if p.Y>screenH*.06 and p.Y<screenH*.99 then
                local circular=z.X>=65 and z.Y>=65 and z.Y>0
                    and z.X/z.Y>.75 and z.X/z.Y<1.28
                if circular or p.Y>screenH*.53 then
                    count=count+1
                    local bg=skillColor(o)
                    local rgb=bg and string.format("%d,%d,%d",math.floor(bg.R*255),math.floor(bg.G*255),math.floor(bg.B*255)) or "-"
                    local txt=skillText(o):sub(1,38)
                    local strokes=""
                    for _,c in ipairs(o:GetChildren()) do
                        if c:IsA("UIStroke") then
                            strokes=strokes..string.format(" STROKE(%d,%d,%d)",
                                math.floor(c.Color.R*255),math.floor(c.Color.G*255),
                                math.floor(c.Color.B*255))
                        end
                    end
                    table.insert(rows,string.format("%s [%s] X%d Y%d W%d H%d RGB(%s)%s %s",
                        o:GetFullName():sub(-90),o.ClassName,
                        math.floor(p.X),math.floor(p.Y),math.floor(z.X),math.floor(z.Y),rgb,strokes,txt))
                end
            end
        end
    end
    local report=table.concat(rows,"\n")
    if type(setclipboard)=="function" then
        local ok=pcall(function()setclipboard(report)end)
        say(ok and "Diagnostico copiado! Cole o texto no ChatGPT."
            or "Falha ao copiar. Consulte console Delta.")
    else
        say("Sem clipboard no Delta. Resultado no console.")
    end
    print(report)
end

heading("MAQUINAS / SKILLCHECK")
addButton("Auto SkillCheck linha + circulo (BETA)",function()
    state.autoSkill=not state.autoSkill
    skillInfo=nil
    skillNeedleLastX=nil
    skillNeedleLastAt=nil
    skillArmed=true
    circleInfo=nil
    circleArmed=true
    circleActive=false
    say(state.autoSkill and "Auto SkillCheck ON: linha + circulo (BETA)."
        or "Auto SkillCheck desligado.")
end,"autoSkill")
addButton("Diagnosticar SkillCheck (copiar)",function()
    skillDiagnostic()
end)

heading("AUTO BETA - TESTES MANUAIS")
addButton("Auto jogar: maquinas + fugir + elevador",function()
    setAutoPlay(not state.autoPlay)
end,"autoPlay")
heading("NAVEGACAO (SEM TELEPORTE)")
addButton("Diagnosticar elevador (copiar)",function()elevatorDiagnostic()end)
addButton("Caminhar ate maquina mais proxima",function()walkToward("machines")end)
addButton("Caminhar ate o elevador",function()walkToward("elevator")end)
addButton("Ir ao elevador apos ultima maquina",function()
    state.autoElev=not state.autoElev
    if not state.autoElev then lastAutoElevatorMap=nil end
end,"autoElev")
addButton("PARAR caminhada / auto",function()
    setAutoPlay(false);stopNav();
    if buttonList.autoPlay then buttonList.autoPlay()end
    say("Movimento automatico interrompido")
end)
heading("AJUDA")
addButton("Atualizar localizadores",function()refreshMarkers();say("Localizadores atualizados")end)
addButton("Desligar todos os ESPs",function()
    for _,k in ipairs({"monsters","machines","items","elevator","players"}) do
        state[k]=false
        if buttonList[k] then buttonList[k]() end
    end
    clearAllMarkers();say("Todos ESPs desligados")
end)

local function countMachines()
    local info=workspace:FindFirstChild("Info")
    if not info then return nil end
    local done=info:FindFirstChild("GeneratorsCompleted")
    local total=info:FindFirstChild("RequiredGenerators")
    if done and total and done:IsA("ValueBase") and total:IsA("ValueBase") then
        return tostring(done.Value).."/"..tostring(total.Value)
    end
    return nil
end
bind(LP.Idled,function()
    if state.antiAFK then
        pcall(function()VirtualUser:CaptureController();VirtualUser:ClickButton2(Vector2.new(0,0))end)
    end
end)
local lastAlert=false
local function refreshInfo()
    local map=currentMap()
    local progress=countMachines()
    local info=workspace:FindFirstChild("Info")
    if state.autoElev and not state.autoPlay and map and lastAutoElevatorMap~=map and info then
        local done=info:FindFirstChild("GeneratorsCompleted")
        local required=info:FindFirstChild("RequiredGenerators")
        if done and required and tonumber(required.Value) and tonumber(done.Value)
            and required.Value>0 and done.Value>=required.Value then
            lastAutoElevatorMap=map
            task.defer(function()if live and state.autoElev then walkToward("elevator")end end)
        end
    end
    local monster,dist=nearest("monsters")
    local text=(map and ("Maquinas "..(progress or "?").."  |  ") or "Lobby / carregando andar  |  ")
    if monster then text=text.."Twisted "..math.floor(dist).." studs"
    else text=text.."Sem Twisted encontrado" end
    if (state.danger or state.autoPlay) and monster and dist<DANGER_RANGE then
        status.TextColor3=C.danger
        status.Text="PERIGO! "..text
        if not lastAlert then say("Cuidado: um Twisted se aproximou!") end
        lastAlert=true
    else
        status.TextColor3=C.mute
        status.Text=text
        lastAlert=false
    end
end

task.spawn(function()
    while live do
        pcall(refreshInfo)
        pcall(refreshMarkers)
        task.wait(1.5)
    end
end)
task.spawn(function()
    while live do
        -- Manter o Speed nao obriga o jogador a ativar essa opcao.
        if state.speed then
            local h=human()
            if h and h.Health>0 then
                if h~=speedHumanoid then
                    originalSpeed=h.WalkSpeed;speedHumanoid=h
                end
                if h.WalkSpeed~=state.speedValue then h.WalkSpeed=state.speedValue end
            end
        end
        task.wait(.20)
    end
end)
local function cleanup()
    if not live then return end
    state.autoPlay=false
    autoRunId=autoRunId+1
    stopNav()
    setSpeed(false)
    setBright(false)
    live=false
    clearAllMarkers()
    for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
    if gui then gui:Destroy() end
    if _G.DOUBLEXDandyCleanup==cleanup then _G.DOUBLEXDandyCleanup=nil end
end
_G.DOUBLEXDandyCleanup=cleanup
topButton("-",-68,function()main.Visible=false;float.Visible=true end)
topButton("X",-35,cleanup)
bind(float.MouseButton1Click,function()main.Visible=true;float.Visible=false end)
say("Pronto! Nada foi ligado automaticamente.")
print("[DOUBLEX Dandy v11] SkillCheck barra verde 1.0.1 e circular, mantendo navegacao V10. Tudo OFF.")