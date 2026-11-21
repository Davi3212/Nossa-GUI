-- DOUBLEX HUB | Dandy's World v32.0 | Delta Android
-- Script independente do DOUBLEX HUB Universal/BedWars.
-- Nenhum ESP, Speed ou autopiloto e ativado sozinho.
-- A estrutura interna do jogo pode mudar. Funcoes sao locais e nao garantem vitoria.

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

if _G.DOUBLEXDandyCleanup then pcall(_G.DOUBLEXDandyCleanup) end
local live = true
local connections, markers = {}, {}
local state = {monsters=false, machines=false, items=false, elevator=false, players=false,
    danger=false, bright=false, antiAFK=false, autoCollect=false,
    speed=false, speedValue=26, autoSkill=false}
local DANGER_RANGE=65
local originalSpeed, speedHumanoid=nil,nil
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

-- Interface Dandy Compacta: mesmo padrao visual do DOUBLEX HUB Universal V10.
-- Tres abas independentes, pesquisa, minimizacao flutuante e controles mobile.
-- A interface mantem apenas 13 referencias no escopo principal.
local gui, C, main, topButton, status, foot, float, say, heading, addButton, buttonList, scroll, registerSearch
do
    gui = inst("ScreenGui",{
        Name="DOUBLEX_Dandy_GUI",ResetOnSpawn=false,IgnoreGuiInset=true,
        DisplayOrder=35,ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    },PG)
    C={
        bg=Color3.fromRGB(19,19,29),
        card=Color3.fromRGB(30,29,44),
        accent=Color3.fromRGB(25,139,255),
        off=Color3.fromRGB(45,45,61),
        white=Color3.fromRGB(236,231,250),
        mute=Color3.fromRGB(174,168,194),
        green=Color3.fromRGB(80,198,132),
        danger=Color3.fromRGB(240,84,95)
    }
    local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,360)
    local w=math.min(342,math.max(255,vp.X-24))
    local h=math.min(322,math.max(245,vp.Y-34))
    main=inst("Frame",{
        Size=UDim2.fromOffset(w,h),Position=UDim2.new(.5,-w/2,.5,-h/2),
        BackgroundColor3=C.bg,BorderSizePixel=0,Active=true
    },gui)
    round(main,13)
    inst("UIStroke",{Color=C.accent,Thickness=1,Transparency=.1},main)
    local top=inst("Frame",{
        Size=UDim2.new(1,0,0,43),BackgroundColor3=C.card,
        BorderSizePixel=0,Active=true
    },main)
    round(top,13)
    local title=inst("TextLabel",{
        Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-101,1,0),
        BackgroundTransparency=1,Text="DOUBLEX HUB | DANDY V32",
        TextColor3=Color3.fromRGB(84,180,255),Font=Enum.Font.GothamBold,
        TextSize=14,TextXAlignment=Enum.TextXAlignment.Left
    },top)
    topButton=function(text,x,action)
        local b=inst("TextButton",{
            Size=UDim2.fromOffset(31,29),Position=UDim2.new(1,x,0,7),
            BackgroundColor3=text=="X" and Color3.fromRGB(163,52,77)
                or Color3.fromRGB(22,88,172),
            Text=text,TextColor3=C.white,Font=Enum.Font.GothamBold,
            TextSize=17,BorderSizePixel=0
        },top)
        round(b,7)
        bind(b.MouseButton1Click,action)
        return b
    end
    status=inst("TextLabel",{
        Position=UDim2.fromOffset(9,48),Size=UDim2.new(1,-18,0,24),
        BackgroundColor3=C.card,Text="Aguardando partida...",
        TextWrapped=true,Font=Enum.Font.Gotham,TextSize=10,
        TextColor3=C.mute,BorderSizePixel=0
    },main)
    round(status,6)
    local search=inst("TextBox",{
        Position=UDim2.fromOffset(9,78),Size=UDim2.new(1,-18,0,29),
        BackgroundColor3=C.card,Text="",PlaceholderText="Pesquisar funcionalidades...",
        PlaceholderColor3=C.mute,ClearTextOnFocus=false,
        TextColor3=C.white,Font=Enum.Font.Gotham,TextSize=12,
        BorderSizePixel=0
    },main)
    round(search,8)
    local tabs=inst("ScrollingFrame",{
        Position=UDim2.fromOffset(8,113),Size=UDim2.new(1,-16,0,31),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,
        ScrollingDirection=Enum.ScrollingDirection.X,CanvasSize=UDim2.fromOffset(0,0)
    },main)
    local tabLayout=inst("UIListLayout",{
        FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),
        SortOrder=Enum.SortOrder.LayoutOrder
    },tabs)
    bind(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
        tabs.CanvasSize=UDim2.fromOffset(tabLayout.AbsoluteContentSize.X+5,0)
    end)
    local tabPages={}
    local tabButtons={}
    local categoryNames={
        {id="ESP",label="ESP"},
        {id="SOBREVIVENCIA",label="Sobrevivência + Speed"},
        {id="VERIFICACOES",label="Verificações + Minijogos"}
    }
    for _,cat in ipairs(categoryNames) do
        local b=inst("TextButton",{
            Size=UDim2.fromOffset(cat.id=="ESP" and 56 or
                (cat.id=="SOBREVIVENCIA" and 150 or 179),29),
            BackgroundColor3=C.card,Text=cat.label,
            TextColor3=C.white,Font=Enum.Font.GothamBold,
            TextSize=11,BorderSizePixel=0
        },tabs)
        round(b,7)
        tabButtons[cat.id]=b
        local page=inst("ScrollingFrame",{
            Name="Aba_"..cat.id,
            Position=UDim2.fromOffset(9,150),Size=UDim2.new(1,-18,1,-181),
            BackgroundTransparency=1,BorderSizePixel=0,
            ScrollBarThickness=3,ScrollBarImageColor3=C.accent,
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            CanvasSize=UDim2.fromOffset(0,0),Visible=false
        },main)
        inst("UIListLayout",{
            Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder
        },page)
        inst("UIPadding",{PaddingBottom=UDim.new(0,4)},page)
        tabPages[cat.id]=page
    end
    foot=inst("TextLabel",{
        Position=UDim2.new(0,9,1,-27),Size=UDim2.new(1,-18,0,23),
        BackgroundColor3=C.card,BorderSizePixel=0,
        Text="Tudo OFF ao iniciar  |  X fecha o hub",
        TextWrapped=true,TextColor3=C.mute,Font=Enum.Font.Gotham,
        TextSize=10
    },main)
    round(foot,7)
    float=inst("TextButton",{
        Name="DOUBLEX_Bubble",Size=UDim2.fromOffset(52,52),
        Position=UDim2.new(0,12,.5,-26),BackgroundColor3=C.accent,
        Text="DX",TextColor3=C.white,Font=Enum.Font.GothamBold,
        TextSize=18,Visible=false,BorderSizePixel=0,Active=true
    },gui)
    round(float,26)
    inst("UIStroke",{Color=Color3.fromRGB(65,185,255),Thickness=1},float)
    local function drag(handle,target)
        local moving,started,origin=false,nil,nil
        bind(handle.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.Touch or
                input.UserInputType==Enum.UserInputType.MouseButton1 then
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
            if moving and
                (input.UserInputType==Enum.UserInputType.MouseMovement or
                 input.UserInputType==Enum.UserInputType.Touch) and
                 started and origin then
                local d=input.Position-started
                target.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,
                    origin.Y.Scale,origin.Y.Offset+d.Y)
            end
        end)
    end
    drag(top,main)
    drag(float,float)
    say=function(msg)
        if live then foot.Text=msg end
    end
    buttonList={}
    local activeCategory="ESP"
    scroll=tabPages.ESP
    local searchRows={}
    registerSearch=function(obj,label,category)
        table.insert(searchRows,{obj=obj,label=string.lower(label),
            category=category or activeCategory})
    end
    local function applySearch()
        local query=string.lower(tostring(search.Text or ""))
        for _,rec in ipairs(searchRows) do
            rec.obj.Visible=(query=="" or rec.label:find(query,1,true)~=nil)
        end
    end
    local function showTab(category)
        activeCategory=category
        for id,page in pairs(tabPages) do
            page.Visible=(id==category)
            tabButtons[id].BackgroundColor3=id==category and C.accent or C.card
        end
        search.Text=""
        applySearch()
    end
    for _,cat in ipairs(categoryNames) do
        local id=cat.id
        bind(tabButtons[id].MouseButton1Click,function()showTab(id)end)
    end
    bind(search:GetPropertyChangedSignal("Text"),applySearch)
    showTab("ESP")
    heading=function(text)
        if text=="LOCALIZADOR (ESP)" then
            activeCategory="ESP"
        elseif text=="SOBREVIVENCIA" or text=="VELOCIDADE" then
            activeCategory="SOBREVIVENCIA"
        else
            activeCategory="VERIFICACOES"
        end
        scroll=tabPages[activeCategory]
        local t=inst("TextLabel",{
            Size=UDim2.new(1,-4,0,20),BackgroundTransparency=1,
            Text="  "..text,TextColor3=C.mute,TextSize=11,
            Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left
        },scroll)
        registerSearch(t,text)
    end
    addButton=function(label,fn,key)
        local b=inst("TextButton",{
            Size=UDim2.new(1,-4,0,34),BackgroundColor3=C.off,
            Text=label,TextColor3=C.white,Font=Enum.Font.GothamMedium,
            TextSize=12,BorderSizePixel=0,TextWrapped=true
        },scroll)
        round(b,8)
        local function redraw()
            if not key then return end
            b.Text=(state[key] and "[ON]  " or "[OFF]  ")..label
            b.BackgroundColor3=state[key] and C.accent or C.off
        end
        redraw()
        registerSearch(b,label)
        bind(b.MouseButton1Click,function()
            if not live then return end
            local ok,err=pcall(fn)
            if not ok then say("Falha: "..tostring(err):sub(1,75)) end
            redraw()
        end)
        if key then buttonList[key]=redraw end
    end
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
-- Apenas os recursos solicitados permanecem nesta edicao.
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

