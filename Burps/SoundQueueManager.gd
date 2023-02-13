extends Node

class_name SoundQueueManager


static func create_sound_event(position: float, sound_file_index: int, pitch: float, pan: float, low_cut: float, high_cut: float):
	var s = SoundEvent.new()
	s.position = position
	s.sounds_idx = sound_file_index
	s.pan = pan
	s.pitch = pitch
	s.low_cut = low_cut
	s.high_cut = high_cut
	return s

class SoundEvent:
	var position : float
	var sounds_idx : int
	var pan : float
	var pitch : float
	var low_cut : float
	var high_cut : float

	func _to_string():
		return "<@%s: %s pan:%s pitch:%s cutoff:%s-%s" % [
			position, sounds_idx, pan, pitch, low_cut, high_cut
		]

# TODO:
# * Clean up UI
#   * Change canvas size to a portrait mobile ratio
#   * Try using layout elements for arranging UI elements
# * Add FX Chorus
# * Add FX Delay
# * Add FX BandPass
# * Add FX Reverb
# * Add FX Stereo Enhance
# * Add FX Compressor
# * Add FX Phaser
# * Add FX Distortion



enum FX { PAN, LOW_PASS, HIGH_PASS, EQ6 }


export(Array, AudioStreamSample) var sounds : Array
var number_sounds = 0
var audioPlayers : Array
var NUM_BUSES = 16

var is_processing_queue : bool = false
var playback_started_at : float
var playback_next_sound : int
var queue : Array = []


signal queue_changed(new_size)


# Interface

func play(sound_event: SoundEvent):
	var sample = sounds[sound_event.sounds_idx]
	var player = _get_idle_player()
	player.set_sound_parameters(sound_event, sample)
	player.stream_player.play()


func queue_sound(sound_event: SoundEvent):
	_insert_sorted(sound_event)
	emit_signal("queue_changed", queue.size())


func play_queue():
	if is_processing_queue:
		return

	is_processing_queue = true
	print("Queue:")
	for event in queue:
		print(event)
	playback_started_at = Time.get_ticks_usec()
	playback_next_sound = 0
	# Optional: Start playing sounds with start == 0.0 (or <= 33.3ms?)


func get_last_sound_timing():
	if queue.size() == 0:
		return {
			"begin": 0.0,
			"length": 0.0
		}
	else:
		var last = queue[-1] as SoundEvent
		var last_sample = sounds[last.sounds_idx] as AudioStreamSample
		var last_length = last_sample.get_length()
		return {
			"begin": last.position,
			"length": last_length
		}


func reset_queue():
	queue.clear()
	emit_signal("queue_changed", queue.size())


# Engine hooks

# Called when the node enters the scene tree for the first time.
func _ready():
	number_sounds = sounds.size()
	for _i in range(NUM_BUSES):
		var audioPlayer = AudioPlayer.new()
		audioPlayers.append(audioPlayer)
		add_child(audioPlayer.stream_player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if is_processing_queue:
		while playback_next_sound < queue.size():
			var next = queue[playback_next_sound]
			var next_start = playback_started_at + round(next.position * 1000000)
			if next_start <= Time.get_ticks_usec():
				play(next)
				playback_next_sound += 1
			else:
				return
		is_processing_queue = false


# Private utility functions

func _insert_sorted(sound_event: SoundEvent):
	var insert_at = _find_sound_idx_to_insert(sound_event.position)
	queue.insert(insert_at, sound_event)
		

func _find_sound_idx_to_insert(position: float):
	var idx_leq = -1
	for sound_idx in range(queue.size()):
		if queue[sound_idx].position <= position:
			idx_leq = sound_idx
		elif queue[sound_idx].position > position:
			break
	return idx_leq + 1


func _get_idle_player() -> AudioPlayer:
	for player in audioPlayers:
		var p = player as AudioPlayer
		if p.is_idle():
			return player
	return null  # TODO: Error handling (dynamically adding extra audioPlayers? logging?)


class AudioPlayer:
	var stream_player : AudioStreamPlayer
	var bus_index : int
	var bus : String

	func _init():
		bus_index = AudioServer.bus_count
		bus = "PlayerBus%03d" % bus_index
		AudioServer.add_bus(bus_index)
		AudioServer.set_bus_name(bus_index, bus)

		stream_player = AudioStreamPlayer.new()
		stream_player.bus = bus

		_init_fx()
	
	func _init_fx():
		AudioServer.add_bus_effect(bus_index, AudioEffectPanner.new(), FX.PAN)
		AudioServer.add_bus_effect(bus_index, AudioEffectLowPassFilter.new(), FX.LOW_PASS)
		AudioServer.add_bus_effect(bus_index, AudioEffectHighPassFilter.new(), FX.HIGH_PASS)
		# AudioServer.add_bus_effect(bus_index, AudioEffectEQ6.new(), FX.EQ6)
		reset_fx()
	
	func set_sound_parameters(s: SoundEvent, sample: AudioStreamSample):
		reset_fx()
		stream_player.stream = sample
		stream_player.pitch_scale = s.pitch
		set_pan(s.pan)
		if s.high_cut <= 20_000.0:
			set_high_cut_cutoff(s.high_cut)
		if s.low_cut >= 20.0:
			set_low_cut_cutoff(s.low_cut)
	

	func reset_fx():
		_set_fx_enabled(FX.LOW_PASS, false)
		_set_fx_enabled(FX.HIGH_PASS, false)
		# _set_fx_enabled(FX.EQ6, false)
	
	func _set_fx_enabled(fx: int, enabled: bool):
		AudioServer.set_bus_effect_enabled(bus_index, fx, enabled)
	
	func is_idle():
		return not stream_player.playing
	
	func set_pan(pan: float):
		var panner = AudioServer.get_bus_effect(bus_index, FX.PAN) as AudioEffectPanner
		panner.pan = pan
	
	func set_high_cut_cutoff(cutoff: float):
		var low_pass = AudioServer.get_bus_effect(bus_index, FX.LOW_PASS) as AudioEffectLowPassFilter
		low_pass.cutoff_hz = cutoff
		_set_fx_enabled(FX.LOW_PASS, true)

	func set_low_cut_cutoff(cutoff: float):
		var high_pass = AudioServer.get_bus_effect(bus_index, FX.HIGH_PASS) as AudioEffectHighPassFilter
		high_pass.cutoff_hz = cutoff
		_set_fx_enabled(FX.HIGH_PASS, true)
