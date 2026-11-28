-- Doublex Hub Boat Wars - diagnostico V2 (somente leitura)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("DoublexBoatDiagnostic")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "DoublexBoatDiagnostic"
gui.ResetOnSpawn = false
gui.Parent = pg
local function make(class, parent, props)
    local o = Instance.new(class)
    for k,v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local purple = Color3.fromRGB(112,53,190)
local white = Color3.fromRGB(245,240,255)
local function round(o) make("UICorner",o,{CornerRadius=UDim.new(0,9)}) end
local panel = make("Frame",gui,{Size=UDim2.fromOffset(340,280),Position=UDim2.new(.5,-170,.5,-140),BackgroundColor3=Color3.fromRGB(24,18,39),BorderSizePixel=0})
round(panel)
local scale=make("UIScale",panel,{Scale=1})
local function fit()
    local cam=workspace.CurrentCamera
    if cam then scale.Scale=math.min(1,(cam.ViewportSize.X-16)/340,(cam.ViewportSize.Y-24)/280) end
end
fit()
local title=make("TextLabel",panel,{Size=UDim2.new(1,-88,0,36),BackgroundTransparency=1,Text="DOUBLEX | Boat Wars V2",TextColor3=white,TextSize=15,Font=Enum.Font.GothamBold,Active=true})
local function button(parent,txt,x,y,w,h)
    local b=make("TextButton",parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=purple,Text=txt,TextColor3=white,TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0})
    round(b)
    return b
