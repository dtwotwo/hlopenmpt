package openmpt;

import haxe.io.Bytes;

/**
	Decoded audio returned by libopenmpt.

	The `bytes` field contains interleaved PCM samples.
	Use `channels`, `sampleRate`, `samples`, and `floatFormat`
	to pass the data into your audio backend.
**/
typedef DecodedAudio = {
	bytes:Bytes,
	channels:Int,
	sampleRate:Int,
	samples:Int,
	floatFormat:Bool,
}

/**
	Selects the PCM format used when decoding tracker modules.

	- `PCM16` returns signed 16-bit interleaved PCM.
	- `PCMFloat` returns 32-bit float interleaved PCM.
**/
enum DecodeFormat {
	PCM16;
	PCMFloat;
}

/**
	Optional settings for tracker decoding.

	Set `loopSeconds` when you want a finite loop-aware preview buffer
	instead of decoding the module once through to the end.
**/
typedef DecodeOptions = {
	?format:DecodeFormat,
	?loopSeconds:Int,
}

/**
	High-level decoder helpers for tracker modules.

	These helpers can decode module bytes directly, load them from files,
	or create Heaps-compatible sound data.
**/
class OpenMPT {
	static inline function buildDecodedAudio(decoded:hl.Bytes, channels:Int, sampleRate:Int, samples:Int, floatFormat:Bool):DecodedAudio {
		return {
			bytes: @:privateAccess new Bytes(decoded, samples * channels * (floatFormat ? 4 : 2)),
			channels: channels,
			sampleRate: sampleRate,
			samples: samples,
			floatFormat: floatFormat,
		};
	}

	static inline function decodeRaw(bytes:Bytes, format:DecodeFormat, loopSeconds:Null<Int>):hl.Bytes {
		return switch ([format, loopSeconds]) {
			case [PCM16, null]: _decodeToPCM16(bytes, bytes.length);
			case [PCMFloat, null]: _decodeToPCMFloat(bytes, bytes.length);
			case [PCM16, seconds]: _decodeLoopToPCM16(bytes, bytes.length, seconds);
			case [PCMFloat, seconds]: _decodeLoopToPCMFloat(bytes, bytes.length, seconds);
		};
	}

	static inline function normalizeOptions(options:Null<DecodeOptions>):DecodeOptions {
		return options != null ? options : {};
	}

	static inline function readModuleFile(path:String):Null<Bytes> {
		if (path == null || path.length == 0)
			return null;
		if (!sys.FileSystem.exists(path))
			return null;
		return sys.io.File.getBytes(path);
	}

	/**
		Checks whether the provided bytes look like a supported tracker module.
	**/
	public static inline function probeModule(bytes:Bytes):Bool {
		if (bytes == null || bytes.length <= 0)
			return false;
		return _probeModule(bytes, bytes.length);
	}

	/**
		Decodes tracker bytes using the selected output format and options.

		Example:
		```haxe
		final decoded = openmpt.OpenMPT.decode(bytes, {
			format: PCMFloat,
			loopSeconds: 20,
		});
		```
	**/
	public static inline function decode(bytes:Bytes, ?options:DecodeOptions):Null<DecodedAudio> {
		if (bytes == null || bytes.length <= 0)
			return null;

		final resolved = normalizeOptions(options);
		final format = resolved.format != null ? resolved.format : PCM16;
		final decoded = decodeRaw(bytes, format, resolved.loopSeconds);
		if (decoded == null)
			return null;

		final channels = _decodedChannels();
		final sampleRate = _decodedSampleRate();
		final samples = _decodedSamples();
		return buildDecodedAudio(decoded, channels, sampleRate, samples, format == PCMFloat);
	}

	/**
		Loads a tracker module from disk and decodes it.
	**/
	public static inline function decodeFromFile(path:String, ?options:DecodeOptions):Null<DecodedAudio> {
		final bytes = readModuleFile(path);
		if (bytes == null)
			return null;
		return decode(bytes, options);
	}

	#if heaps
	/**
		Creates Heaps-compatible `OpenMPTData` from tracker bytes.
	**/
	public static inline function decodeToHeapsData(bytes:Bytes, ?loopSeconds:Int):hxd.snd.OpenMPTData {
		return new hxd.snd.OpenMPTData(bytes, loopSeconds);
	}

	/**
		Loads a tracker module from disk and creates Heaps-compatible sound data.
	**/
	public static inline function decodeToHeapsDataFromFile(path:String, ?loopSeconds:Int):hxd.snd.OpenMPTData {
		final bytes = readModuleFile(path);
		if (bytes == null)
			throw path == null || path.length == 0 ? "Invalid module path" : "Module file not found: " + path;
		return new hxd.snd.OpenMPTData(bytes, loopSeconds);
	}
	#end

	/**
		Decodes tracker bytes to float PCM.
	**/
	public static inline function decodeToPCMFloat(bytes:Bytes):Null<DecodedAudio> {
		return decode(bytes, {format: PCMFloat});
	}

	/**
		Decodes tracker bytes to 16-bit PCM.
	**/
	public static inline function decodeToPCM16(bytes:Bytes):Null<DecodedAudio> {
		return decode(bytes, {format: PCM16});
	}

	/**
		Decodes a loop-aware preview buffer to float PCM.
	**/
	public static inline function decodeLoopToPCMFloat(bytes:Bytes, seconds:Int):Null<DecodedAudio> {
		return decode(bytes, {format: PCMFloat, loopSeconds: seconds});
	}

	/**
		Decodes a loop-aware preview buffer to 16-bit PCM.
	**/
	public static inline function decodeLoopToPCM16(bytes:Bytes, seconds:Int):Null<DecodedAudio> {
		return decode(bytes, {format: PCM16, loopSeconds: seconds});
	}

	/**
		Returns the last error message reported by the native decoder.
	**/
	public static inline function describeLastError():String {
		return @:privateAccess String.fromUTF8(_describeLastError());
	}

	@:hlNative("openmpt", "probe_module")
	@:noCompletion
	static function _probeModule(bytes:hl.Bytes, size:Int):Bool {
		return false;
	}

	@:hlNative("openmpt", "decode_pcm_float")
	@:noCompletion
	static function _decodeToPCMFloat(bytes:hl.Bytes, size:Int):hl.Bytes {
		return null;
	}

	@:hlNative("openmpt", "decode_pcm_s16")
	@:noCompletion
	static function _decodeToPCM16(bytes:hl.Bytes, size:Int):hl.Bytes {
		return null;
	}

	@:hlNative("openmpt", "decode_loop_pcm_float")
	@:noCompletion
	static function _decodeLoopToPCMFloat(bytes:hl.Bytes, size:Int, seconds:Int):hl.Bytes {
		return null;
	}

	@:hlNative("openmpt", "decode_loop_pcm_s16")
	@:noCompletion
	static function _decodeLoopToPCM16(bytes:hl.Bytes, size:Int, seconds:Int):hl.Bytes {
		return null;
	}

	@:hlNative("openmpt", "decoded_channels")
	@:noCompletion
	static function _decodedChannels():Int {
		return 0;
	}

	@:hlNative("openmpt", "decoded_sample_rate")
	@:noCompletion
	static function _decodedSampleRate():Int {
		return 0;
	}

	@:hlNative("openmpt", "decoded_samples")
	@:noCompletion
	static function _decodedSamples():Int {
		return 0;
	}

	@:hlNative("openmpt", "describe_last_error")
	@:noCompletion
	static function _describeLastError():hl.Bytes {
		return null;
	}
}
