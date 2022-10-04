local hf = {reduceConst = 20, softenAmount = 0.2929}

-- Tables --
-- returns a shallow copy of a table
-- you can pass a table as the second paramator, and it will copy the first table into the second
function hf.copy (obj,obj2)
	-- if a table is not there to be copied into, it creates a table to copy to
	if obj2 == nil then obj2 = {}; end

	for k,v in pairs (obj) do -- actually copies the table
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
	if i > 0 then return 1; end
	if i < 0 then return -1; end
	return 0;
end

function hf.linearReduce (val,x)
	val = val - x;
	if val < 0 then val = 0; end
	return val;
end

-- moves a rectangles so that the origin is in the center
function hf.centerRect (x,y,w,h)
	return x - (w * 0.5), y - (h * 0.5), w, h;
end

-- reduces over time
function hf.reduce (val, am, dt, snap)
	if snap == nil then snap = 0 end
	-- snaps the value to zero
	if math.abs(val) <= snap then return 0 end
	return val * math.pow(1/(1+am),hf.reduceConst * dt);
end

-- approaches a value over time
function hf.moveTo (val, target, am, dt, snap)
	return hf.reduce (val - target, am, dt, snap) + target
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
function hf.distanceSqr (x,y) return (x*x)+(y*y);end
function hf.distance (x,y)return math.sqrt(hf.distanceSqr(x,y));end

-- takes in 2 numbers and normalizes them so that each is only 1 unit from zero
function hf.normalize (x,y)
	if x == 0 and y == 0 then return 0,0; end -- prevents divide by zero errors
	local mult = 1/hf.distance(x,y); -- calculates the multiplier
	return x * mult, y * mult; -- multiplies x&y by 1/the distance
end

function hf.getGreater(x,y)
	if (x > y) then return x end
	return y;
end

function hf.getLesser(x,y)
	if (x < y) then return x end
	return y;
end

-- takes a square canvas and centers it in a rectange, so that the entire canvas is visible
function hf.centerCanvas (sizeX,sizeY, canvSize)
	local canvasScreenSize = hf.getLesser(sizeX,sizeY);
	local canvasScreenScale = canvasScreenSize / canvSize;
	local screenOffset = hf.getGreater (sizeX,sizeY) - hf.getLesser (sizeX,sizeY);
	if sizeX > sizeY then
		return screenOffset * 0.5, 0, canvasScreenScale, canvasScreenScale;
	else
		return 0, screenOffset * 0.5, canvasScreenScale, canvasScreenScale;
	end
end

function hf.centerCanvasFill (sizeX,sizeY, canvSize)
	local canvasScreenSize = hf.getLesser(sizeX,sizeY);
	local canvasScreenScale = canvasScreenSize / canvSize;
	local screenOffset = hf.getGreater (sizeX,sizeY) - hf.getLesser (sizeX,sizeY);
	if sizeX < sizeY then
		return screenOffset * 0.5, 0, canvasScreenScale, canvasScreenScale;
	else
		return 0, screenOffset * 0.5, canvasScreenScale, canvasScreenScale;
	end
end

-- Physics
function hf.parabola (x,a,b,c)
	return (a * x * x) + (b * x) + c;
end

function hf.parabolaDerivative (x,a,b)
	return (2 * a * x) + b;
end

function hf.collideRect (posX1, posY1, posX2, posY2, sizeX, sizeY)
	local distX, distY = math.abs (posX1 - posX2), math.abs (posY1 - posY2); -- calculates the x&y distance
	return distX < sizeX and distY < sizeY; -- checks if the distance is less then the size
end

function hf.collideCircle (posX1, posY1, posX2, posY2, radius)
	return radius * radius > hf.distanceSqr (posX1 - posX2, posY1 - posY2);
end

-- animation --
-- returns a sprite index for a looping animation
function hf.animateLoop (t, length)
	t = t%length;
	return math.floor (t) + 1;
end

-- returns a sprite index for an animation that feezes at the end
function hf.animateStop (t, length)
	t = t + 1;
	if t > length then
		t = length
	end
	return math.floor(t);
end

-- returns the scaleX, scaleY of a sprite that is squished
function hf.squish (scale, t, am)
	local squishAm = t * am;
	return scale * (1 - squishAm), scale * (1 + squishAm);
end


-- Input --
-- takes in 2 keys, lesser lessens the return value, and greater increases it
-- returns a value between -1 and 1
function hf.inputDir (lesser, greater)
	local dir = 0; -- initializes dir
	if love.keyboard.isDown (lesser) then -- if the lesser key is down then reduce dir
		dir = -1;
	end
	if love.keyboard.isDown (greater) then -- if the greater key is down then increase dir
		dir = dir + 1;
	end

	return dir;
end



-- adds objects to a level based on a string
-- takes in the
-- world you want to populate,
-- the string you format from,
-- a table of functions that are executed on each charactor (world, posX, posY) (use these to call the creation functions),
-- element seperator says how mush to seperate the new objects

function hf.formatLevel (world, level, levelBuilder)
	local x,y = 0.5,0.5;
	for i = 1, #level do
		local c = string.sub(level,i,i);
		if c == "\n" and i ~= 1 then
			x, y = -0.5, y + 1;
		elseif c ~= " " then
			levelBuilder(world, c, x, y);
		end
		x = x + 1;
	end
end
--[[
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
--]]
return hf;

