-- title:  Flower Protector
-- author: Istvan Szalontai
-- desc:   Spray the bugs. Protect your flower.
-- script: lua
-- date:   2021-03-31
-- twitter:@pisti72

debug=false
--debug=true
paused=false
difficulty=6

title=1
beforegame=2
ingame=3
lifelost=4
gameover=5
flowereaten=6
floweropen=7
wave=1
grab_time=60
flower_opens_at=7000
flower_init=2000
flower_dies_at=1800
spray_reload=14
--state=test
state=title
robot={}
flower={}
bullets={}
booms={}
bugs={}
leaves={
 {x=123,y=20,flip=0},
	{x=101,y=30,flip=1},
	{x=123,y=40,flip=0}
}
sprays={
 {gfx=32,speed=3,bgfx=24},
	{gfx=34,speed=3,bgfx=23},
	{gfx=36,speed=3,bgfx=22}
}
bugdb={
	{gfx=10,bullet=23,xd=.2,yd=.05},
	{gfx=44,bullet=23,xd=.2,yd=.05},
	{gfx=76,bullet=24,xd=.2,yd=.2},
	{gfx=136,bullet=24,xd=.2,yd=.2},
	{gfx=140,bullet=22,xd=.2,yd=.5},
	{gfx=172,bullet=22,xd=.2,yd=.5}
}
waves={
 {1,2},
	{3,4},
	{1,2,3,4},
	{5,6},
	{1,2,5,6},
	{3,4,5,6},
	{1,2,3,4,5,6}
}
slots={}
coord={x=120,y=66}
flr=math.floor
abs=math.abs
rnd=math.random
ctr={up=0,
 down=1,
	left=2,
	right=3,
	fire=4,
	action=5}
boom_anim_speed=2


function init()
 robot.gfx=2
	robot.steps=0
	robot.speed=2
	robot.hand=12
	robot.score=0
	robot.grab=0
	robot.high=0
	robot.reload=0
	robot.lives=5
	
	flower.x=116
	flower.gfx=38
	flower.opening=0

	create_slots()
	init_robot()
	flower.height=flower_init
end

function create_slots()
 n=1
	for j=0,1 do
		for i=0,4 do
		 slot={}
			slot.x=8+j*208
			slot.y=16+24*i
			slot.free=true
		 slots[n]=slot
			n=n+1
		end
	end	
end

function init_robot()
 robot.x=112
	robot.y=44
	robot.died=false
	robot.spray=-1
	--flower.height=flower_init
	put_sprays()
	bugs={}
end