end
local mini=button(panel,"-",260,4,34,29)
local close=button(panel,"X",299,4,34,29)
local start=button(panel,"Gravar 8s",8,42,110,32)
local snap=button(panel,"Foto agora",124,42,104,32)
local clear=button(panel,"Limpar",234,42,98,32)
local status=make("TextLabel",panel,{Position=UDim2.fromOffset(8,78),Size=UDim2.fromOffset(324,24),BackgroundTransparency=1,Text="Pronto: fique ao lado do coletor.",TextColor3=white,TextSize=12,TextWrapped=true})
local tabTouch=button(panel,"Toques",8,105,104,28)
local tabNear=button(panel,"Perto",118,105,104,28)
local tabOther=button(panel,"Valores",228,105,104,28)
local output=make("TextLabel",panel,{Position=UDim2.fromOffset(8,138),Size=UDim2.fromOffset(324,101),BackgroundColor3=Color3.fromRGB(13,10,22),BorderSizePixel=0,TextColor3=white,TextSize=14,Font=Enum.Font.Code,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Text="Nenhum registro ainda."})
round(output)
local prevButton=button(panel,"< Anterior",8,244,104,28)
local nextButton=button(panel,"Proximo >",228,244,104,28)
local pageLabel=make("TextLabel",panel,{Position=UDim2.fromOffset(118,244),Size=UDim2.fromOffset(104,28),BackgroundTransparency=1,TextColor3=white,TextSize=12,Text="0 / 0"})
local bubble=button(gui,"DX",12,110,48,48)
bubble.Visible=false
local connections={}
local touches={}
local lines={Toques={},Perto={},Valores={}}
local category="Toques"
local page=1
local recording=false
local alive=true
local seen={}
local lastText={}
local function render()
    local list=lines[category]
    page=math.clamp(page,1,math.max(1,#list))
    output.Text=list[page] or "Nenhum registro nesta categoria."
    pageLabel.Text=(#list==0 and "0" or tostring(page)).." / "..#list
    for key,btn in pairs({Toques=tabTouch,Perto=tabNear,Valores=tabOther}) do
        btn.BackgroundColor3=key==category and purple or Color3.fromRGB(59,43,83)
    end
end
local function choose(k)
    category=k
    page=1
    render()
end
local function reset()
    for _,list in pairs(lines) do table.clear(list) end
    page=1
    render()
end
tabTouch.Activated:Connect(function() choose("Toques") end)
tabNear.Activated:Connect(function() choose("Perto") end)
tabOther.Activated:Connect(function() choose("Valores") end)
prevButton.Activated:Connect(function() page=page-1; render() end)
nextButton.Activated:Connect(function() page=page+1; render() end)
local function add(s)
    local k=s:sub(1,6)=="TOQUE:" and "Toques" or s:sub(1,6)=="PERTO:" and "Perto" or "Valores"
    local list=lines[k]
    if k=="Perto" then
        for _,v in ipairs(list) do if v==s then return end end
    end
    if #list<250 then table.insert(list,s) end
    if category==k then render() end
end
render()
local function money(s)
    return type(s)=="string" and #s<120 and s:find("%$%s*[%d]")
end
local function positionOf(g)
    local a=g.Adornee or g.Parent
    if not a then return nil end
    if a:IsA("Attachment") then return a.WorldPosition end
    if a:IsA("BasePart") then return a.Position end
    if a:IsA("Model") then return a:GetPivot().Position end
    return nil
end
local function sample(label,full)
    local char=plr.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then add("Sem personagem"); return end
    add("-- "..label.." --")
    local n=0
    for _,g in ipairs(workspace:GetDescendants()) do
        if g:IsA("BillboardGui") or g:IsA("SurfaceGui") then
            local pos=positionOf(g)
            if pos and (pos-root.Position).Magnitude<=24 then
                for _,t in ipairs(g:GetDescendants()) do
                    if (t:IsA("TextLabel") or t:IsA("TextButton")) and money(t.Text) then
                        local prev=lastText[t]
                        if full or (prev and prev~=t.Text) then
                            add("VALOR: "..t.Text..(prev and prev~=t.Text and " (antes "..prev..")" or ""))
                            add("OBJ: "..g:GetFullName())
                            n=n+1
                        end
                        lastText[t]=t.Text
                        if n>=8 then break end
                    end
                end
            end
        end
        if n>=8 then break end
    end
    local h=0
    for _,t in ipairs(pg:GetDescendants()) do
        if not t:IsDescendantOf(gui) and (t:IsA("TextLabel") or t:IsA("TextButton")) and money(t.Text) and t.Visible then
            local prev=lastText[t]
            if full or (prev and prev~=t.Text) then
                add("HUD: "..t.Text..(prev and prev~=t.Text and " (antes "..prev..")" or ""))
                h=h+1
            end
            lastText[t]=t.Text
            if h>=6 then break end
        end
    end
    if full then
        local params=OverlapParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={char}
        params.MaxParts=40
        local parts=workspace:GetPartBoundsInRadius(root.Position,7,params)
        table.sort(parts,function(a,b) return (a.Position-root.Position).Magnitude<(b.Position-root.Position).Magnitude end)
        for i=1,math.min(6,#parts) do
            local p=parts[i]
            add("PERTO: "..p:GetFullName())
        end
    end
end
local function connect(signal,fn,list)
    local c=signal:Connect(fn)
    table.insert(list or connections,c)
end
local function bindChar(char)
    for _,c in ipairs(touches) do c:Disconnect() end
    table.clear(touches)
    local function attach(p)
        if not p:IsA("BasePart") then return end
        connect(p.Touched,function(hit)
            if not alive or not recording or not hit or hit:IsDescendantOf(char) or seen[hit] then return end
            seen[hit]=true
            add("TOQUE: "..hit:GetFullName())
        end,touches)
    end
    for _,p in ipairs(char:GetDescendants()) do attach(p) end
    connect(char.DescendantAdded,attach,touches)
end
if plr.Character then bindChar(plr.Character) end
connect(plr.CharacterAdded,bindChar)
start.Activated:Connect(function()
    if recording then return end
    reset()
    table.clear(seen)
    table.clear(lastText)
    recording=true
    status.Text="Passe por cima de UMA construcao!"
    task.spawn(function()
        local ok,err=pcall(function()
            sample("ANTES",true)
            for i=1,8 do
                task.wait(1)
                if not alive then return end
                sample("SEG "..i,i==8)
            end
        end)
        recording=false
        if not alive then return end
        if not ok then add("ERRO: "..tostring(err)) end
        choose(#lines.Toques>0 and "Toques" or "Perto")
        status.Text="Fim! Toques: "..#lines.Toques.." | Perto: "..#lines.Perto
    end)
end)
snap.Activated:Connect(function()
    if recording then return end
    local ok,err=pcall(sample,"FOTO",true)
    if not ok then add("ERRO: "..tostring(err)) end
end)
clear.Activated:Connect(function()
    if recording then return end
    reset()
    status.Text="Registro limpo."
end)
mini.Activated:Connect(function() panel.Visible=false; bubble.Visible=true end)
bubble.Activated:Connect(function() panel.Visible=true; bubble.Visible=false; fit() end)
local dragging=false
local origin,initial
connect(title.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; origin=i.Position; initial=panel.Position
    end
end)
connect(UIS.InputChanged,function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=i.Position-origin
        panel.Position=UDim2.new(initial.X.Scale,initial.X.Offset+d.X,initial.Y.Scale,initial.Y.Offset+d.Y)
    end
end)
connect(UIS.InputEnded,function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)
local function cleanup()
    if not alive then return end
    alive=false
    recording=false
    for _,c in ipairs(connections) do c:Disconnect() end
    for _,c in ipairs(touches) do c:Disconnect() end
end
gui.Destroying:Connect(cleanup)
close.Activated:Connect(function() cleanup(); gui:Destroy() end)
