-- Jailbreak Fun Hub V1 - LocalScript / Delta Mobile
-- Interface e utilitarios locais. Nao altera regras ou danos do servidor.
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local player = Players.LocalPlayer
local guiParent = (gethui and gethui()) or game:GetService('CoreGui')
local old = guiParent:FindFirstChild('JailbreakFunHubV1')
if old then old:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name='JailbreakFunHubV1'; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Parent=guiParent
local function create(class,props,parent)
 local obj=Instance.new(class)
 for k,v in pairs(props) do obj[k]=v end
 obj.Parent=parent
 return obj
end
local bg=Color3.fromRGB(23,26,37)
local accent=Color3.fromRGB(58,173,255)
local panel=create('Frame',{Size=UDim2.fromOffset(330,410),Position=UDim2.new(.5,-165,.5,-205),BackgroundColor3=bg,BorderSizePixel=0},gui)
create('UICorner',{CornerRadius=UDim.new(0,12)},panel)
local title=create('TextLabel',{Size=UDim2.new(1,-90,0,42),Position=UDim2.fromOffset(12,0),BackgroundTransparency=1,Text='🚔 Jailbreak Fun Hub V1',TextColor3=Color3.new(1,1,1),TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},panel)
local mini=create('TextButton',{Size=UDim2.fromOffset(32,30),Position=UDim2.new(1,-75,0,6),Text='−',TextSize=22,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(55,65,82)},panel)
local close=create('TextButton',{Size=UDim2.fromOffset(32,30),Position=UDim2.new(1,-39,0,6),Text='×',TextSize=22,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(160,56,68)},panel)
for _,v in ipairs({mini,close}) do create('UICorner',{CornerRadius=UDim.new(0,7)},v) end
local scroll=create('ScrollingFrame',{Position=UDim2.fromOffset(10,46),Size=UDim2.new(1,-20,1,-56),BackgroundTransparency=1,ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
create('UIListLayout',{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
local function label(text)
 return create('TextLabel',{Size=UDim2.new(1,-8,0,27),BackgroundTransparency=1,Text=text,TextColor=accent,TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},scroll)
end
local function button(text,callback)
 local b=create('TextButton',{Size=UDim2.new(1,-8,0,36),BackgroundColor3=Color3.fromRGB(42,49,66),Text=text,TextColor3=Color3.new(1,1,1),TextSize=13,Font=Enum.Font.GothamMedium},scroll)
 create('UICorner',{CornerRadius=UDim.new(0,7)},b)
 b.MouseButton1Click:Connect(function() local ok,err=pcall(callback,b); if not ok then warn('[FunHub] '..tostring(err)) end end)
 return b
end
local status=label('Status: pronto para testar')
local function say(s) status.Text='Status: '..s end
local function humanoid() local c=player.Character; return c and c:FindFirstChildOfClass('Humanoid') end
local function root() local c=player.Character; return c and c:FindFirstChild('HumanoidRootPart') end
local function numberField(text,initial,callback)
 local holder=create('Frame',{Size=UDim2.new(1,-8,0,39),BackgroundTransparency=1},scroll)
 create('TextLabel',{Size=UDim2.new(.5,0,1,0),BackgroundTransparency=1,Text=text,TextColor3=Color3.new(1,1,1),TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},holder)
 local input=create('TextBox',{Position=UDim2.new(.5,0,0,3),Size=UDim2.new(.5,-4,1,-6),BackgroundColor3=Color3.fromRGB(49,57,77),Text=tostring(initial),PlaceholderText='Digite um valor',ClearTextOnFocus=false,TextColor3=Color3.new(1,1,1),TextSize=14},holder)
 create('UICorner',{CornerRadius=UDim.new(0,6)},input)
 input.FocusLost:Connect(function() local n=tonumber(input.Text); if n then callback(n) else say('Digite um numero valido') end end)
end
label('🎮 Modos de jogo')
local mode='manual'
button('Modo: Manual Assistido',function(b) mode=mode=='manual' and 'experimental' or 'manual'; b.Text=mode=='manual' and 'Modo: Manual Assistido' or 'Modo: Automatico (experimental)'; say(mode=='manual' and 'Modo manual selecionado' or 'Modo experimental selecionado (sem auto roubo)') end)
button('Verificar personagem',function() say(humanoid() and 'Personagem carregado' or 'Aguardando personagem') end)
label('🏃 Personagem (ajustes locais)')
numberField('Velocidade',16,function(n) local h=humanoid(); if h then h.WalkSpeed=math.clamp(n,0,100); say('Velocidade aplicada localmente') end end)
numberField('Pulo',50,function(n) local h=humanoid(); if h then h.UseJumpPower=true; h.JumpPower=math.clamp(n,0,150); say('Pulo aplicado localmente') end end)
numberField('Campo de visao',70,function(n) workspace.CurrentCamera.FieldOfView=math.clamp(n,40,120); say('Camera ajustada') end)
button('Restaurar controles padrao',function() local h=humanoid(); if h then h.WalkSpeed=16; h.UseJumpPower=true; h.JumpPower=50 end; workspace.CurrentCamera.FieldOfView=70; say('Valores restaurados') end)
label('💰 Roubos - painel informativo')
button('Listar pontos de interesse',function() say('Banco • Joalheria • Museu • Tumba • Cassino • Trens') end)
button('Auto Robbery (ainda nao implementado)',function() say('Precisa de integracao especifica com o jogo') end)
button('Auto Puzzle (ainda nao implementado)',function() say('Sem automacao de minigames nesta versao') end)
label('👥 Jogadores')
button('Mostrar jogadores e equipes',function()
 local counts={}; for _,p in ipairs(Players:GetPlayers()) do local t=p.Team and p.Team.Name or 'Sem equipe'; counts[t]=(counts[t] or 0)+1 end
 local parts={}; for t,n in pairs(counts) do table.insert(parts,t..': '..n) end
 say(table.concat(parts,' | '))
end)
button('Distancia do jogador mais proximo',function()
 local r=root(); if not r then return say('Personagem nao carregado') end
 local best,bestD=nil,math.huge
 for _,p in ipairs(Players:GetPlayers()) do if p~=player and p.Character then local pr=p.Character:FindFirstChild('HumanoidRootPart'); if pr then local d=(r.Position-pr.Position).Magnitude; if d<bestD then best,bestD=p,d end end end end
 say(best and (best.DisplayName..': '..math.floor(bestD)..' studs') or 'Nenhum jogador proximo')
end)
label('⚙️ Seguranca e interface')
button('PARAR / Restaurar',function() local h=humanoid(); if h then h.WalkSpeed=16; h.UseJumpPower=true; h.JumpPower=50 end; workspace.CurrentCamera.FieldOfView=70; say('Ajustes locais restaurados') end)
local collapsed=false
mini.MouseButton1Click:Connect(function() collapsed=not collapsed; scroll.Visible=not collapsed; panel.Size=collapsed and UDim2.fromOffset(330,42) or UDim2.fromOffset(330,410); mini.Text=collapsed and '+' or '−' end)
close.MouseButton1Click:Connect(function() gui:Destroy() end)
local dragging,dragStart,startPos=false,nil,nil
title.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=input.Position; startPos=panel.Position end end)
UIS.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement) then local delta=input.Position-dragStart; panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y) end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
