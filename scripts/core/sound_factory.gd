class_name SoundFactory
extends RefCounted

static func tone(frequency: float = 660.0, duration: float = 0.22, volume: float = 0.32) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for frame in frames:
		var envelope := 1.0 - float(frame) / float(frames)
		var wave := sin(TAU * frequency * float(frame) / float(rate))
		wave += sin(TAU * frequency * 1.5 * float(frame) / float(rate)) * 0.25
		var sample := int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