local function machineExtractingUI()
    for _,obj in ipairs(PG:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("TextLabel")) then
            local t=tostring(obj.Text or ""):lower()
            if t:find("stop extracting",1,true) or
                t:find("stop extraction",1,true) or
                t:find("parar a extra",1,true) then
                local node=obj
                local visible=true
                while node and node~=PG do
                    if node:IsA("GuiObject") and not node.Visible then
                        visible=false;break
                    end
                    if node:IsA("LayerCollector") and not node.Enabled then
                        visible=false;break
                    end
                    node=node.Parent
                end
                if visible and node==PG then return true end
            end
        end
    end
    return false
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
addButton("Coletor de itens / fitas",function()
    state.autoCollect=not state.autoCollect
    say(state.autoCollect and
        "Coletor ON: fitas, capsulas e itens ao passar perto."
        or "Coletor OFF: coleta automatica interrompida.")
end,"autoCollect")
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
registerSearch(speedBoxRow,"Speed velocidade 16 a 120")
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


do
    -- COLETOR PASSIVO V32 - SO QUANDO O JOGADOR PASSA POR PERTO.
    -- Nunca teleporta, nunca move o jogador e nao dispara remotes desconhecidos.
    -- Tenta a interacao normal de itens que estao na sala atual.
    local collectCooldown=setmetatable({},{__mode="k"})
    local collectAttempts=0
    local collectLastMode="aguardando"
    local COLLECT_SCAN_INTERVAL=.22
    local COLLECT_RANGE=4.35

    local function collectItemCandidates()
        local map=currentMap()
        if not map then return {} end
        local results={}
        local seen={}
        local function add(entry)
            if entry and not seen[entry] and
                (entry:IsA("BasePart") or entry:IsA("Model")) then
                seen[entry]=true
                table.insert(results,entry)
            end
        end
        for _,obj in ipairs(getObjects("items")) do add(obj) end
        -- Alguns eventos colocam suas moedas em pastas especificas.
        for _,folderName in ipairs({"Collectibles","EventItems","Pickups","Currency","Currencies"}) do
            local folder=map:FindFirstChild(folderName)
            if folder then
                for _,obj in ipairs(folder:GetChildren()) do
                    local name=obj.Name:lower()
                    if name:find("tape",1,true) or
                        name:find("capsule",1,true) or
                        name:find("currency",1,true) or
                        name:find("basket",1,true) or
                        name:find("ornament",1,true) or
                        name:find("pumpkin",1,true) or
                        name:find("collect",1,true) then
                        add(obj)
                    end
                end
            end
        end
        return results
    end
    local function collectFocus(item)
        -- Distancia medida do ponto interativo se houver prompt.
        for _,o in ipairs(item:GetDescendants()) do
            if o:IsA("ProximityPrompt") and o.Enabled then
                local parent=o.Parent
                local pos=(parent and parent:IsA("Attachment") and parent.WorldPosition)
                    or (parent and parent:IsA("BasePart") and parent.Position)
                if pos then return pos,o end
            end
        end
        return positionOf(item),nil
    end
    local function collectVisible(root,item,point)
        if not root or not item or not point then return false end
        if math.abs(root.Position.Y-point.Y)>6.5 then return false end
        local delta=point-(root.Position+Vector3.new(0,1,0))
        if delta.Magnitude<.35 then return true end
        local p=RaycastParams.new()
        p.FilterType=Enum.RaycastFilterType.Exclude
        p.FilterDescendantsInstances=LP.Character and {LP.Character} or {}
        local hit=workspace:Raycast(root.Position+Vector3.new(0,1,0),delta,p)
        return not hit or hit.Instance==item or hit.Instance:IsDescendantOf(item)
    end
    local function collectNearMachine(root)
        -- Impede que um E generico comece/cancele extracao em vez de pegar o item.
        for _,machine in ipairs(getObjects("machines")) do
            local pos=positionOf(machine)
            if pos and (pos-root.Position).Magnitude<4.2 then return true end
        end
        return false
    end
    local function pressCollectE()
        if type(keypress)=="function" and type(keyrelease)=="function" then
            local ok=pcall(function()
                keypress(0x45)
                task.delay(.12,function()
                    pcall(function()keyrelease(0x45)end)
                end)
            end)
            if ok then return true,"tecla E" end
        end
        local vim
        pcall(function()vim=game:GetService("VirtualInputManager")end)
        if vim then
            local ok=pcall(function()
                vim:SendKeyEvent(true,Enum.KeyCode.E,false,game)
                task.delay(.12,function()
                    pcall(function()vim:SendKeyEvent(false,Enum.KeyCode.E,false,game)end)
                end)
            end)
            if ok then return true,"E mobile" end
        end
        return false,"interacao E indisponivel"
    end
    local function collectTry(item,root,point,prompt)
        if not item.Parent or not state.autoCollect or not live then return false,"desligado" end
        if prompt and prompt.Enabled then
            local limit=math.min(6,math.max(2.0,prompt.MaxActivationDistance+.15))
            if (root.Position-point).Magnitude<=limit then
                if type(fireproximityprompt)=="function" then
                    local ok=pcall(function()fireproximityprompt(prompt)end)
                    if ok then return true,"prompt" end
                end
                -- Fallback nativo para prompts sem a funcao do executor.
                local ok=pcall(function()
                    prompt:InputHoldBegin()
                    task.delay(math.max(.10,prompt.HoldDuration+.05),function()
                        pcall(function()prompt:InputHoldEnd()end)
                    end)
                end)
                if ok then return true,"hold prompt" end
            end
            return false,"fora do prompt"
        end
        -- O item pode utilizar colisao ou um ClickDetector para coleta.
        for _,desc in ipairs(item:GetDescendants()) do
            if desc:IsA("ClickDetector") and
                type(fireclickdetector)=="function" then
                local ok=pcall(function()fireclickdetector(desc)end)
                if ok then return true,"click detector" end
            elseif desc:IsA("TouchTransmitter") and
                type(firetouchinterest)=="function" then
                local part=desc.Parent
                if part and part:IsA("BasePart") and
                    (root.Position-part.Position).Magnitude<=4 then
                    local ok=pcall(function()
                        firetouchinterest(root,part,0)
                        firetouchinterest(root,part,1)
                    end)
                    if ok then return true,"toque" end
                end
            end
        end
        -- Sem prompt especifico, so usa E MUITO PERTO e longe das maquinas.
        if (root.Position-point).Magnitude<=3.1 and
            not collectNearMachine(root) then
            return pressCollectE()
        end
        return false,"aguardando aproximacao"
    end
    task.spawn(function()
        while live do
            if state.autoCollect then
                local root=charRoot()
                local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health>0 and not machineExtractingUI() then
                    local now=os.clock()
                    local chosen,chosenPoint,chosenPrompt,nearestDist=nil,nil,nil,math.huge
                    for _,item in ipairs(collectItemCandidates()) do
                        local point,prompt=collectFocus(item)
                        if point then
                            local distance=(root.Position-point).Magnitude
                            if distance<nearestDist and distance<COLLECT_RANGE and
                                now-(collectCooldown[item] or -100)>1.1 and
                                collectVisible(root,item,point) then
                                chosen,chosenPoint,chosenPrompt,nearestDist=
                                    item,point,prompt,distance
                            end
                        end
                    end
                    if chosen then
                        collectCooldown[chosen]=now
                        local ok,how=collectTry(chosen,root,chosenPoint,chosenPrompt)
                        if ok then
                            collectAttempts=collectAttempts+1
                            collectLastMode=how
                        end
                    end
                end
                task.wait(COLLECT_SCAN_INTERVAL)
            else
                task.wait(.6)
            end
        end
    end)

end

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

-- V12: detector circular restrito a PlayerGui.Skillchecks.
local circleSizes=setmetatable({},{__mode="k"})
local circleScanAt=0
local circleInfo=nil
local circleLastWidth=nil
local circleLastAt=nil
local circleArmed=true
local circleActive=false
local circleReason=""
local circleLastEvent="nenhuma verificacao circular observada"
local circleLastPrompt="nenhum"
local circleLastSnapAt=0
local circleTapMethod="nenhum"
local circlePressCount=0
local function isRingRed(c)
    return c and c.R>.49 and c.R>c.G*1.43 and c.R>c.B*1.42
end
local function isRingGold(c)
    return c and c.R>.6 and c.G>.36 and c.R>c.B*1.2
