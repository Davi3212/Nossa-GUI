-- DOUBLEX HUB | TESTE 04 | Delta Android
-- Teste de ativacao de Tool equipada. Nao contorna validacoes do servidor.
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local player = Players.LocalPlayer
local pg = player:WaitForChild('PlayerGui')
for _, name in ipairs({'DOUBLEX_TESTE_03','DOUBLEX_TESTE_04'}) do
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
end
local gui = Instance.new('ScreenGui')
gui.Name = 'DOUBLEX_TESTE_04'
gui.ResetOnSpawn = false
gui.Parent = pg
local function corner(o,r)
    local c = Instance.new('UICorner')
    c.CornerRadius = UDim.new(0,r)
    c.Parent=o
end
local function button(parent,txt,size,pos,bg)
    local b=Instance.new('TextButton')
    b.Size=size b.Position=pos b.BackgroundColor3=bg or Color3.fromRGB(45,53,73)
    b.Text=txt b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold b.TextSize=13 b.Parent=parent
    corner(b,9)
    return b
end
local bubble=button(gui,'DX',UDim2.fromOffset(48,48),UDim2.new(0,12,0.4,0),Color3.fromRGB(26,33,50))
corner(bubble,24)
local panel=Instance.new('Frame')
panel.Name='Painel' panel.Size=UDim2.fromOffset(258,220)
panel.Position=UDim2.new(0,65,0.34,0)
panel.BackgroundColor3=Color3.fromRGB(24,28,40)
panel.Visible=false panel.Parent=gui corner(panel,12)
local header=button(panel,'DOUBLEX | TESTE 04',UDim2.new(1,-66,0,32),UDim2.fromOffset(5,4),Color3.fromRGB(24,28,40))
local mini=button(panel,'-',UDim2.fromOffset(27,27),UDim2.new(1,-61,0,6))
local close=button(panel,'X',UDim2.fromOffset(27,27),UDim2.new(1,-31,0,6))
local info=Instance.new('TextLabel')
info.Position=UDim2.fromOffset(12,40)
info.Size=UDim2.new(1,-24,0,121)
info.BackgroundTransparency=1 info.TextColor3=Color3.fromRGB(225,234,250)
info.TextXAlignment=Enum.TextXAlignment.Left info.TextYAlignment=Enum.TextYAlignment.Top
info.Font=Enum.Font.Code info.TextSize=12 info.TextWrapped=true
info.Text='Aguardando personagem...' info.Parent=panel
local toggle=button(panel,'ATIVAR TESTE',UDim2.new(1,-24,0,38),UDim2.fromOffset(12,169),Color3.fromRGB(45,118,83))
local alive=true
local enabled=false
local range=10
local cooldown=0.4
local attempts=0
local status='Aguardando ativacao'
local lastHealth={}
local lastChange='Nenhuma mudanca de vida'
local lastAttempt=0
local function stop()
    enabled=false
    toggle.Text='ATIVAR TESTE'
    toggle.BackgroundColor3=Color3.fromRGB(45,118,83)
end
bubble.MouseButton1Click:Connect(function() panel.Visible=not panel.Visible end)
mini.MouseButton1Click:Connect(function() panel.Visible=false end)
close.MouseButton1Click:Connect(function() alive=false stop() gui:Destroy() end)
toggle.MouseButton1Click:Connect(function()
    enabled=not enabled
    toggle.Text=enabled and 'DESATIVAR TESTE' or 'ATIVAR TESTE'
    toggle.BackgroundColor3=enabled and Color3.fromRGB(147,67,65) or Color3.fromRGB(45,118,83)
    status=enabled and 'Procurando alvo a ate 10 studs' or 'Desligado'
end)
local function draggable(handle,target)
    local dragging=false
    local startInput,startPos,activeInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true activeInput=input startInput=input.Position startPos=target.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging or not startInput then return end
        if input~=activeInput and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=input.Position-startInput
        target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end)
end
draggable(bubble,bubble)
draggable(header,panel)
local elapsed=0
local conn
conn=RunService.Heartbeat:Connect(function(dt)
    if not alive or not gui.Parent then if conn then conn:Disconnect() end return end
    elapsed=elapsed+dt
    if elapsed<0.15 then return end
    elapsed=0
    local char=player.Character
    local root=char and char:FindFirstChild('HumanoidRootPart')
    local myHum=char and char:FindFirstChildOfClass('Humanoid')
    local tool=char and char:FindFirstChildOfClass('Tool')
    local closest,dist
    for _,other in ipairs(Players:GetPlayers()) do
        if other~=player then
            local oc=other.Character
            local hrp=oc and oc:FindFirstChild('HumanoidRootPart')
            local hum=oc and oc:FindFirstChildOfClass('Humanoid')
            if root and hrp and hum and hum.Health>0 then
                local d=(root.Position-hrp.Position).Magnitude
                if not dist or d<dist then closest=other dist=d end
                local previous=lastHealth[other.UserId]
                if previous and math.abs(previous-hum.Health)>0.01 then
                    lastChange=other.DisplayName..': '..math.floor(previous)..' -> '..math.floor(hum.Health)
                end
                lastHealth[other.UserId]=hum.Health
            end
        end
    end
    if enabled then
        if not myHum or myHum.Health<=0 then
            status='Personagem sem vida'
        elseif not tool then
            status='Equipe uma espada/Tool'
        elseif not closest or not dist or dist>range then
            status='Aproxime-se do alvo (10 studs)'
        elseif os.clock()-lastAttempt>=cooldown then
            lastAttempt=os.clock()
            attempts=attempts+1
            local ok,err=pcall(function() tool:Activate() end)
            status=ok and 'Tool:Activate() chamado' or ('Erro: '..tostring(err):sub(1,35))
        end
    end
    info.Text='Arma: '..(tool and tool.Name or 'Nenhuma')..'\n'..
        'Alvo: '..(closest and closest.DisplayName or 'Nenhum')..'\n'..
        'Distancia: '..(dist and string.format('%.1f studs',dist) or '--')..'\n'..
        'Tentativas: '..attempts..'\n'..
        'Vida: '..lastChange..'\n'..
        'Status: '..status..'\n'..
        'Automatico: '..(enabled and 'LIGADO' or 'DESLIGADO')
end)
