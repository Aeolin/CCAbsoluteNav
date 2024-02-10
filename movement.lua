Direction = {North = 0, East = 1, South = 2, West = 3, Up = 4, Down = 5, UNKNOWN = 6}
Movement = {homepos = nil, position = nil, direction = Direction.UNKNOWN}
Rotatation = {Clockwise = true, CounterClockwise = false, CW = true, CCW = false}
Dir2Vec = {
    [Direction.North] = vector.new(0, 0, -1),
    [Direction.East] = vector.new(1, 0, 0),
    [Direction.South] = vector.new(0, 0, 1),
    [Direction.West] = vector.new(-1, 0, 0),
    [Direction.Up] = vector.new(0, 1, 0),
    [Direction.Down] = vector.new(0, -1, 0),
    [Direction.UNKNOWN] = vector.new(0, 0, 0)
}

function copyVec(vec)
    return vector.new(vec.v, vec.y, vec.z)
end

function Movement:init()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.homepos = vector.new(gps.locate(10))
    self.position = copyVec(self.homepos)
    return o   
end

function Direction.getOpposing(face)
    return (face + 2) % 4
end

function Direction.nextCW(face)
    return (face + 1) % 4
end

function  Direction.nextCCW(face)
    return (face - 1) % 4
end

function Direction.distanceCW(from, to)
    return (to - from) % 4
end

function Direction.distanceCCW(from, to)
    return (from - to) % 4
end

function Movement.checkFuel()
    if turtle.getFuelLevel() == 0 then
        turtle.refuel(1)
    end
end

function Movement:move(dir, count)
    if count <= 0 then
        return
    end

    if dir == Direction.Down then
        for i = 1, count, 1 do
            Movement.checkFuel()
            turtle.down()
            self.position.y = self.position.y - 1
        end
    elseif dir == Direction.Up then
        for i = 1, count, 1 do
            Movement.checkFuel()
            turtle.up()
            self.position.y = self.position.y + 1
        end
    elseif dir ~= Direction.UNKNOWN then
        self:rotateTo(dir)
        for i = 1, count, 1 do
            Movement.checkFuel()
            turtle.forward()
            self.position = self.position + Dir2Vec[dir]
        end
    end
end

function Direction.getMovementComponentsOfDiff(diff)
    local x = (diff.x > 0) and Direction.East or Direction.West
    local y = (diff.y > 0) and Direction.Up or Direction.Down
    local z = (diff.z > 0) and Direction.South or Direction.North
    return x, y, z 
end

function Movement:moveTo(target)
    local diff = target - self.position
    local x, y, z = Direction.getMovementComponentsOfDiff(diff)
    self:move(x, math.abs(diff.x))
    self:move(y, math.abs(diff.y))
    self:move(z, math.abs(diff.z))
end

function Movement:rotateCW(count)
    for i = 1, count%4, 1 do
        turtle.turnRight()
        self.direction = Direction.nextCW(self.direction)
    end
end

function Movement:rotateCCW(count)
    for i = 1, count%4, 1 do
        turtle.turnLeft()
        self.direction = Direction.nextCCW(self.direction)
    end
end

function Movement:rotate(count, cw)
    if cw then
        self.rotateCW(self, count)
    else
        self:rotateCCW(count)
    end
end

function Direction.shortestRotationDist(from, to)
    local diffCW = Direction.distanceCW(from, to)
    local diffCCW = Direction.distanceCCW(from, to)
    if diffCW < diffCCW then
        return diffCW, Rotatation.Clockwise
    else
        return diffCCW, Rotatation.CounterClockwise
    end
end

function Movement:rotateTo(dir)
    if dir == self.direction then
        return
    else
        local diff, dir = Direction.shortestRotationDist(self.direction, dir)
        self:rotate(diff, dir)
    end
end

function Direction.ofVectorDiff(from, to)
    local diff = from - to
    if diff.x > 0 then
        return Direction.West
    elseif diff.x < 0 then
        return Direction.East
    elseif diff.z > 0 then
        return Direction.North    
    elseif diff.z < 0 then
        return Direction.South
    else
        return Direction.UNKNOWN
    end
end

function Movement:calibrate()
    local rotation = 0
    self.position = vector.new(gps.locate(10))
    for i=Direction.North, Direction.West, 1 do
        if turtle.detect() == false then
            turtle.forward()
            local current =  vector.new(gps.locate(10))
            self.direction = Direction.ofVectorDiff(self.position, current)
            turtle.back()
            self:rotateCCW(rotation)
            return true
        else
            turtle.turnRight()
            rotation = rotation + 1
        end
    end
    
    self.direction = Direction.UNKNOWN
    turtle.turnRight()
    return false 
end