end
local function ringColors(o)
    local colors={}
    if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.ImageTransparency<.9 then
        table.insert(colors,o.ImageColor3)
    end
    if o.BackgroundTransparency<.9 then table.insert(colors,o.BackgroundColor3) end
    for _,ch in ipairs(o:GetChildren()) do
        if ch:IsA("UIStroke") and ch.Enabled and ch.Transparency<.9 then
            table.insert(colors,ch.Color)
        end
    end
    return colors
end
local function circleScreen()
    local screen=PG:FindFirstChild("Skillchecks")
    if not screen or not screen:IsA("ScreenGui") or not screen.Enabled then
        return nil,"ScreenGui Skillchecks indisponivel"
    end
    return screen,nil
end
local function circleScope(screen)
    for _,name in ipairs({"Circular","Circle","Radial","Ring","Round"}) do
        local obj=screen:FindFirstChild(name,true)
        if obj and obj:IsA("GuiObject") and visibleGui(obj)
            and obj.AbsoluteSize.X>=70 and obj.AbsoluteSize.Y>=70 then
            return obj
        end
    end
    for _,obj in ipairs(screen:GetDescendants()) do
        if obj:IsA("GuiObject") and visibleGui(obj)
            and (obj.Name:lower():find("circle") or
                 obj.Name:lower():find("ring") or
                 obj.Name:lower():find("radial")) and
            obj.AbsoluteSize.X>=75 and obj.AbsoluteSize.Y>=75 then
            return obj
        end
    end
    return screen
end
-- V23: os aneis NAO estao em PlayerGui.Skillchecks no diagnostico real.
-- Eles podem ser outra ScreenGui ou um BillboardGui 3D junto a maquina.
local circleWorldCache={}
local circleWorldCacheAt=0
local function circleVisibleAny(obj)
    if not obj or not obj:IsA("GuiObject") or not obj.Visible then
        return false
    end
    local node=obj.Parent
    local layerFound=false
    while node do
        if node:IsA("GuiObject") and not node.Visible then return false end
        if node:IsA("LayerCollector") then
            if not node.Enabled then return false end
            layerFound=true
        end
        if node==PG or node==workspace or node==game:GetService("CoreGui") then
            return layerFound
        end
        node=node.Parent
    end
    return false
end

local function circleRecord(obj,now)
    if not obj:IsA("GuiObject") or not circleVisibleAny(obj) then return nil end
    local p,z=obj.AbsolutePosition,obj.AbsoluteSize
    if z.X<35 or z.Y<35 or z.X>650 or z.Y>650 or z.Y<1 or
        z.X/z.Y<.7 or z.X/z.Y>1.35 then return nil end
    local name=obj.Name:lower()
    local red,gold=0,0
    for _,color in ipairs(ringColors(obj)) do
        if isRingRed(color) then red=math.max(red,7) end
        if isRingGold(color) then gold=math.max(gold,7) end
    end
    if name:find("red") or name:find("shrink") or
        name:find("moving") or name:find("cursor") then red=math.max(red,6) end
    if name:find("gold") or name:find("yellow") or
        name:find("perfect") then gold=math.max(gold,7)
    elseif name:find("target") or name:find("required") or
        name:find("gray") or name:find("grey") or
        name:find("zone") then gold=math.max(gold,4) end
    local previous=circleSizes[obj]
    local shrinking=false
    if previous and now-previous.t<.40 then
        local change=previous.w-z.X
        if change>.24 and change<math.max(65,z.X*.45) then
            shrinking=true
            red=math.max(red,12)
        end
    end
    circleSizes[obj]={w=z.X,t=now}
    return {obj=obj,red=red,gold=gold,width=z.X,
        cx=p.X+z.X*.5,cy=p.Y+z.Y*.5,shrinking=shrinking}
end
local function circleCandidates()
    local screen,reason=circleScreen()
    if not screen then return nil,nil,nil,reason end
    local scope=circleScope(screen)
    local now=os.clock()
    local records={}
    local seen={}
    local function put(obj)
        if #records>=550 or seen[obj] then return end
        seen[obj]=true
        local rec=circleRecord(obj,now)
        if rec then table.insert(records,rec) end
    end
    if scope~=screen then put(scope) end
    for _,o in ipairs(scope:GetDescendants()) do put(o) end
    -- Scan adicional: interfaces de jogo FORA de Skillchecks.
    -- Ignora HUD, TouchGui, chat e o proprio DOUBLEX.
    for _,root in ipairs(PG:GetChildren()) do
        if root:IsA("LayerCollector") and root.Enabled and
            root~=screen and root~=gui and
            root.Name~="HUD" and root.Name~="TouchGui" and
            root.Name~="Chat" and root.Name~="BubbleChat" then
            for _,o in ipairs(root:GetDescendants()) do
                put(o)
                if #records>=550 then break end
            end
        end
    end
    -- GUI pode estar em modelos de outras pastas (nao apenas CurrentRoom).
    -- Armazena em cache e consulta no maximo a cada 3s no cliente.
    if now-circleWorldCacheAt>3 then
        circleWorldCacheAt=now
        circleWorldCache={}
        local added=0
        -- A verificacao ativa e um caso raro: uma pesquisa inteira na sala.
        for _,root in ipairs(workspace:GetDescendants()) do
            if (root:IsA("BillboardGui") or root:IsA("SurfaceGui"))
                and root.Enabled then
                table.insert(circleWorldCache,root)
                added=added+1
                if added>=180 then break end
            end
        end
    end
    -- Contribuem para os candidatos inclusive se outro HUD lotou o scan.
    for _,root in ipairs(circleWorldCache) do
        if root.Parent and root.Enabled then
            for _,o in ipairs(root:GetDescendants()) do
                put(o)
                if #records>=550 then break end
            end
        end
    end
    -- Alguns jogos alojam interfaces dinamicas em CoreGui.
    local core=game:GetService("CoreGui")
    for _,root in ipairs(core:GetChildren()) do
        if root:IsA("LayerCollector") and root.Enabled and
            not root.Name:lower():find("roblox") and
            not root.Name:lower():find("delta") and
            not root.Name:lower():find("doublex") then
            for _,o in ipairs(root:GetDescendants()) do
                put(o)
                if #records>=550 then break end
            end
        end
    end
    return screen,scope,records,nil
end
-- Reconhece o minijogo circular pelo texto mostrado na propria tela.
-- Nao confunde barra horizontal, nado e outras imagens vermelhas do HUD.
local cachedCircleState=false
local cachedCircleChecked=0
local function isCirclePresented()
    local screen=circleScreen()
    if not screen then
        cachedCircleState=false
        return false
    end
    local shared=screen:FindFirstChild("Shared")
    local prompt=shared and shared:FindFirstChild("Prompt")
    -- A instrucao principal e examinada a cada frame, sem scans pesados.
    local t=prompt and visibleGui(prompt) and skillText(prompt) or ""
    local isCircle=t:find("círculo",1,true) or
        t:find("circulo",1,true) or t:find("circle",1,true) or
        t:find("ring",1,true) or t:find("anel",1,true)
    if isCircle then
        cachedCircleState=true
        circleLastPrompt=t
        return true
    end
    -- Se o texto migrar para ClientUI, so pesquisa a cada 0.35 s.
    local now=os.clock()
    if now-cachedCircleChecked<.35 then return cachedCircleState end
    cachedCircleChecked=now
    cachedCircleState=false
    local client=PG:FindFirstChild("ClientUI")
    if not client then return false end
    for _,obj in ipairs(client:GetDescendants()) do
        if obj:IsA("TextLabel") and visibleGui(obj) then
            local content=skillText(obj)
            if content:find("círculo",1,true) or
                content:find("circulo",1,true) or
                content:find("circle",1,true) or
                content:find("ring",1,true) or
                content:find("anel",1,true) then
                cachedCircleState=true
                circleLastPrompt=content
                return true
            end
        end
    end
    return false
