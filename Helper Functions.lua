local hf = {reduceConst = 20, softenAmount = 0.2929}

-- Tables --
-- returns a shallow copy of a table
-- you can pass a table as the second paramator, and it will copy the first table into the second
function hf.copy (obj,obj2)
	if obj2 == nil then obj2 = {}; end
	for k,v in pairs (obj) do
		obj2[k] = v;
		
	end
	return obj2;
end

local function tableToString (tbl,tabSub)
	local vals = "{";
	local funcs = "";
	for k,v in pairs (tbl) do
		local t = type(v);
		if t == "function" then
			funcs = string.format ("%s\n%sfunction %s(?)", funcs, tabSub, k);
		elseif t == "table" then
			vals = string.format("%s\n%s%s: table", vals, tabSub, k);
		else
			vals = string.format("%s\n%s%s: %s = %s", vals, tabSub, tostring(k), t, tostring(v));
		end
	end
	return vals.."\n"..funcs.."\n".."}";
end

-- convirts a table into a string
function hf.tableToString (tbl)
	return tableToString(tbl,"\t");
end

-- Math --
-- returns normalizes a number.
function hf.getDir (i)
	if i < 0 then return -1; end
	if i > 0 then return 1; end
	return 0;
end

-- moves a rectangles so that the origin is in the center
function hf.centerRect (x,y,w,h)
	return x - (w * 0.5), y - (h * 0.5), w, h;
end

-- reduces over time
function hf.reduce (val, am, dt)
	return val * math.pow(1/(1 + am),dt * hf.reduceConst);
end

-- approaches a value over time
function hf.moveTo (val, target, am, dt)
	return hf.reduce (val - target, am, dt) + target
end

-- takes in 2 values that ranges between -1 and 1, and divides them as they both approach 1 and/or -1
function hf.softenEdges (x,y)
	local mult = 1 - math.abs(x*y*hf.softenAmount);
	return x * mult, y * mult
end

-- takes in an image, and 
function hf.centerImage (img)
	local ox, oy = img:getDimensions();
	return ox * 0.5, oy * 0.5;
end



-- Pythagorean theoram
function hf.distenceSqr (x,y) return (x*x)+(y*y);end
function hf.distence (x,y)return math.sqrt(hf.distenceSqr(x,y));end

-- takes in 2 numbers and normalizes them so that each is only 1 unit from zero
function hf.normalize (x,y)
	if x == 0 and y == 0 then return 0,0; end
	local mult = 1/hf.distence(x,y);
	return x * mult, y * mult;
end

-- Physics
function collideRect (posX1, posY1, posX2, posY2, sizeX, sizeY)
	local distX, distY = math.abs (posX1 - posX2), math.abs (posY1 - posY2);
	return distX < sizeX && distY < sizeY;
end

-- Input --
-- takes in 2 keys, lesser lessens the return value, and greater increases it
-- returns a value between -1 and 1
function hf.inputDir (lesser, greater)
	local dir = 0;
	if love.keyboard.isDown (lesser) then
		dir = -1;
	end
	if love.keyboard.isDown (greater) then
		dir = dir + 1;
	end
	return dir;
end

-- getMousePos declared in gameState;

-- FileLoading --
--[[
Don't use these functions in love 2D. They're unstable, and unsafe.
function hf.loadFile (path)
	local f, err = io.open (path, "r+");
	if f == nil then
		f, err = io.open ("../"..path, "r+");
		if f == nil then
			error(err);
		end
	end
	local txt = "";
	local res = f:read().."\n";
	while res ~= nil do
		txt = txt..res.."\n";
		res = f:read();
	end
	f:close();
	return txt;
end

function hf.loadLevel (scene, level, levelBuilder, sep)
	local lev = hf.loadFile (level)
	local x, y = sep * 0.5, sep * 0.5;
	local skipNL = true;
	for i = 1, #lev do
		local c = string.sub(lev,i,i)
		local s = levelBuilder[c];
		if s ~= nil then
			s(scene, x, y);
		elseif c == "\n" then
			if skipNL then 
				skipNL = false;
			else
				x,y = -sep * 0.5, y + sep;
			end
		end
		x = x + sep;
	end
end
--]]

-- adds objects to a level based on a string
-- takes in the
-- world you want to populate,
-- the string you format from,
-- a table of functions that are executed on each charactor (world, posX, posY) (use these to call the creation functions),
-- element seperator says how mush to seperate the new objects
function hf.formatLevel (world, level, lb, elmSep)
	local x,y = elmSep * 0.5, elmSep * 0.5;
	for i = 1, #level do
		local c = string.sub (level, i, i);
		local objMaker = lb[c];
		if c == "\n" then
			x, y = -elmSep * 0.5, y + elmSep;
		elseif objMaker ~= nil then
			objMaker(world, x, y);
		end
		x = x + elmSep;
	end
end 

return hf;

