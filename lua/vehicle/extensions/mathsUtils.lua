-- NOTE: some functions, e.i. normalize, cross, dot and add, are
-- functions already supplied by BeamNG as vec3 methods, but have 
-- been left in to prevent refactoring the rotateVector function

M = {}
-- Helper function: Compute dot product of two vec3 vectors
local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

-- Helper function: Compute cross product of two vec3 vectors
local function cross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x
    }
end

-- Helper function: Normalize a vec3 to unit length
local function normalize(v)
    local len = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
    if len == 0 then return {x=0, y=0, z=0} end
    return {x = v.x/len, y = v.y/len, z = v.z/len}
end

-- Helper function: Multiply a vec3 by a scalar
local function mulScalar(v, s)
    return {x = v.x * s, y = v.y * s, z = v.z * s}
end

-- Helper function: Add two vec3 vectors
local function add(a, b)
    return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z}
end

-- Rotate a vector 'vec' using the direction vector 'axis_angle_vec'
-- (rotation axis = normalized direction vector, angle = vector magnitude)
local function rotateVector(vec, axis_angle_vec)
    -- Extract rotation angle from direction vector's magnitude
    local theta = math.sqrt(
        axis_angle_vec.x^2 +
        axis_angle_vec.y^2 +
        axis_angle_vec.z^2
    )

    -- If no rotation needed, return original vector
    if theta < 1e-6 then return vec3:setFromTable({x=vec.x, y=vec.y, z=vec.z}) end

    -- Normalize the rotation axis
    local k = normalize(axis_angle_vec)

    -- Precompute trigonometric terms
    local cos_theta = math.cos(theta)
    local sin_theta = math.sin(theta)

    -- Rodrigues' Rotation Formula components
    local term1 = mulScalar(vec, cos_theta)
    local term2 = mulScalar(cross(k, vec), sin_theta)
    local term3 = mulScalar(k, dot(k, vec) * (1 - cos_theta))

    -- Combine all terms
    local result = add(add(term1, term2), term3)
    return vec3:setFromTable(result)
end

M.mulScalar = mulScalar
M.add = add
M.rotateVector = rotateVector
return M
