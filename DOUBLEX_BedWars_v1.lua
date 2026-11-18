-- DOUBLEX HUB BEDWARS v1 | Delta Android
-- Independent project. Client-side features; server validates combat and purchases.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local HttpService = game:GetService('HttpService')
local player = Players.LocalPlayer
local guiParent = (gethui and gethui()) or player:WaitForChild('PlayerGui')
local old = guiParent:FindFirstChild('DOUBLEX_BEDWARS_V1')
if old then old:Destroy() end
local configFile = 'DOUBLEX_BedWars_settings.json'
local cfg = {jump=false, esp=false, autoSword=false, aura=false, range=12}
if readfile and isfile and isfile(configFile) then
    local ok,data=pcall(function() return HttpService:JSONDecode(readfile(configFile)) end)
    if ok and type(data)=='table' then for k in pairs(cfg) do if type(data[k])==type(cfg[k]) then cfg[k]=data[k] end end end
end
local function save()
    if writefile then pcall(function() writefile(configFile,HttpService:JSONEncode(cfg)) end) end
end
local gui=Instance.new('ScreenGui');gui.Name='DOUBLEX_BEDWARS_V1';gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.Parent=guiParent
local function create(class, props, parent)
    local o=Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    o.Parent=parent
    return o
end
local panel=create('Frame',{Size=UDim2.fromOffset(280,325),Position=UDim2.new(.5,-140,.5,-162),BackgroundColor3=Color3.fromRGB(23,25,35),BorderSizePixel=0,Active=true,Draggable=true},gui)
create('UICorner',{CornerRadius=UDim.new(0,12)},panel)
create('TextLabel',{Size=UDim2.new(1,-85,0,43),Position=UDim2.fromOffset(12,0),BackgroundTransparency=1,Text='DOUBLEX | BEDWARS v1',TextColor3=Color3.new(1,1,1),TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},panel)
local close=create('TextButton',{Size=UDim2.fromOffset(36,32),Position=UDim2.new(1,-42,0,5),Text='X',TextSize=17,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(156,46,56)},panel)
create('UICorner',{CornerRadius=UDim.new(0,8)},close)
local status=create('TextLabel',{Position=UDim2.fromOffset(12,277),Size=UDim2.new(1,-24,0,39),BackgroundTransparency=1,Text='Recursos experimentais; servidor valida ataques.',TextWrapped=true,TextColor3=Color3.fromRGB(190,190,202),TextSize=11,Font=Enum.Font.Gotham},panel)
local alive=true
local connections={}
local highlights={}
local function button(label,key,y)
    local b=create('TextButton',{Size=UDim2.new(1,-24,0,39),Position=UDim2.fromOffset(12,y),Font=Enum.Font.GothamSemibold,TextSize=13,TextColor3=Color3.new(1,1,1)},panel)
    local function paint() b.Text=label..' : '..(cfg[key] and 'ON' or 'OFF');b.BackgroundColor3=cfg[key] and Color3.fromRGB(40,127,99) or Color3.fromRGB(55,59,74) end
    create('UICorner',{CornerRadius=UDim.new(0,7)},b)
    b.MouseButton1Click:Connect(function() cfg[key]=not cfg[key];paint();save() end)
    paint()
end
button('Infinite Jump','jump',48)
button('ESP adversarios','esp',94)
button('Auto equipar espada','autoSword',140)
button('Aura (experimental)','aura',186)
local info=create('TextLabel',{Size=UDim2.new(1,-24,0,40),Position=UDim2.fromOffset(12,231),BackgroundTransparency=1,Text='Aura: apenas tentativa de ativacao de Tool; nao contorna limites de alcance ou cooldown.',TextColor3=Color3.fromRGB(200,200,212),TextWrapped=true,TextSize=11,Font=Enum.Font.Gotham},panel)
local function characterParts(p)
    local c=p.Character
    return c,c and c:FindFirstChildOfClass('Humanoid'),c and c:FindFirstChild('HumanoidRootPart')
end
local function enemy(p)
    return p~=player and (not player.Team or p.Team~=player.Team)
end
local function findSword()
    local c=player.Character
    if not c then return nil end
    for _,folder in ipairs({c,player:FindFirstChildOfClass('Backpack')}) do
        if folder then for _,tool in ipairs(folder:GetChildren()) do
            if tool:IsA('Tool') and string.find(tool.Name:lower(),'sword') then return tool end
        end end
    end
end
local function equipSword()
    local c,h=characterParts(player)
    local sword=findSword()
    if sword and c and h and sword.Parent~=c then pcall(function() h:EquipTool(sword) end) end
    return sword
end
connections[#connections+1]=UIS.JumpRequest:Connect(function()
    if not alive or not cfg.jump then return end
    local _,h=characterParts(player)
    if h and h.Health>0 then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
local elapsed=0
connections[#connections+1]=RunService.Heartbeat:Connect(function(dt)
    if not alive then return end
    elapsed=elapsed+dt
    if elapsed<.25 then return end
    elapsed=0
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player then
            local c,h=characterParts(p)
            if cfg.esp and enemy(p) and c and h and h.Health>0 then
                if not highlights[p] or highlights[p].Parent~=c then
                    if highlights[p] then highlights[p]:Destroy() end
                    local hl=Instance.new('Highlight');hl.Name='DOUBLEX_ESP';hl.FillColor=Color3.fromRGB(255,80,85);hl.OutlineColor=Color3.new(1,1,1);hl.FillTransparency=.6;hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.Adornee=c;hl.Parent=c;highlights[p]=hl
                end
            elseif highlights[p] then highlights[p]:Destroy();highlights[p]=nil end
        end
    end
    if cfg.autoSword then equipSword() end
    if cfg.aura then
        local _,h,root=characterParts(player)
        if h and h.Health>0 and root then
            local nearby=false
            for _,p in ipairs(Players:GetPlayers()) do
                if enemy(p) then
                    local _,eh,eroot=characterParts(p)
                    if eh and eh.Health>0 and eroot and (root.Position-eroot.Position).Magnitude<=cfg.range then nearby=true;break end
                end
            end
            if nearby then
                local sword=equipSword()
                if sword and sword.Parent==player.Character then pcall(function() sword:Activate() end) end
            end
        end
    end
end)
connections[#connections+1]=Players.PlayerRemoving:Connect(function(p)
    if highlights[p] then highlights[p]:Destroy();highlights[p]=nil end
end)
close.MouseButton1Click:Connect(function()
    alive=false
    for _,connection in ipairs(connections) do connection:Disconnect() end
    for _,highlight in pairs(highlights) do highlight:Destroy() end
    save()
    gui:Destroy()
end)
