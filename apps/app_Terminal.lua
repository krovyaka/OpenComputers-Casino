local component = require("component")
local term = require("term")
local gpu = component.gpu
local unicode = require("unicode")
local pim = component.pim
local me = component.me_interface

local item = {["id"] = "customnpcs:npcMoney",["dmg"]=0,["display_name"]="Money"}

SIZE = "Down"
local value = 10
local login = true
local player = ''

function drawDisplay()
  gpu.setResolution(64,20)
  gpu.setBackground(0xa0a0a0)
  term.clear()
  gpu.setBackground(0x000000)
  gpu.fill(3,2,60,18," ")
  gpu.set(15,5,"  Терминал для перевода эмеральдов")
  gpu.set(15,6,"           в дюрексики")
  gpu.set(15,8,"Встаньте на PIM для входа в терминал")
  login = false
end

function localsay(msg, color)
  gpu.setForeground(color)
  gpu.setBackground(0)
  gpu.set((gpu.getResolution()-unicode.len(msg))/2,4,msg)
  os.sleep(1.2)
  gpu.setForeground(0xffffff)
  gpu.fill(3,4,59,1," ")
end

function drawInterface(nick)
  value = 10
  local temp_items = me.getAvailableItems()
  local temp_money = 0
  for i=1,#temp_items do
    if (temp_items[i].fingerprint.id==item.id and temp_items[i].fingerprint.dmg == item.dmg) then
      temp_money = temp_items[i].size
      break
    end
  end
  
  money_of_player, bonus_money_of_player = Connector:get(nick)
  gpu.setResolution(64,20)
  gpu.setBackground(0xa0a0a0)
  term.clear()
  gpu.setBackground(0x000000)
  gpu.fill(3,2,60,18," ")
  gpu.set(15,6,"        Здравствуйте, "..nick)
  
  local p_money = "На Вашем счету "..money_of_player.." дюрексиков"
  
  gpu.set(33-math.floor(unicode.len(p_money)/2),7,p_money)
  gpu.set(15,8,"     В терминале "..temp_money.." дюрексиков")
  
  gpu.set(8,12,"                      ------                       ")
  gpu.set(8,13,"+1 +5 +10 +50 +100    |10  |    -1 -5 -10 -50 -100")
  gpu.set(8,14,"                      ------                       ")
  gpu.setBackground(0x00aa00)
  gpu.fill(4,16,25,3," ")
  gpu.set(8,17,"Пополнить баланс")
  gpu.setBackground(0xaa0000)
  gpu.fill(37,16,25,3," ")
  gpu.set(41,17,"Снять со счёта")
  login = true
  player = nick
end

function setValue(val)
  gpu.setBackground(0x000000)
  gpu.fill(31,13,4,1,' ')
  value = val
  if value > 2304 then
    value = 2304
  elseif value < 1 then
    value = 1
  end
  gpu.set(31,13,value..'')
end	

function giveMoney(val)
  local temp_value = 0
  for i=1,40 do
    local temp_item = pim.getStackInSlot(i)
    if(temp_item ~= nil and temp_item.id == item.id and temp_item.dmg == item.dmg and temp_item.display_name == item.display_name) then
      temp_value = temp_value + temp_item.qty
    end
  end
  if (temp_value >= val) then 
    temp_value = 0
    for i=1,40 do
      local temp_item = pim.getStackInSlot(i)
      if(temp_item ~= nil and temp_item.id == item.id and temp_item.dmg == item.dmg and temp_item.display_name == item.display_name) then
        temp_value = temp_value + pim.pushItem(SIZE,i,val-temp_value)
      end
    end
    Connector:give(player,temp_value)
    localsay(player..", Вам зачислено "..temp_value.." дюрексиков на баланс.",0x00ff00)
    drawInterface(player)
  else
    localsay(player..", у Вас не хватает денег в инвентаре.",0xff0000)
  end
end

function payMoney(val)
  local temp_items = me.getAvailableItems()
  for i=1,#temp_items do
    if (temp_items[i].fingerprint.id==item.id and temp_items[i].fingerprint.dmg == item.dmg) then
      local items_count = temp_items[i].size
      if Connector:get(player)<val then
        localsay(player..", у Вас не хватает дюрексиков на счету.",0xff0000)
        return
      end
      if (items_count>= val) then
        local temp = 1
        while (val > 0 and temp > 0) do
          temp = pim.pullItem(SIZE,1,val)
          val = val - temp
          os.sleep(0.2)
        end
        Connector:pay(player,value-val)
        localsay(player..", Вы сняли "..value-val.." дюрексиков с баланса.",0x00ff00)
        drawInterface(player)
      else
        localsay(player..", у терминала нет налички. Пожалуйста, обратитесь к создателям варпа!",0xff0000)
      end
      return
    end
  end
end

drawDisplay()

while true do 
  local _,p =event.pull("player_on")
  player = p
  drawInterface(p)
  while pim.getInventoryName()==player do
    local _,_,left,top,_,a5 = event.pull(2,"touch")
    if(player == a5) then
      if (left == 8 or left == 9) and top == 13 then setValue(value+1)
      elseif (left == 11 or left == 12) and top == 13 then setValue(value+5)
      elseif (left == 14 or left == 15 or left == 16) and top == 13 then setValue(value+10)
      elseif (left == 18 or left == 19 or left == 20) and top == 13 then setValue(value+50)
      elseif (left == 22 or left == 23 or left == 24 or left == 25) and top == 13 then setValue(value+100)
      elseif (left == 40 or left == 41) and top == 13 then setValue(value-1)
      elseif (left == 43 or left == 44) and top == 13 then setValue(value-5)
      elseif (left == 46 or left == 47 or left == 48) and top == 13 then setValue(value-10)
      elseif (left == 50 or left == 51 or left == 52) and top == 13 then setValue(value-50)
      elseif (left == 54 or left == 55 or left == 56 or left == 57) and top == 13 then setValue(value-100)
      elseif (left >= 4 and left <=28 and top >= 16 and top <= 18) then giveMoney(value)
      elseif (left >= 37 and left <=61 and top >= 16 and top <= 18) then payMoney(value) end
    end
  end
  drawDisplay()
end