end
local function findCircleElements()
    local screen,scope,records,reason=circleCandidates()
    if not screen then return nil,reason end
    if not isCirclePresented() then return nil,"prompt circular inativo" end
    -- Registra o que aconteceu DURANTE o circulo; na tela de resultado,
    -- o prompt ja esta oculto e um diagnostico ao vivo perderia tudo.
    if os.clock()-circleLastSnapAt>.28 then
        circleLastSnapAt=os.clock()
        local report={"CIRCULO ATIVO: "..tostring(circleLastPrompt),
            "candidatos="..tostring(#records)}
        local count=0
        for _,r in ipairs(records) do
            if count>=100 then break end
            if r.red>0 or r.gold>0 or r.shrinking then
                count=count+1
                table.insert(report,string.format(
                    "%s [red=%d gold=%d shr=%s width=%.1f] ",
                    r.obj:GetFullName(),r.red,r.gold,
                    tostring(r.shrinking),r.width))
            end
        end
        if count==0 then
            table.insert(report,"Nenhum anel com cor/nome/movimento identificavel")
            for _,r in ipairs(records) do
                if count>=40 then break end
                count=count+1
                table.insert(report,r.obj:GetFullName()..
                    " W="..tostring(r.width))
            end
        end
        circleLastEvent=table.concat(report,"\n")
    end
    local shared=screen:FindFirstChild("Shared")
    local button=nil
    -- Nunca escolher um TapButton oculto do Horizontal por acidente.
    local candidates={}
    if scope~=screen then
        local scoped=scope:FindFirstChild("TapButton",true)
        if scoped then table.insert(candidates,scoped) end
    end
    local sharedButton=shared and shared:FindFirstChild("TapButton")
    if sharedButton then table.insert(candidates,sharedButton) end
    for _,o in ipairs(screen:GetDescendants()) do
        if o.Name=="TapButton" and o:IsA("GuiButton") then
            table.insert(candidates,o)
        end
    end
    for _,candidate in ipairs(candidates) do
        if candidate:IsA("GuiButton") and visibleGui(candidate) then
            button=candidate
            break
        end
    end
    if not button then
        return nil,"TapButton real e visivel nao localizado"
    end
    local best,bestScore=nil,-math.huge
    for _,r in ipairs(records) do
        if r.red>0 then
            for _,g in ipairs(records) do
                if g.obj~=r.obj and (g.gold>0 or
                    (r.shrinking and g.width>=35 and
                    g.width<=r.width*1.12 and g.width>=r.width*.64)) and
                    g.width>=35 and g.width<=340 and
                    math.abs(r.cx-g.cx)<math.max(26,g.width*.2) and
                    math.abs(r.cy-g.cy)<math.max(26,g.width*.2) and
                    r.width>=g.width*.72 and r.width<g.width*4.2 then
                    local n=g.obj.Name:lower()
                    local namedGold=n:find("gold") or n:find("yellow")
                        or n:find("perfect")
                    local movingRedBonus=r.shrinking and 150 or 0
                    local score=r.red*5+g.gold*5+
                        movingRedBonus+
                        (namedGold and 85 or 0)-
                        (g.gold==0 and 70 or 0)-
                        (g.shrinking and 65 or 0)-
                        math.abs(r.width-g.width)*.012
                    if score>bestScore then
                        best,bestScore={red=r.obj,gold=g.obj,button=button},score
                    end
                end
            end
        end
    end
    if best then return best,nil end
    return nil,"aneis sem par vermelho/alvo"
end

local skillInfo=nil
local lastSkillScan=0
local skillNeedleLastX=nil
local skillNeedleLastAt=nil
local skillPressedAt=0
local skillStatusAt=0
local skillArmed=true
-- Prioriza o botao GUI verdadeiro, nao o texto de instrucao.
local function clickRealSkillButton(btn,preferSpace)
    if not btn or not btn:IsA("GuiButton") or not visibleGui(btn) then
        return false
    end
    local x=btn.AbsolutePosition.X+btn.AbsoluteSize.X*.5
    local y=btn.AbsolutePosition.Y+btn.AbsoluteSize.Y*.5
    local vim
    pcall(function()vim=game:GetService("VirtualInputManager")end)
    if vim then
        local ok=pcall(function()
            vim:SendMouseButtonEvent(x,y,0,true,game,0)
            vim:SendMouseButtonEvent(x,y,0,false,game,0)
        end)
        if ok then circleTapMethod="toque";return true end
    end
    if type(firesignal)=="function" then
        local ok=pcall(function()firesignal(btn.Activated)end)
        if ok then circleTapMethod="activated";return true end
        ok=pcall(function()firesignal(btn.MouseButton1Click)end)
        if ok then circleTapMethod="click";return true end
    end
    if vim then
        local ok=pcall(function()
            vim:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
            vim:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
        end)
        if ok then circleTapMethod="space";return true end
    end
    if type(keypress)=="function" and type(keyrelease)=="function" then
        local ok=pcall(function()keypress(0x20);keyrelease(0x20)end)
        if ok then circleTapMethod="tecla";return true end
    end
    circleTapMethod="falhou"
    return false
end

-- V25: comando de teclado exigido pela interface mostrada pelo jogador.
-- A V24 emitia evento de mouse, mudava o cursor do Delta e podia
-- retornar true sem o jogo realmente aceitar o input.
local circleV25={sent=0,last="nenhum",autoSent=0}
local function sendCircleSpace()
    local did=false
    if type(keypress)=="function" and type(keyrelease)=="function" then
        local ok=pcall(function()
            keypress(0x20)
            task.delay(.024,function()pcall(function()keyrelease(0x20)end)end)
        end)
        if ok then
            did=true
            circleTapMethod="keypress SPACE"
        end
    end
    if not did then
        local vim
        pcall(function()vim=game:GetService("VirtualInputManager")end)
        if vim then
            local ok=pcall(function()
                vim:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
                task.delay(.024,function()
                    pcall(function()
                        vim:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
                    end)
                end)
            end)
            if ok then
                did=true
                circleTapMethod="VirtualInputManager SPACE"
            end
        end
    end
    circleV25.last=did and circleTapMethod or "Space nao enviado"
    if did then circleV25.sent=circleV25.sent+1 end
    return did
end

-- V25 circular: SPACE no instante de sobreposicao dos aneis; SEM mouse.
bind(RunService.RenderStepped,function()
    if not live or not state.autoSkill then
        circleInfo=nil;circleLastWidth=nil;circleLastAt=nil
        circleArmed=true;circleActive=false
        return
    end
    local now=os.clock()
    if not isCirclePresented() then
        circleInfo=nil;circleLastWidth=nil;circleLastAt=nil
        circleArmed=true;circleActive=false
        return
    end
    circleActive=true
    local valid=circleInfo and circleInfo.red.Parent and circleInfo.gold.Parent
        and circleInfo.button.Parent and visibleGui(circleInfo.red)
        and visibleGui(circleInfo.gold) and visibleGui(circleInfo.button)
    if not valid then
        circleInfo=nil;circleLastWidth=nil;circleLastAt=nil
    end
    -- Busca periodicamente o anel realmente animado. A V17 podia fixar
    -- um circulo decorativo e nunca chegar a enviar o clique.
    if now-circleScanAt>.11 then
        local found,reason=findCircleElements()
        if found then
            if not circleInfo or circleInfo.red~=found.red then
                circleLastWidth=nil
                circleLastAt=nil
            end
            circleInfo=found
        end
        circleReason=reason or "aneis detectados"
        circleScanAt=now
    end
    if not circleInfo then return end
    local rw=circleInfo.red.AbsoluteSize.X
    local gw=circleInfo.gold.AbsoluteSize.X
    if rw<1 or gw<1 then return end
    if circleLastWidth and circleLastAt then
        local dt=now-circleLastAt
        local shrinkSpeed=(dt>.003 and dt<.25) and
            (circleLastWidth-rw)/dt or 0
        local shrinking=shrinkSpeed>1.5
        local diff=rw-gw
        local predicted=rw-shrinkSpeed*.026
        local tolerance=math.max(9,gw*.16)
        -- Melhor acertar o aro amarelo ao passar pelo seu diametro.
        -- O valor previsto leva em conta o atraso aproximado do toque.
        local nowInZone=math.abs(diff)<=tolerance
        local aboutToEnter=shrinking and
            math.abs(predicted-gw)<=tolerance*1.2 and
            diff<math.max(38,gw*.42)
        if circleArmed and shrinking and (nowInZone or aboutToEnter)
            and now-skillPressedAt>.65 then
            local ok=sendCircleSpace()
            if ok then
                circleArmed=false
                skillPressedAt=now
                circlePressCount=circlePressCount+1
                circleV25.autoSent=circleV25.autoSent+1
            end
            if now-skillStatusAt>1 then
                say(ok and "V25 circular: ESPACO enviado na zona."
                    or "V25 circular: ESPACO indisponivel no Delta.")
                skillStatusAt=now
            end
        end
        if not circleArmed and now-skillPressedAt>.55 and
            (rw>gw*1.75 or circleLastWidth-rw<-.8) then
            circleArmed=true
        end
    end
    circleLastWidth=rw
    circleLastAt=now
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
    if circleActive or isCirclePresented() then return end
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

local function skillDiagnostic(onlyReport)
    local rows={"DOUBLEX DANDY V32 - SKILLCHECK",
        "Circular/Horizontal - diagnostico da arvore Skillchecks",""}
    local bar,barReason=findSkillElements()
    local circle,circleWhy=findCircleElements()
    table.insert(rows,"Horizontal: "..(bar and "detectado" or tostring(barReason)))
    table.insert(rows,"Circular: "..(circle and "detectado" or tostring(circleWhy)))
    table.insert(rows,"Clique circular: "..circleTapMethod)
    table.insert(rows,"V25 - Espaco auto: "..circleV25.autoSent)
    table.insert(rows,"V25 - Comandos enviados: "..circleV25.sent)
    table.insert(rows,"V25 - Metodo/ultimo: "..circleV25.last)
    table.insert(rows,"V25 - Resultado do comando: nao confirma acerto do jogo")
    table.insert(rows,"Toques circulares enviados: "..tostring(circlePressCount))
    table.insert(rows,"Estado circulo: "..tostring(circleReason))
    table.insert(rows,"Circular ativo (prompt): "..tostring(isCirclePresented()))
    table.insert(rows,"ULTIMO CIRCULO ATIVO (capturado automaticamente):")
    table.insert(rows,circleLastEvent)
    table.insert(rows,"Ultima instrucao: "..circleLastPrompt)
    table.insert(rows,"Armed: "..tostring(circleArmed)..
        " | Ultimo aro="..tostring(circleLastWidth)..
        " | Ultimo clique="..tostring(circlePressCount))
    table.insert(rows,"Modo ativo: "..tostring(isCirclePresented()))
    table.insert(rows,"ELEMENTOS VISUAIS CIRCULARES / TEXTURAS:")
    local sc=PG:FindFirstChild("Skillchecks")
    if sc then
        local count=0
        for _,obj in ipairs(sc:GetDescendants()) do
            if count>=70 then break end
            if obj:IsA("GuiObject") and visibleGui(obj) then
                local z=obj.AbsoluteSize
                if z.X>=24 and z.Y>=24 and z.X/z.Y>.7 and z.X/z.Y<1.35 then
                    count=count+1
                    local desc=obj:GetFullName():gsub(
                        "^.-%.PlayerGui%.","PlayerGui.")
                    desc=desc..string.format(" [%s] W%.0f H%.0f",
                        obj.ClassName,z.X,z.Y)
                    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                        desc=desc.." Image="..tostring(obj.Image):sub(1,55)
                        desc=desc.." Rect="..tostring(obj.ImageRectOffset)..
                            "/"..tostring(obj.ImageRectSize)
                    end
                    for _,child in ipairs(obj:GetChildren()) do
                        if child:IsA("UIScale") then
                            desc=desc.." Scale="..tostring(child.Scale)
                        elseif child:IsA("UIGradient") then
                            desc=desc.." Grad="..tostring(child.Offset)..
                                "/"..tostring(child.Rotation)
                        end
                    end
                    table.insert(rows,desc)
                end
            end
        end
    end
    -- Busca por aneis fora da arvore Skillchecks. Nomes e caminhos
    -- concretos permitem proxima correcao sem adivinhar a interface.
    table.insert(rows,"=== V23: OUTRAS INTERFACES DO JOGADOR ===")
    local added=0
    for _,root in ipairs(PG:GetChildren()) do
        if root:IsA("LayerCollector") and root.Enabled and
            root~=gui and root.Name~="Skillchecks" and
            root.Name~="HUD" and root.Name~="TouchGui" and
            root.Name~="Chat" then
            table.insert(rows,"UI RAIZ: "..root:GetFullName())
            for _,o in ipairs(root:GetDescendants()) do
                if added>=110 then break end
                if o:IsA("GuiObject") and circleVisibleAny(o) then
                    local z,p=o.AbsoluteSize,o.AbsolutePosition
                    if z.X>=26 and z.Y>=26 and z.X<=600 and z.Y<=600
                        and z.X/z.Y>.68 and z.X/z.Y<1.4 then
                        added=added+1
                        local colors=ringColors(o)
                        local rgb=#colors>0 and tostring(colors[1]) or "-"
                        local data=string.format(
                            "%s [%s] X%.0f Y%.0f W%.0f H%.0f Color=%s",
                            o:GetFullName():gsub("^.-%.PlayerGui%.","PlayerGui."),
                            o.ClassName,p.X,p.Y,z.X,z.Y,rgb)
                        if o:IsA("ImageLabel") or o:IsA("ImageButton") then
                            data=data.." Img="..tostring(o.Image):sub(1,80)
                        end
                        for _,child in ipairs(o:GetChildren()) do
                            if child:IsA("UIStroke") then
                                data=data.." Stroke="..tostring(child.Color)
                            elseif child:IsA("UIScale") then
                                data=data.." Scale="..tostring(child.Scale)
                            end
                        end
                        table.insert(rows,data)
                    end
                end
            end
        end
    end
    table.insert(rows,"=== V23: BILLBOARD/SURFACE GUI DA SALA ===")
    local room=workspace
    if room then
        local count=0
        for _,o in ipairs(room:GetDescendants()) do
            if count>=90 then break end
            if (o:IsA("BillboardGui") or o:IsA("SurfaceGui")) and
                o.Enabled then
                count=count+1
                table.insert(rows,"WORLD GUI: "..o:GetFullName())
                for _,part in ipairs(o:GetDescendants()) do
                    if count>=90 then break end
                    if part:IsA("GuiObject") then
                        count=count+1
                        local z=part.AbsoluteSize
                        local data=part:GetFullName().." ["..part.ClassName..
                            "] "..tostring(z).." VIS="..tostring(circleVisibleAny(part))
                        if part:IsA("ImageLabel") or part:IsA("ImageButton") then
                            data=data.." Image="..tostring(part.Image):sub(1,70)
                        end
                        table.insert(rows,data)
                    end
                end
            end
        end
    end
    local _,_,potential= circleCandidates()
    table.insert(rows,"=== V23: CANDIDATOS A ANEIS ===")
    for i,rec in ipairs(potential or {}) do
        if i>95 then break end
        if rec.red>0 or rec.gold>0 or rec.shrinking then
            table.insert(rows,
                rec.obj:GetFullName()..
                string.format(" red=%d gold=%d shrink=%s width=%.1f",
                    rec.red,rec.gold,tostring(rec.shrinking),rec.width))
        end
    end
    table.insert(rows,"Prompt: "..tostring((PG:FindFirstChild("Skillchecks") and
        PG.Skillchecks:FindFirstChild("Shared") and
        PG.Skillchecks.Shared:FindFirstChild("Prompt") and
        PG.Skillchecks.Shared.Prompt.Text) or "-"))
    if circleInfo then
        table.insert(rows,"Anel vermelho: "..circleInfo.red:GetFullName()..
            " diametro="..tostring(circleInfo.red.AbsoluteSize.X))
        table.insert(rows,"Alvo: "..circleInfo.gold:GetFullName()..
            " diametro="..tostring(circleInfo.gold.AbsoluteSize.X))
    end
    local screen=PG:FindFirstChild("Skillchecks")
    if screen then
        local count=0
        for _,o in ipairs(screen:GetDescendants()) do
            if count>=160 then break end
            if o:IsA("GuiObject") then
                count=count+1
                local p,z=o.AbsolutePosition,o.AbsoluteSize
                local rgb="-"
                local colors=ringColors(o)
                if #colors>0 then
                    local color=colors[1]
                    rgb=string.format("%d,%d,%d",
                        math.floor(color.R*255),math.floor(color.G*255),
                        math.floor(color.B*255))
                end
                local path=o:GetFullName():gsub("^.-%.PlayerGui%.","PlayerGui.")
                local strokes=""
                for _,child in ipairs(o:GetChildren()) do
                    if child:IsA("UIStroke") then
                        local color=child.Color
                        strokes=strokes..string.format(" stroke=%d,%d,%d",
                            math.floor(color.R*255),math.floor(color.G*255),
                            math.floor(color.B*255))
                    end
                end
                table.insert(rows,string.format(
                    "%s [%s] vis=%s X%d Y%d W%d H%d RGB(%s)%s %s",
                    path,o.ClassName,tostring(visibleGui(o)),
                    math.floor(p.X),math.floor(p.Y),math.floor(z.X),
                    math.floor(z.Y),rgb,strokes,skillText(o):sub(1,50)))
            end
        end
    else
        table.insert(rows,"Skillchecks nao encontrado")
    end
    local report=table.concat(rows,"\n")
    if onlyReport then return report end
    if type(setclipboard)=="function" then
        local ok=pcall(function()setclipboard(report)end)
        say(ok and "Diagnostico V25 copiado. Envie aqui."
            or "Veja diagnostico no console Delta.")
    else
        say("Diagnostico V12 no console Delta.")
    end
    print(report)
end
heading("VERIFICACOES / SKILLCHECK")
addButton("Auto SkillCheck",function()
    state.autoSkill=not state.autoSkill
    skillInfo=nil
    skillNeedleLastX=nil
    skillNeedleLastAt=nil
    skillArmed=true
    circleInfo=nil
    circleArmed=true
    circleActive=false
    say(state.autoSkill and "Auto SkillCheck ON: linha, circulo, esteira e natacao."
        or "Auto SkillCheck OFF: todas as verificacoes paradas.")
end,"autoSkill")
-- Verificacoes reunidas no Auto SkillCheck (inclui minijogos).
-- TREADMILL (gota azul): pede 4 a 8 cliques, monitora numero atual.
-- SWIMMY BARNABY (nadar): so tenta ajudar se peixe e obstaculos estao
-- representados como elementos separados da interface. Nunca toca no escuro.
local minigameMode="nenhum"
local miniTapCount=0
local miniTapMethod="nenhum"
local miniLastError=""
local miniLastNotice=0
local treadmillSession=nil
local swimLastTap=0
local swimLastTarget=nil

local function miniText(o)
    if o and (o:IsA("TextLabel") or o:IsA("TextButton")) then
        return tostring(o.Text or ""):lower()
    end
    return ""
end
local function getMiniTexts()
    local all={}
    for _,o in ipairs(PG:GetDescendants()) do
        if (o:IsA("TextLabel") or o:IsA("TextButton"))
            and visibleGui(o) and not o:IsDescendantOf(gui) then
            local t=miniText(o)
            if t~="" then table.insert(all,{obj=o,text=t}) end
        end
    end
    return all
end
-- Esteira: comando principal e ESPACO, nao clique no texto/botao.
-- Alguns executores suportam keypress; outros somente VirtualInputManager.
-- Uma chamada bem-sucedida significa ENVIO, nao confirma o acerto do jogo.
local treadInputMethod="nao enviado"
local treadLastObservedCount=0
local function pressTreadmillSpace()
    if type(keypress)=="function" and type(keyrelease)=="function" then
        local ok=pcall(function()
            keypress(0x20)
            task.wait(.018)
            keyrelease(0x20)
        end)
        if ok then treadInputMethod="keypress Space";return true end
    end
    local vim
    pcall(function()vim=game:GetService("VirtualInputManager")end)
    if vim then
        local ok=pcall(function()
            vim:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
            task.wait(.018)
            vim:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
        end)
        if ok then treadInputMethod="VirtualInputManager Space";return true end
    end
    treadInputMethod="Space indisponivel no Delta"
    return false
end

-- V17: procura instrucoes no Skillchecks e contador em outras ScreenGuis.
local function activeTreadmillUI()
    local skill=PG:FindFirstChild("Skillchecks")
    if not skill or not skill:IsA("ScreenGui") or not skill.Enabled then
        return nil,"Skillchecks inativo"
    end
    if isCirclePresented() then return nil,"verificacao circular" end
    local texts=getMiniTexts()
    local prompt=nil
    for _,rec in ipairs(texts) do
        local t=rec.text
        if t:find("esteira",1,true) or t:find("treadmill",1,true) or
            t:find("toque rapidamente",1,true) or
            t:find("tap rapidly",1,true) or t:find("tap quickly",1,true) then
            prompt=rec.obj
            break
        end
    end
    if not prompt then return nil,"instrucao de esteira ausente" end
    local current,required=nil,nil
    local maxScore=-math.huge
    local hud=PG:FindFirstChild("HUD")
    local promptRoot=prompt:FindFirstAncestorOfClass("ScreenGui")
    for _,rec in ipairs(texts) do
        -- Pula HUD: 0/4 MACHINES nao e o contador de 0/6 da esteira.
        if not (hud and rec.obj:IsDescendantOf(hud)) then
            local plain=rec.text:gsub("<[^>]+>","")
            local a,b=plain:match("^%s*(%d+)%s*/%s*(%d+)%s*$")
            if a and b then
                a,b=tonumber(a),tonumber(b)
                if a and b and b>=4 and b<=8 and a<=b then
                    local root=rec.obj:FindFirstAncestorOfClass("ScreenGui")
                    local score=0
                    if root and root.Name=="Skillchecks" then score=score+8 end
                    if root and root.Name=="ClientUI" then score=score+7 end
                    if root==promptRoot then score=score+4 end
                    if rec.obj.Name:lower():find("count") then score=score+3 end
                    if score>maxScore then
                        maxScore,current,required=score,a,b
                    end
                end
            end
        end
    end
    local button=nil
    local shared=skill:FindFirstChild("Shared")
    local candidate=shared and shared:FindFirstChild("TapButton")
    if candidate and candidate:IsA("GuiButton") and visibleGui(candidate) then
        button=candidate
    end
    if not button then
        for _,o in ipairs(skill:GetDescendants()) do
            if o:IsA("GuiButton") and o.Name=="TapButton" and visibleGui(o) then
                button=o
                break
            end
        end
    end
    if not button then return nil,"botao de skillcheck nao visivel" end
    return {button=button,current=current or 0,
        required=required or 8,counterFound=required~=nil},nil
end

-- A interface de nado pode ser um unica imagem/renderizacao. Sem sprite
-- e obstaculos acessiveis separadamente, solicita diagnostico e nao interfere.
-- V14: leitura da janela verdadeira, ClientUI.GameWindow.
-- Skillchecks.Shared.Prompt contem apenas TEXTO sobre o minijogo.
-- O desenho do peixe/algas pertence ao cliente e nao ao Shared.
local function swimWindow()
    local client=PG:FindFirstChild("ClientUI")
    local window=client and client:FindFirstChild("GameWindow",true)
    if not window or not window:IsA("GuiObject") then
        return nil,"ClientUI.GameWindow nao encontrado"
    end
    if not visibleGui(window) then
        return nil,"ClientUI.GameWindow nao visivel"
    end
    return window,nil
end
local function swimSessionActive(window)
    if not window then return false end
    local instruction=window:FindFirstChild("GenInstr",true)
    local text=miniText(instruction)
    local skill=PG:FindFirstChild("Skillchecks")
    local shared=skill and skill:FindFirstChild("Shared")
    local prompt=shared and shared:FindFirstChild("Prompt")
    local generic=miniText(prompt)
    local instructions=text.." "..generic
    if not (instructions:find("swim") or instructions:find("nadar")
        or instructions:find("seaweed") or instructions:find("algas")) then
        return false
    end
    for _,o in ipairs(window:GetDescendants()) do
        if o:IsA("TextLabel") and visibleGui(o) then
            local t=miniText(o)
            if t:find("game over") or t:find("fim do jogo") then
                return false
            end
        end
    end
    return true
end
local function swimNameMatch(name,terms)
    name=tostring(name or ""):lower()
    for _,term in ipairs(terms) do
        if name:find(term,1,true) then return true end
    end
    return false
end
local function swimDescribe(window)
    local totals={gui=0,images=0,viewport=0,parts=0,fish=0,kelp=0}
    for _,o in ipairs(window:GetDescendants()) do
        if o:IsA("GuiObject") then
            totals.gui=totals.gui+1
            if o:IsA("ImageLabel") or o:IsA("ImageButton") then
                totals.images=totals.images+1
            end
            if o:IsA("ViewportFrame") then totals.viewport=totals.viewport+1 end
        end
        if o:IsA("BasePart") then totals.parts=totals.parts+1 end
        if swimNameMatch(o.Name,{"barnaby","fish","swimmy","playerfish"}) then
            totals.fish=totals.fish+1
        end
        if swimNameMatch(o.Name,{"seaweed","alga","kelp","obstacle","pipe"}) then
            totals.kelp=totals.kelp+1
        end
    end
    return totals
end
-- V15: o Swimmy Barnaby usa um ViewportFrame com WorldModel 3D.
-- No diagnostico real, o peixe e WorldModel.Part (Part pai de um sprite 4x4);
-- as algas sao Partes 3D dentro de WorldModel.ObstacleSet.
local swimWorldLastY=nil
local swimWorldLastTime=nil
local swimWorldVelocity=0
local swimWorldGap=nil
local swimWorldFish=nil
local swimWorldStep=0
local swimWorldFailures=0
local swimWorldLastYAtTap=nil
local swimWorldLastPressAt=0
local swimWorldTapStill=0
local swimWorldSession=nil

local function swimScene(window)
    local vp=window and window:FindFirstChild("ViewportFrame",true)
    if not vp or not vp:IsA("ViewportFrame") or not visibleGui(vp) then
        return nil,"ViewportFrame nao carregado/oculto"
    end
    local world=vp:FindFirstChildOfClass("WorldModel")
    if not world then
        world=vp:FindFirstChild("WorldModel")
    end
    if not world or not world:IsA("WorldModel") then
        return nil,"WorldModel 3D nao encontrado"
    end
    local obstacles=world:FindFirstChild("ObstacleSet")
    if not obstacles then
        return nil,"ObstacleSet 3D nao encontrado"
    end
    local fish=nil
    local spriteSize=3.5
    -- Procura Part pequena diretamente no WorldModel e um filho Part
    -- retangular, mesmo que ambos se chamem apenas "Part".
    for _,part in ipairs(world:GetChildren()) do
        if part:IsA("BasePart") and part.Size.X<=9 and
            part.Size.Y<=9 and part.Size.Z<=9 then
            local sprite=nil
            for _,child in ipairs(part:GetChildren()) do
                if child:IsA("BasePart") and child.Size.X>=2 and
                    child.Size.X<=9 and child.Size.Y>=2 and
                    child.Size.Y<=9 and child.Size.Z<1 then
                    sprite=child
                    break
                end
            end
            if sprite then
                fish=part
                spriteSize=sprite.Size.Y
                break
            end
        end
    end
    if not fish then
        return nil,"Part do peixe sem sprite filho identificavel"
    end
    return {
        viewport=vp,world=world,fish=fish,
        obstacleSet=obstacles,fishHeight=spriteSize
    },nil
end
local function swimObstacleGaps(scene)
    -- Cada grupo ObstacleSet.Part tem duas barreiras, inferior e superior.
    -- Desconsidera o sprite 2D (Size.Z=0.05) e le as partes de colisao 3D.
    local obstacles={}
    for _,group in ipairs(scene.obstacleSet:GetChildren()) do
        local solids={}
        for _,part in ipairs(group:GetDescendants()) do
            if part:IsA("BasePart") and part.Size.Z>=.5 and
                part.Size.X>=.5 and part.Size.Y>=.7 and
                part.Size.Y<200 then
                table.insert(solids,part)
            end
        end
        table.sort(solids,function(a,b)return a.Position.Y<b.Position.Y end)
        if #solids>=2 then
            -- Usa o par com a menor distancia X, de forma a evitar misturar
            -- barreiras de pares de algas diferentes.
            local low,high,distX=nil,nil,math.huge
            for i=1,#solids-1 do
                for j=i+1,#solids do
                    local one,two=solids[i],solids[j]
                    local dx=math.abs(one.Position.X-two.Position.X)
                    if dx<distX and two.Position.Y-one.Position.Y>1.0 then
                        low,high,distX=one,two,dx
                    end
                end
            end
            if low and high and distX<8 then
                local gapLow=low.Position.Y+low.Size.Y*.5
                local gapHigh=high.Position.Y-high.Size.Y*.5
                local width=math.max(low.Size.X,high.Size.X)
                if gapHigh>gapLow and gapHigh-gapLow>=scene.fishHeight+1.4 then
                    table.insert(obstacles,{
                        x=(low.Position.X+high.Position.X)*.5,
                        gapLow=gapLow,gapHigh=gapHigh,
                        width=width,low=low,high=high,
                        source=group
                    })
                end
            end
        end
    end
    table.sort(obstacles,function(a,b)return a.x<b.x end)
    return obstacles
end
local function chooseSwimGap(scene,fish)
    local barriers=swimObstacleGaps(scene)
    local px=fish.Position.X
    local upcoming=nil
    local bestDist=math.huge
    -- Peixe no diagnostico esta em X=-13.5; alga seguinte em X=-5.87.
    -- Os objetos se deslocam da direita para a esquerda.
    for _,barrier in ipairs(barriers) do
        local dx=barrier.x-px
        if dx>=-math.max(3,barrier.width*.5+1.5) and dx<=52 then
            local score=dx>=0 and dx or math.abs(dx)*.3
            if score<bestDist then
                upcoming,bestDist=barrier,score
            end
        end
    end
    return upcoming,barriers
end
local function activeSwimWorld(window)
    local scene,reason=swimScene(window)
    if not scene then return nil,reason end
    local gap,allGaps=chooseSwimGap(scene,scene.fish)
    scene.gap=gap
    scene.gapCount=#allGaps
    scene.mode="worldmodel"
    scene.weedCount=#allGaps
    return scene,nil
end

local function activeSwimUI()
    local window,reason=swimWindow()
    if not window then return nil,reason end
    if not swimSessionActive(window) then
        return nil,"Barnaby fora de jogo"
    end
    -- Tenta primeiro o mapa 3D fornecido pelo diagnostico V14.
    local scene=select(1,activeSwimWorld(window))
    if scene then return scene,nil end
    local fish=nil
    local weeds={}
    local fishTerms={"barnaby","fish","swimmy","playerfish","swimmer"}
    local weedTerms={"seaweed","alga","kelp","obstacle","pipe"}
    -- Examina so GameWindow para nao confundir seu Toon/ESP com o peixe.
    for _,o in ipairs(window:GetDescendants()) do
        if o:IsA("GuiObject") and visibleGui(o) then
            local name=o.Name:lower()
            local z=o.AbsoluteSize
            if swimNameMatch(name,fishTerms) and
                z.X>=8 and z.X<=125 and z.Y>=8 and z.Y<=125 and
                not o:IsA("TextLabel") and not o:IsA("TextButton") then
                fish=o
            elseif swimNameMatch(name,weedTerms) and
                z.X>=9 and z.Y>=18 then
                table.insert(weeds,o)
            end
        end
    end
    local totals=swimDescribe(window)
    -- Se o minijogo e desenhado em uma imagem unica, o Lua nao tem acesso
    -- aos pixels nem consegue distinguir o peixe da alga nessa imagem.
    if not fish or #weeds<2 then
        local cause="peixe/algas ainda sem coordenadas separadas"
        if totals.gui<=5 or (totals.images<=1 and totals.viewport==0) then
            cause="GameWindow provavelmente desenha a cena em imagem unica"
        end
        return {
            mode="undetectable",reason=cause,scope=window,
            fish=fish,weedCount=#weeds,totals=totals
        },nil
    end
    return {
        mode="structured",scope=window,fish=fish,weeds=weeds,
        weedCount=#weeds,totals=totals
    },nil
end

local function touchMiniScreen(x,y)
    local vim=nil
    pcall(function()vim=game:GetService("VirtualInputManager")end)
    if not vim then return false end
    return pcall(function()
        vim:SendMouseButtonEvent(x,y,0,true,game,0)
        vim:SendMouseButtonEvent(x,y,0,false,game,0)
    end)
end
-- Controle proporcional com preditor simples para nao tocar sem parar.
-- O peixe sobe com toques e desce com gravidade. Le a posicao 3D real,
-- tenta se manter no centro do proximo vao e antecipa a queda/subida.
local function swimControlWorld(scene)
    if not scene or scene.mode~="worldmodel" or not scene.fish
        or not scene.fish.Parent then return false end
    local fish=scene.fish
    local fishY=fish.Position.Y
    local now=os.clock()
    if swimWorldSession~=scene.world then
        swimWorldSession=scene.world
        swimWorldLastY=nil
        swimWorldLastTime=nil
        swimWorldVelocity=0
        swimWorldFailures=0
        swimWorldTapStill=0
    end
    local lastY,lastTime=swimWorldLastY,swimWorldLastTime
    if lastY and lastTime and now-lastTime>.025 and now-lastTime<.35 then
        local raw=(fishY-lastY)/(now-lastTime)
        if math.abs(raw)<120 then
            swimWorldVelocity=swimWorldVelocity*.55+raw*.45
        end
    end
    swimWorldLastY=fishY
    swimWorldLastTime=now
    swimWorldFish=fish.Position
    local gap=select(1,chooseSwimGap(scene,fish))
    scene.gap=gap
    local target=0
    local margin=scene.fishHeight*.5+1.05
    local soon=false
    if gap then
        local minY=gap.gapLow+margin
        local maxY=gap.gapHigh-margin
        if maxY<=minY then
            miniLastError="vao estreito demais para o peixe"
            return false
        end
        -- Manter centralizado fornece margem nos dois lados.
        target=(minY+maxY)*.5
        local d=gap.x-fish.Position.X
        soon=d<math.max(25,gap.width*2+8)
        swimWorldGap={x=gap.x,low=gap.gapLow,high=gap.gapHigh,
            target=target,dist=d}
    else
        -- Sem alga proxima, manter a altura neutra do aquario.
        target=0
        swimWorldGap=nil
    end
    target=math.clamp(target,-15,17)
    swimWorldStep=swimWorldStep+1
    local horizon=soon and .20 or .15
    local prediction=fishY+swimWorldVelocity*horizon
    -- Perto de uma alga, use a margem superior do centro como
    -- seguranca, pois a queda natural do peixe continua.
    local tolerance=soon and math.max(.8,scene.fishHeight*.23) or 2.1
    local wantTap=prediction<target-tolerance
    if not wantTap then return false end
    if now-swimLastTap<(soon and .105 or .16) then return false end

    -- Tocar dentro da area do ViewportFrame, evitando o botao SAIDA.
    local vp=scene.viewport
    local rect,dim=vp.AbsolutePosition,vp.AbsoluteSize
    if dim.X<160 or dim.Y<90 then return false end
    local x=rect.X+dim.X*.7
    local y=rect.Y+dim.Y*.53
    swimLastTarget=target
    swimLastTap=now
    local ok=touchMiniScreen(x,y)
    miniTapCount=miniTapCount+1
    miniTapMethod=ok and "V15 ViewportFrame 3D" or "Delta nao enviou toque"
    if ok then
        swimWorldLastYAtTap=fishY
        swimWorldLastPressAt=now
    else
        miniLastError="nao foi possivel tocar na tela de nado"
    end
    return ok
end

local function swimControlTick(info)
    if not info or info.mode~="structured" or not info.fish.Parent then
        return false
    end
    local scope,fish=info.scope,info.fish
    local p,z=scope.AbsolutePosition,scope.AbsoluteSize
    local fpos,fsize=fish.AbsolutePosition,fish.AbsoluteSize
    local fx=fpos.X+fsize.X*.5
    local fy=fpos.Y+fsize.Y*.5
    local targetY=p.Y+z.Y*.49
    -- Encontra o par de algas que vai passar em frente ao peixe.
    local close={}
    for _,weed in ipairs(info.weeds) do
        if weed.Parent and visibleGui(weed) then
            local wp,wz=weed.AbsolutePosition,weed.AbsoluteSize
            if wp.X+wz.X>fx-5 and wp.X<fx+z.X*.48 then
                table.insert(close,{top=wp.Y,bottom=wp.Y+wz.Y,
                    center=wp.X+wz.X*.5})
            end
        end
    end
    table.sort(close,function(a,b)return a.center<b.center end)
    if #close>=2 then
        local first=close[1]
        for j=2,math.min(5,#close) do
            local second=close[j]
            if math.abs(first.center-second.center)<70 then
                local upper=first.top<second.top and first or second
                local lower=first.top<second.top and second or first
                local gap=lower.top-upper.bottom
                if gap>fsize.Y+8 then
                    targetY=(upper.bottom+lower.top)*.5
                end
                break
            end
        end
    end
    targetY=math.clamp(targetY,p.Y+z.Y*.23,p.Y+z.Y*.78)
    swimLastTarget=targetY
    local now=os.clock()
    if fy>targetY+math.max(8,fsize.Y*.17) and now-swimLastTap>.18 then
        swimLastTap=now
        local ok=touchMiniScreen(p.X+z.X*.74,p.Y+z.Y*.54)
        if ok then miniTapCount=miniTapCount+1;miniTapMethod="swim mouse" end
        return ok
    end
    return false
end

-- Frequencia moderada, sem cliques indiscriminados em toda a tela.
task.spawn(function()
    local lastModeNotice=0
    while live do
        if state.autoSkill then
            local treadmill,reason=nil,nil
            local swimmingNow=false
            if state.autoSkill then
                local window=select(1,swimWindow())
                swimmingNow=window and swimSessionActive(window) or false
            end
            if state.autoSkill and not swimmingNow then
                treadmill,reason=activeTreadmillUI()
            end
            if treadmill then
                minigameMode="esteira"
                local now=os.clock()
                local session=treadmillSession
                if not session or session.required~=treadmill.required or
                    (session.lastSeen and now-session.lastSeen>1.0) or
                    (treadmill.counterFound and treadmill.current<(session.current or 0)) then
                    session={required=treadmill.required,current=treadmill.current,
                        attempts=0,lastTap=0,lastSeen=now,started=now,progress=0,
                        lastProgressAt=now}
                    treadmillSession=session
                end
                session.lastSeen=now
                if treadmill.counterFound and treadmill.current>session.current then
                    session.progress=session.progress+
                        (treadmill.current-session.current)
                    session.current=treadmill.current
                    session.lastProgressAt=now
                end
                treadLastObservedCount=treadmill.current
                -- Envia ESPACO repetidamente. Nunca depende do botão de tela
                -- que antes retornava sucesso mas nao alterava o contador.
                local limit=treadmill.counterFound and
                    math.min(22,session.required*3) or 10
                local finished=treadmill.counterFound and
                    treadmill.current>=treadmill.required
                if not finished and session.attempts<limit and
                    now-session.lastTap>.095 then
                    local ok=pressTreadmillSpace()
                    session.attempts=session.attempts+1
                    session.lastTap=now
                    if ok then miniTapCount=miniTapCount+1 end
                    miniTapMethod=ok and treadInputMethod or
                        "Nao foi possivel enviar Espaco"
                    -- Plano B somente quando Space nao esta disponivel.
                    if not ok then
                        local touched=clickRealSkillButton(treadmill.button,false)
                        if touched then miniTapMethod="botao fallback" end
                    end
                end
                miniLastError=treadmill.counterFound and
                    ("esteira "..treadmill.current.."/"..treadmill.required..
                    " | tentativas "..session.attempts) or
                    ("contador oculto | tentativas "..session.attempts)
            else
                treadmillSession=nil
                local swim=select(1,activeSwimUI())
                if swim then
                    minigameMode="natacao"
                    if swim.mode=="worldmodel" and state.autoSkill then
                        swimControlWorld(swim)
                    elseif swim.mode=="structured" and state.autoSkill then
                        swimControlTick(swim)
                    elseif swim.mode=="undetectable" then
                        miniLastError=swim.reason
                        if state.autoSkill and os.clock()-lastModeNotice>5 then
                            say("Nadacao: sprite ou algas nao detectados; controle manual.")
                            lastModeNotice=os.clock()
                        end
                    end
                else
                    minigameMode="nenhum"
                end
            end
        else
            treadmillSession=nil
            minigameMode="nenhum"
        end
        -- Durante natacao, atualizar posicao do peixe e obstaculos
        -- mais rapido do que o scan de maquinas para evitar colisoes.
        task.wait((state.autoSkill and minigameMode=="natacao") and .075 or
            ((state.autoSkill and minigameMode=="esteira") and .085 or .18))
    end
end)

local function miniDiagnostic(onlyReport)
    local lines={
        "DOUBLEX HUB DANDY V18 - MINIJOGOS",
        "Modo detectado: "..minigameMode,
        "Ultimo toque: "..miniTapMethod,
        "Toques enviados: "..tostring(miniTapCount),
        "Aviso: "..tostring(miniLastError),""
    }
    local tread,reason=activeTreadmillUI()
    table.insert(lines,"Esteira: "..(tread and
        (tread.current.."/"..tread.required) or tostring(reason)))
    table.insert(lines,"Contador encontrado: "..tostring(tread and tread.counterFound))
    table.insert(lines,"Metodo SPACE: "..tostring(treadInputMethod))
    table.insert(lines,"Contador visto: "..tostring(treadLastObservedCount))
    if treadmillSession then
        table.insert(lines,"Toques tentados na rodada: "..tostring(treadmillSession.attempts))
        table.insert(lines,"Mudancas de contador: "..tostring(treadmillSession.progress))
    end
    local swim,swimReason=activeSwimUI()
    table.insert(lines,"Natacao: "..(swim and
        (tostring(swim.mode).." | algas "..tostring(swim.weedCount or 0))
        or tostring(swimReason)))
    if swim and swim.mode=="worldmodel" then
        table.insert(lines,"PEIXE 3D: "..tostring(swim.fish.Position))
        table.insert(lines,"Peixe SizeY="..tostring(swim.fishHeight)..
            " | velocidade Y estimada="..string.format("%.2f",swimWorldVelocity))
        table.insert(lines,"GRUPOS DE ALGAS 3D: "..tostring(swim.gapCount))
        local barrierList=swimObstacleGaps(swim)
        for n,barrier in ipairs(barrierList) do
            if n>12 then break end
            table.insert(lines,string.format(
                "ALGAS #%d X=%.2f | vao Y=%.2f..%.2f | largura %.2f",
                n,barrier.x,barrier.gapLow,barrier.gapHigh,barrier.width))
        end
        if swimWorldGap then
            table.insert(lines,string.format(
                "ALVO 3D: Y=%.2f | proximo vao X=%.2f | deltaX=%.2f",
                swimWorldGap.target,swimWorldGap.x,swimWorldGap.dist))
        end
        table.insert(lines,"Auto natacao: "..tostring(state.autoSkill))
    end
    local window,windowReason=swimWindow()
    if not window then
        table.insert(lines,"GAMEWINDOW: "..tostring(windowReason))
    else
        local totals=swimDescribe(window)
        table.insert(lines,string.format(
            "GAMEWINDOW: %s | Gui=%d | Imagens=%d | Viewports=%d | Pecas3D=%d | PeixesNome=%d | AlgasNome=%d",
            window.ClassName,totals.gui,totals.images,totals.viewport,
            totals.parts,totals.fish,totals.kelp))
        table.insert(lines,"MODELOS VISUAIS (inclusive elementos invisiveis):")
        local count=0
        local function append(o)
            if count>=190 then return end
            count=count+1
            local info=o:GetFullName():gsub("^.-%.PlayerGui%.","PlayerGui.")
            local extras=""
            if o:IsA("GuiObject") then
                local p,z=o.AbsolutePosition,o.AbsoluteSize
                extras=string.format(" vis=%s X%d Y%d W%d H%d",
                    tostring(visibleGui(o)),math.floor(p.X),math.floor(p.Y),
                    math.floor(z.X),math.floor(z.Y))
                if o:IsA("ImageLabel") or o:IsA("ImageButton") then
                    extras=extras.." Image="..tostring(o.Image):sub(1,100)
                    extras=extras.." Rect="..tostring(o.ImageRectOffset)..
                        "/"..tostring(o.ImageRectSize)
                end
                local tint=o:IsA("ImageLabel") and o.ImageColor3 or
                    (o:IsA("ImageButton") and o.ImageColor3 or o.BackgroundColor3)
                if tint then
                    extras=extras..string.format(" rgb=%d,%d,%d",
                        math.floor(tint.R*255),math.floor(tint.G*255),
                        math.floor(tint.B*255))
                end
                if miniText(o)~="" then
                    extras=extras.." Text="..miniText(o):sub(1,65)
                end
            elseif o:IsA("BasePart") then
                extras=" Pos="..tostring(o.Position).." Size="..tostring(o.Size)
            elseif o:IsA("WorldModel") then
                extras=" WorldModel"
            end
            table.insert(lines,string.format("%s [%s]%s",info,o.ClassName,extras))
        end
        append(window)
        for _,o in ipairs(window:GetDescendants()) do
            if o:IsA("GuiObject") or o:IsA("BasePart") or
                o:IsA("WorldModel") or o:IsA("Camera") or
                o:IsA("UIStroke") then
                append(o)
                if count>=190 then break end
            end
        end
    end
    local result=table.concat(lines,"\n")
    if onlyReport then return result end
    if type(setclipboard)=="function" then
        local ok=pcall(function()setclipboard(result)end)
        say(ok and "Diagnostico V15 3D copiado. Envie aqui."
            or "Abra o console Delta para o diagnostico.")
    else
        say("Diagnostico V14 no console Delta.")
    end
    print(result)
end

-- Um unico diagnostico da aba: inclui o SkillCheck tradicional,
-- os aneis, a esteira e a natacao 3D, sem botoes de testes separados.
addButton("Diagnosticar verificacoes (copiar)",function()
    local report=skillDiagnostic(true).."\n\n"..miniDiagnostic(true)
    if type(setclipboard)=="function" then
        local ok=pcall(function()setclipboard(report)end)
        say(ok and "Diagnostico das verificacoes copiado."
            or "Falha ao copiar; confira o console Delta.")
    else
        say("Diagnostico no console Delta (clipboard indisponivel).")
    end
    print(report)
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
    local monster,dist=nearest("monsters")
    local statusText=(map and ("Maquinas "..(progress or "?").."  |  ")
        or "Lobby / carregando andar  |  ")
    if monster then
        statusText=statusText.."Twisted "..math.floor(dist).." studs"
    else
        statusText=statusText.."Sem Twisted encontrado"
    end
    if state.danger and monster and dist<DANGER_RANGE then
        status.TextColor3=C.danger
        status.Text="PERIGO! "..statusText
    else
        status.TextColor3=C.mute
        status.Text=statusText
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
    state.autoCollect=false
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
print("[DOUBLEX Dandy v32 Compacto] ESP, sobrevivencia, speed, skillcheck e coletor. Tudo OFF.")