function put_sprays()
	array={}
	for i=1,#sprays do
		repeat
			s=rnd(#slots-1)+1
		until not contains(array,s)
		array[i]=s
		spray=sprays[i]
		slot=slots[s]
		spray.x=slot.x
		spray.y=slot.y+2
		spray.grabbed=false
		slot.free=false
	end
end

function contains(array,a)
 for i=1,#array do
	 if a==array[i] then
		 return true
		end
	end
	return false
end

init()

function TIC()
 cls(0)
	map()
	update_flower()
	update_leaves()
	update_robot()
	update_sprays()
	update_bullets()
	update_bugs()
	update_booms()
	update_states()
	if debug then
		draw_slots()
	end
	
	if state==test then
	 draw_test()
	end
	draw_scores()	
end

function draw_test()
 for wave=1,10 do
	 n=(wave-1)%(#waves)+1
	 i=#waves[n]
		b=waves[n][rnd(i)]
		
		print(wave.."-"..b,24,wave*8+24,12)
	end
end

function update_states()
 if btnp(ctr.fire) 
	 or btnp(ctr.action) then
	 if state==beforegame then
		 state=ingame
			sfx(5)
		elseif state==floweropen then
		 state=beforegame
			--next level
			init_robot()
			flower.height=flower_init
			sfx(5)
			wave=wave+1
		elseif state==lifelost then
		 init_robot()
			state=ingame
			sfx(5)
		elseif state==flowereaten then
		 init_robot()
			flower.height=flower_init
			state=ingame
			sfx(5)
		elseif state==gameover then
		 init_robot()
			flower.height=flower_init
			state=title
			sfx(5)
		elseif state==title then
			init_robot()
			flower.height=flower_init
			robot.lives=5
			robot.score=0
			wave=1
		 state=beforegame
			sfx(5)
		end
	end
	
	if btnp(6) then
	 paused = not paused
	end
	
	if debug==true then
	 coord.x=flower.height
		--coord.x=flower.opening
		print(coord.x..","..coord.y,1,50,14)
		print(coord.x..","..coord.y,0,50,12) 
	end
	if state==title then
	 print("Flower",87,28,2,false,2)
		print("Protector",69,47,2,false,2)
		print("Flower",86,28,4,false,2)
		print("Protector",68,47,4,false,2)
		print_middle("2021 Demake by @pisti72",65)		
		spr(robot.gfx,53,17,11,2,0,0,2,2)
		robot.x=-60
		press_fire() 
	elseif state==beforegame then
	 print_middle("SPRAY THE BUGS",68)
		print_middle("WAVE-"..ndigits(wave,2),77)
	 press_fire()
	elseif state==lifelost then
	 print_middle("ROBOT KILLED BY A BUG",68)
	 press_fire()
	elseif state==flowereaten then
	 print_middle("PLANT HAS BEEN EATEN",68)
	 press_fire()
	elseif state==floweropen then
	 print_middle("FLOWER IS GROWN UP",40)
	 press_fire()
	elseif state==gameover then
		print_middle("GAME OVER",68)
		press_fire()
	end
end

function press_fire()
 print_middle("PRESS FIRE TO START",114) 
end

function print_middle(txt,y)
 width=print(txt,0,-20)
	print(txt,120-width/2+1,y,9)
	print(txt,120-width/2,y,12)
end

function update_booms()
 for i,boom in ipairs(booms) do
		spr(boom.gfx,boom.x,boom.y,0,1,0,0,2,2)
		if not paused then
			boom.t=boom.t-1
		end
		if boom.t==0 then
		 boom.t=boom_anim_speed
			boom.gfx=boom.gfx+2
			if boom.gfx>110 then
			 table.remove(booms,i)
			end
		end
	end
end

function update_bugs()
	if rnd(1000)>970 
	 and state==ingame 
		and #bugs<flr(wave/#waves*2)+robot.lives+difficulty then
	 
		s=rnd(#slots)
		
		n=(wave-1)%(#waves)+1
	 i=#waves[n]
		b=waves[n][rnd(i)]
			
		bug={}
		bug.x=slots[s].x
		bug.y=slots[s].y
		bug.xd=bugdb[b].xd
		bug.yd=bugdb[b].yd
		bug.gfx=bugdb[b].gfx
		bug.bulletgfx=bugdb[b].bullet
		bug.flip=0
		bug.freezed=0
		bug.anim=0
		bug.score=100
		if no_other_bug(bug) and no_spray(bug)
		 and not overlapped(bug,robot,32) then
		 table.insert(bugs,bug)
		end
	end
	
	for i,bug in ipairs(bugs) do
	 if overlapped(bug,robot,10) 
		 and not robot.died 
			and not debug then
			sfx(6)
		 robot.died=true
			robot.lives=robot.lives-1
			if robot.lives==0 then
			 state=gameover
			else
			 state=lifelost
			end
			create_boom(robot)
			create_boom(bug)
			table.remove(bugs,i)
			sfx(3)
		end
		
		if (bug.x<20 and bug.xd<0)
		 or (bug.x>200 and bug.xd>0) then
		  bug.xd=-bug.xd
		end
		
		if bug.y>116 or bug.y<0 then
		 bug.yd=-bug.yd
		end
		
		if bug.freezed>0 then
		 bug.freezed=bug.freezed-1
		end
		
		if bug.xd>0 then
		 bug.flip=0
		else
		 bug.flip=1
		end
		bug.anim=bug.anim+1
		if state==ingame then
			
			if not is_flower(bug) 
			 and bug.freezed==0 
				and not paused then
				bug.x=bug.x+bug.xd
				bug.y=bug.y+bug.yd
			end
			
			if is_flower(bug) 
			 and not paused then
			 flower.height=flower.height-1
			end
		
		end
		offset=flr(bug.anim/8)%2*2
		spr(bug.gfx+offset,bug.x,bug.y,0,1,bug.flip,0,2,2)
	end
end

function is_flower(bug)
 return in_box(bug.x+2,bug.y+8,
	 flower.x,flower.top,8,2000) 
		or in_box(bug.x+12,bug.y+8,
	 flower.x,flower.top,8,2000)
end

function in_box(x1,y1,x,y,w,h)
 return x1>x and x1<x+w 
		and y1>y	and y1<y+h 
end

function update_flower()
 if state==ingame 
	 and not paused then
		flower.height=flower.height+1
 end
	flower.top=120-flr(flower.height/100)
	for i=0,flr(flower.height/100/8)-1 do
		spr(8,flower.x,flower.top+(i+2)*8,0)
	end
	
	if state==floweropen then
  
		if flower.opening==480 then
		 music(0,-1,-1,false)
		end
		
		if flower.opening>480 then
			spr(66,flower.x-4-8,flower.top,0,1,0,0,4,2)
		elseif	flower.opening>460 then
		 spr(70,flower.x-4-16,flower.top,0,1,0,0,6,2)
		else
			spr(128,flower.x-4-24,flower.top,0,1,0,0,8,2)
		end
		
		if flower.opening>0 then
		 flower.opening=flower.opening-1
		end
	
	else
		spr(38,flower.x-4,flower.top,0,1,0,0,2,2)
	end
	
	for i=0,2 do
		spr(7,flower.x+i*8-4,128)
	end
	if debug then
	 rectb(flower.x,flower.top+8,8,120-flower.top,12)	
  line(120,0,120,136,12) 
	end
	if state==ingame then
		if flower.height<flower_dies_at 
		 and not robot.died 
			and not debug then
		 robot.died=true
			robot.lives=robot.lives-1
			if robot.lives==0 then
			 state=gameover
			else
			 state=flowereaten
			end
			create_boom(robot)
			sfx(3)
		elseif flower.height>flower_opens_at then
		 state=floweropen
			flower.opening=500
		end
	end
end

function update_leaves()
	for i=1,#leaves do
	 local y=flower.top+leaves[i].y
		if y<=100 then
		 local anim=100-y
			if anim>5 then anim=5 end
	 	spr(160+anim*2,leaves[i].x,y,0,1,leaves[i].flip,0,2,2)
		end	
	end
end

function update_bullets()
 for i,bullet in ipairs(bullets) do
	 if not paused then 
		 bullet.x=bullet.x+bullet.xd
		end
		if bullet.x<0 or
		 bullet.x>240 or 
			fget(mget(flr(bullet.x+4)/8,
		  flr(bullet.y+4)/8),0) then
		 table.remove(bullets,i)
		end
		for j,bug in ipairs(bugs) do
		 if overlapped(bug,bullet,12) then 
			 if bug.bulletgfx==bullet.gfx then
				 create_boom(bug)
					table.remove(bugs,j)
					table.remove(bullets,i)
					robot.score=robot.score+bug.score
					if robot.score>robot.high then
					 robot.high=robot.score
					end
					sfx(3)
				else
				 bug.freezed=200
				end
			end
		end
		spr(bullet.gfx,bullet.x,bullet.y,0,1,bullet.flip)
	end
end

function create_boom(bug)
 boom={}
	boom.x=bug.x
	boom.y=bug.y
	boom.t=boom_anim_speed
	boom.gfx=96
	table.insert(booms,boom)
end

function update_sprays()
	for i=1,#sprays do
		s=sprays[i]
		--grab spray
		if overlapped(s,robot,16) 
		 and robot.spray==-1 
			and robot.grab==0 then
		 s.grabbed=true
			robot.grab=grab_time
			robot.spray=i
			sfx(0)
		end
		
		if s.grabbed then
		 if robot.died or state==floweropen then
			 s.y=s.y+2
				if s.y>114 then
				 s.y=114
				end
			else
			 s.x=robot.x+robot.hand
				s.y=robot.y
				if (btn(ctr.fire) or btn(ctr.action))
				 and robot.reload==0 and not paused then
					sfx(2)
				 robot.reload=spray_reload
				 bullet={}
					
					bullet.y=s.y
					bullet.gfx=s.bgfx
					if robot.hand>0 then
					 bullet.x=s.x+8
						bullet.xd=s.speed
						bullet.flip=0
					else
					 bullet.x=s.x-1
					 bullet.xd=-s.speed
					 bullet.flip=1
					end
					table.insert(bullets,bullet)
				end
			 --can release the spray
				for j=1,#slots do
				 if overlapped(s,slots[j],16) 
					 and no_others(i) 
						and robot.grab==0 then
					 s.grabbed=false
						robot.grab=grab_time
						robot.spray=-1
						s.x=slots[j].x
						s.y=slots[j].y+2
						sfx(1)
					end
				end
		 end
		end
		spr(s.gfx,s.x,s.y,11,1,0,0,2,2)
	end
end

function no_others(n)
	for i=1,#sprays do
	 if not(n==i) and overlapped(sprays[i],sprays[n],16) then
		 return false
		end
	end
	return true
end

function no_spray(bug)
 for i=1,#sprays do
	 if overlapped(sprays[i],bug,16) then
		 return false
		end
	end
	return true
end

function no_other_bug(b)
 for i,bug in ipairs(bugs) do
	 if overlapped(b,bug,16) then
		 return false
		end
	end
	return true
end

function update_robot()
 robot.xd=0
	robot.yd=0
	if btn(ctr.up) then 
		robot.yd=-robot.speed
		robot.steps=robot.steps+1
		coord.y=coord.y-1 
	end
	if btn(ctr.down) then 
		robot.yd=robot.speed
		robot.steps=robot.steps+1
	 coord.y=coord.y+1
	end
	
	if btn(ctr.left) then
	 robot.hand=-12 
	 robot.xd=-robot.speed
		robot.steps=robot.steps+1
		coord.x=coord.x-1 
	end
	if btn(ctr.right) then 
		robot.hand=12
		robot.xd=robot.speed
		robot.steps=robot.steps+1
		coord.x=coord.x+1 
	end
	
	if not solid(robot) 
	 and robot.y+robot.yd>0 
		and not robot.died 
		and state==ingame then
		robot.x=robot.x+robot.xd
		robot.y=robot.y+robot.yd
	end
	
	if robot.reload>0 then
	 robot.reload=robot.reload-1
	end
	
	if robot.grab>0 then
	 robot.grab=robot.grab-1
	end
	
	
	if not robot.died then
	 if state==floweropen then
			robot.gfx=42
			if flr(flower.opening/16)%2==0 then
				robot.gfx=40
			end
		else
		 robot.gfx=2
			if flr(robot.steps/4)%2==0 
			 and state==ingame then
				robot.gfx=4
			end
  end
		spr(robot.gfx,robot.x,robot.y,11,1,0,0,2,2)
	end
	
end

function solid(actor)
	for j=2,12,5 do
	 for i=2,12,5 do
		 if fget(mget(
	 flr(actor.x+actor.xd+i)/8,
		flr(actor.y+actor.yd+j)/8),0) then
		 	return true
			end
		end
	end

	return false
end

function overlapped(a,b,distance)
 return abs(a.x-b.x)<distance and abs(a.y-b.y)<distance
end

function draw_slots()
 for i=1,#slots do
	 spr(64,slots[i].x,slots[i].y,0,1,0,0,2,2)
	end
end

function draw_scores()
 print(ndigits(robot.score,6),6,0,12)
	print(ndigits(robot.high,6),200,0,12)
	for i=1,robot.lives do
	 spr(9,94+i*8,0,0)
	end
end

function ndigits(i,n)
 k=#tostring(i)
	txt=""
	for j=1,n-k do
	 txt=txt.."0"
	end
 return txt..i
end
