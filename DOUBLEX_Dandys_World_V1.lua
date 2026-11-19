-- DOUBLEX HUB | Dandy's World v1.0 | Delta Android
-- Script independente do DOUBLEX HUB Universal/BedWars.
-- NENHUM ESP OU AUTOMACAO ATIVA SOZINHA.
-- A estrutura interna do jogo pode mudar. Funcoes sao locais e nao garantem vitoria.

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

if _G.DOUBLEXDandyCleanup then pcall(_G.DOUBLEXDandyCleanup) end
local live = true
local connections, markers = {}, {}
local state = {monsters=false, machines=false, items=false, elevator=false, players=false,
    danger=false, bright=false, antiAFK=false, autoElev=false}
local navSerial = 0
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
    BackgroundTransparency=1,Text="v1.0  •  Delta Mobile  •  Tudo OFF",
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
local function stopNav()
    navSerial=navSerial+1
    local c=LP.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    local root=charRoot()
    if h and root then h:MoveTo(root.Position) end
end
local function walkToward(kind)
    stopNav()
    local serial=navSerial
    local target,d=nearest(kind)
    if not target then say("Nenhum objetivo encontrado. Entre em um andar.");return end
    say("Rota para "..names[kind].." ("..math.floor(d).." studs)")
    task.spawn(function()
        local c=LP.Character
        local h=c and c:FindFirstChildOfClass("Humanoid")
        local root=charRoot()
        local goal=positionOf(target)
        if not h or not root or not goal then say("Personagem indisponivel");return end
        local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
        local ok=pcall(function()path:ComputeAsync(root.Position,goal)end)
        if not live or serial~=navSerial then return end
        if not ok or path.Status~=Enum.PathStatus.Success then
            say("Sem caminho calculado. Tente outro ponto.")
            return
        end
        for _,point in ipairs(path:GetWaypoints()) do
            if not live or serial~=navSerial or h.Health<=0 or not target.Parent then return end
            local monster,dist=nearest("monsters")
            if monster and dist<24 then
                say("Rota interrompida: Twisted muito proximo!")
                h:MoveTo(root.Position)
                return
            end
            if point.Action==Enum.PathWaypointAction.Jump then h.Jump=true end
            h:MoveTo(point.Position)
            local reached=h.MoveToFinished:Wait()
            if not reached then say("Caminho bloqueado. Use PARAR e tente de novo.");return end
        end
        if live and serial==navSerial then say("Destino proximo. Interaja manualmente.") end
    end)
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
heading("NAVEGACAO (SEM TELEPORTE)")
addButton("Caminhar ate maquina mais proxima",function()walkToward("machines")end)
addButton("Caminhar ate o elevador",function()walkToward("elevator")end)
addButton("Ir ao elevador apos ultima maquina",function()
    state.autoElev=not state.autoElev
    if not state.autoElev then lastAutoElevatorMap=nil end
end,"autoElev")
addButton("PARAR caminhada automatica",function()stopNav();say("Caminhada interrompida")end)
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
    if state.autoElev and map and lastAutoElevatorMap~=map and info then
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
    if state.danger and monster and dist<45 then
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
        task.wait(1.8)
    end
end)
local function cleanup()
    if not live then return end
    stopNav()
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
print("[DOUBLEX Dandy v1] Menu pronto. Nenhum recurso ativado por padrao.")
