package openmpt;

import haxe.io.Bytes;

typedef DecodedAudio = {
	bytes:Bytes,
	channels:Int,
	sampleRate:Int,
	samples:Int,
	floatFormat:Bool,
}

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

	public static inline function probeModule(bytes:Bytes):Bool {
		return _probeModule(bytes, bytes.length);
	}

	public static inline function decodeToPCMFloat(bytes:Bytes):Null<DecodedAudio> {
		final decoded = _decodeToPCMFloat(bytes, bytes.length);
		if (decoded == null)
			return null;

		final channels = _decodedChannels();
		final sampleRate = _decodedSampleRate();
		final samples = _decodedSamples();
		return buildDecodedAudio(decoded, channels, sampleRate, samples, true);
	}

	public static inline function decodeToPCM16(bytes:Bytes):Null<DecodedAudio> {
		final decoded = _decodeToPCM16(bytes, bytes.length);
		if (decoded == null)
			return null;

		final channels = _decodedChannels();
		final sampleRate = _decodedSampleRate();
		final samples = _decodedSamples();
		return buildDecodedAudio(decoded, channels, sampleRate, samples, false);
	}

	public static inline function decodeLoopToPCMFloat(bytes:Bytes, seconds:Int):Null<DecodedAudio> {
		final decoded = _decodeLoopToPCMFloat(bytes, bytes.length, seconds);
		if (decoded == null)
			return null;

		final channels = _decodedChannels();
		final sampleRate = _decodedSampleRate();
		final samples = _decodedSamples();
		return buildDecodedAudio(decoded, channels, sampleRate, samples, true);
	}

	public static inline function decodeLoopToPCM16(bytes:Bytes, seconds:Int):Null<DecodedAudio> {
		final decoded = _decodeLoopToPCM16(bytes, bytes.length, seconds);
		if (decoded == null)
			return null;

		final channels = _decodedChannels();
		final sampleRate = _decodedSampleRate();
		final samples = _decodedSamples();
		return buildDecodedAudio(decoded, channels, sampleRate, samples, false);
	}

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
