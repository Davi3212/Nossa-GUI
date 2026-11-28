-- Doublex Hub Boat Wars - teste manual V4
-- Uma tentativa por clique; nao altera posicao, saldo ou interface do jogo.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
for _,name in ipairs({"DoublexBoatDiagnostic","DoublexBoatTestV3","DoublexBoatTestV4"}) do
    local old=pg:FindFirstChild(name)
    if old then old:Destroy() end
end
local gui=Instance.new("ScreenGui")
gui.Name="DoublexBoatTestV4"
gui.ResetOnSpawn=false
gui.DisplayOrder=500
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=pg
local function make(class,parent,props)
    local o=Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    o.Parent=parent
    return o
end
local purple=Color3.fromRGB(112,53,190)
local white=Color3.fromRGB(245,240,255)
local function round(o) make("UICorner",o,{CornerRadius=UDim.new(0,9)}) end
local panel=make("Frame",gui,{Size=UDim2.fromOffset(320,218),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.44),BackgroundColor3=Color3.fromRGB(24,18,39),BorderSizePixel=0})
round(panel)
local scale=make("UIScale",panel,{Scale=1})
local function fit()
    local cam=workspace.CurrentCamera
    if cam then scale.Scale=math.min(1,cam.ViewportSize.X/350,cam.ViewportSize.Y/300) end
end
fit()
local title=make("TextLabel",panel,{Size=UDim2.new(1,-80,0,33),BackgroundTransparency=1,Text="DOUBLEX | Boat Wars V4",TextColor3=white,TextSize=15,Font=Enum.Font.GothamBold,Active=true})
local function button(parent,txt,x,y,w,h)
    local b=make("TextButton",parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=purple,Text=txt,TextColor3=white,TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0})
    round(b)
    return b
end
local mini=button(panel,"-",245,3,32,27)
local close=button(panel,"X",282,3,32,27)
local plotBox=make("TextBox",panel,{Position=UDim2.fromOffset(8,39),Size=UDim2.fromOffset(78,35),BackgroundColor3=Color3.fromRGB(59,43,83),Text="Plot3",PlaceholderText="Sua base",ClearTextOnFocus=false,TextColor3=white,TextSize=13,Font=Enum.Font.GothamBold})
round(plotBox)
local collect=button(panel,"Coletar dinheiro",92,39,220,35)
local result=make("TextLabel",panel,{Position=UDim2.fromOffset(8,81),Size=UDim2.fromOffset(304,129),BackgroundColor3=Color3.fromRGB(13,10,22),Text="Confirme o nome da SUA base (Plot3 no teste anterior).\nFique longe e parado.\nAperte Coletar dinheiro.",TextColor3=white,TextSize=12,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})
round(result)
make("UIPadding",result,{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)})
local bubble=button(gui,"DX",12,95,45,45)
bubble.Visible=false
local alive,busy=true,false
local connections={}
local function connect(signal,fn)
    local c=signal:Connect(fn)
    table.insert(connections,c)
end
local function txt(o)
    return o and o.Parent and o.Text or "N/D"
end
local function moneyLabel(g)
    for _,o in ipairs(g:GetDescendants()) do
        if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text:find("%$%s*[%d]") then return o end
    end
end
local function cashLabel()
    local best,max=nil,-1
    for _,o in ipairs(pg:GetDescendants()) do
        if not o:IsDescendantOf(gui) and (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Visible then
            local v=o.Text:match("^%s*%$([%d,]+)%s*$")
            local n=v and tonumber((v:gsub(",","")))
            if n and n>max then best,max=o,n end
        end
    end
    return best
end
local function test()
    if busy or not alive then return end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then result.Text="Personagem indisponivel."; return end
    if type(firetouchinterest)~="function" then result.Text="Delta nao disponibilizou firetouchinterest."; return end
    local name=plotBox.Text:match("^%s*(Plot%d+)%s*$")
    local plots=workspace:FindFirstChild("Plots")
    local plot=name and plots and plots:FindFirstChild(name)
    local target=plot and plot:FindFirstChild("MainPlotPart")
    if not target or not target:IsA("BasePart") then result.Text="Sua base nao foi encontrada. Confira o nome."; return end
    local cash=cashLabel()
    local before=txt(cash)
    local pos=root.Position
    local dist=(target.Position-pos).Magnitude
    busy=true
    collect.Text="Testando..."
    result.Text="Medindo saldo antes da tentativa..."
    task.spawn(function()
        task.wait(1.5)
        if not alive then return end
        if not root.Parent or not target.Parent or (root.Position-pos).Magnitude>2 then
            busy=false; collect.Text="Coletar dinheiro"; result.Text="Personagem mudou de posicao. Fique parado e tente novamente."; return
        end
        local cb=txt(cash)
        local ok,err=pcall(firetouchinterest,root,target,0)
        if ok then
            task.wait(.7)
            local endOk,endErr=pcall(firetouchinterest,root,target,1)
            if not endOk then ok,err=false,endErr end
        end
        task.wait(.8)
        busy=false
        if not alive then return end
        collect.Text="Coletar dinheiro"
        local ca=txt(cash)
        result.Text=name.." / MainPlotPart ("..math.floor(dist).." studs do centro)\n"
            .."Saldo sem teste: "..before.." -> "..cb.."\n"
            .."Saldo com teste: "..cb.." -> "..ca.."\n"
            ..(ok and "Tentativa enviada; servidor pode ignorar." or "Falha: "..string.sub(tostring(err),1,90))
    end)
end
collect.Activated:Connect(test)
mini.Activated:Connect(function() panel.Visible=false; bubble.Visible=true end)
bubble.Activated:Connect(function() panel.Visible=true; bubble.Visible=false; fit() end)
local drag,origin,initial
connect(title.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; origin=i.Position; initial=panel.Position end
end)
connect(UIS.InputChanged,function(i)
    if drag and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
        local d=i.Position-origin
        panel.Position=UDim2.new(initial.X.Scale,initial.X.Offset+d.X,initial.Y.Scale,initial.Y.Offset+d.Y)
    end
end)
connect(UIS.InputEnded,function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
end)
gui.Destroying:Connect(function()
    alive=false
    for _,c in ipairs(connections) do c:Disconnect() end
end)
close.Activated:Connect(function() gui:Destroy() end)
