--[[
	StickerCodec
	Packs sticker records into a compact `buffer` for network replication.
	Thousands of stickers are sent as a few small chunks instead of thousands of Instances.

	Layout (30 bytes per sticker):
	  0  f32 x3   position
	  12 i16 x3   normal (scaled by 32767)
	  18 u8       spin around normal (0..255 -> 0..2pi)
	  19 u8       sticker type index (StickerConfig.Types[*].Index)
	  20 u16 x2   size X / size Z in centi-studs
	  24 u16      health * 100
	  26 u8       palette color index
	  27 u8       flags (1 = alive, 2 = circle, 4 = hard to reach)
	  28 u8       peel progress (0..255)
	  29 u8       layer (small normal offset to avoid z-fighting between overlapping stickers)
]]

local StickerCodec = {}

StickerCodec.RecordSize = 30

export type Record = {
	Id: number,
	Position: Vector3,
	Normal: Vector3,
	Spin: number,
	TypeIndex: number,
	SizeX: number,
	SizeZ: number,
	Health: number,
	ColorIndex: number,
	Alive: boolean,
	Circle: boolean,
	Hard: boolean,
	Progress: number,
	Layer: number,
}

local TAU = math.pi * 2

local function quantizeNormal(v: number): number
	return math.clamp(math.floor(v * 32767 + 0.5), -32767, 32767)
end

function StickerCodec.Encode(records: { Record }, first: number, last: number): buffer
	local count = last - first + 1
	local b = buffer.create(count * StickerCodec.RecordSize)
	for i = first, last do
		local r = records[i]
		local o = (i - first) * StickerCodec.RecordSize
		buffer.writef32(b, o, r.Position.X)
		buffer.writef32(b, o + 4, r.Position.Y)
		buffer.writef32(b, o + 8, r.Position.Z)
		buffer.writei16(b, o + 12, quantizeNormal(r.Normal.X))
		buffer.writei16(b, o + 14, quantizeNormal(r.Normal.Y))
		buffer.writei16(b, o + 16, quantizeNormal(r.Normal.Z))
		buffer.writeu8(b, o + 18, math.floor((r.Spin % TAU) / TAU * 255 + 0.5) % 256)
		buffer.writeu8(b, o + 19, r.TypeIndex)
		buffer.writeu16(b, o + 20, math.clamp(math.floor(r.SizeX * 100 + 0.5), 1, 65535))
		buffer.writeu16(b, o + 22, math.clamp(math.floor(r.SizeZ * 100 + 0.5), 1, 65535))
		buffer.writeu16(b, o + 24, math.clamp(math.floor(r.Health * 100 + 0.5), 1, 65535))
		buffer.writeu8(b, o + 26, r.ColorIndex)
		local flags = 0
		if r.Alive then
			flags += 1
		end
		if r.Circle then
			flags += 2
		end
		if r.Hard then
			flags += 4
		end
		buffer.writeu8(b, o + 27, flags)
		buffer.writeu8(b, o + 28, math.clamp(math.floor(r.Progress * 255 + 0.5), 0, 255))
		buffer.writeu8(b, o + 29, r.Layer % 256)
	end
	return b
end

function StickerCodec.Decode(b: buffer, firstId: number): { Record }
	local count = buffer.len(b) // StickerCodec.RecordSize
	local records = table.create(count)
	for i = 0, count - 1 do
		local o = i * StickerCodec.RecordSize
		local flags = buffer.readu8(b, o + 27)
		local normal = Vector3.new(
			buffer.readi16(b, o + 12) / 32767,
			buffer.readi16(b, o + 14) / 32767,
			buffer.readi16(b, o + 16) / 32767
		)
		records[i + 1] = {
			Id = firstId + i,
			Position = Vector3.new(buffer.readf32(b, o), buffer.readf32(b, o + 4), buffer.readf32(b, o + 8)),
			Normal = normal.Magnitude > 0.01 and normal.Unit or Vector3.yAxis,
			Spin = buffer.readu8(b, o + 18) / 255 * TAU,
			TypeIndex = buffer.readu8(b, o + 19),
			SizeX = buffer.readu16(b, o + 20) / 100,
			SizeZ = buffer.readu16(b, o + 22) / 100,
			Health = buffer.readu16(b, o + 24) / 100,
			ColorIndex = buffer.readu8(b, o + 26),
			Alive = bit32.band(flags, 1) ~= 0,
			Circle = bit32.band(flags, 2) ~= 0,
			Hard = bit32.band(flags, 4) ~= 0,
			Progress = buffer.readu8(b, o + 28) / 255,
			Layer = buffer.readu8(b, o + 29),
		}
	end
	return records
end

-- CFrame whose Y axis is the surface normal (sticker lies in the local XZ plane).
function StickerCodec.BuildCFrame(position: Vector3, normal: Vector3, spin: number): CFrame
	local up = normal.Unit
	local reference = if math.abs(up.Y) < 0.95 then Vector3.yAxis else Vector3.xAxis
	local right = reference:Cross(up).Unit
	return CFrame.fromMatrix(position, right, up) * CFrame.Angles(0, spin, 0)
end

return StickerCodec
