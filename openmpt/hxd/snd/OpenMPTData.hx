package hxd.snd;

import haxe.io.Bytes;

/**
	Heaps sound data implementation for tracker modules.

	This class decodes tracker bytes through `openmpt.OpenMPT`
	and exposes the result as regular `hxd.snd.Data`.
**/
class OpenMPTData extends hxd.snd.Data {
	final rawData:Bytes;

	/**
		Creates sound data from tracker bytes.

		When `loopSeconds` is provided, the data contains a finite loop-aware
		preview buffer instead of a single non-looped decode.
	**/
	public function new(bytes:Bytes, ?loopSeconds:Int) {
		final decoded = loopSeconds == null ? openmpt.OpenMPT.decodeToPCM16(bytes) : openmpt.OpenMPT.decodeLoopToPCM16(bytes, loopSeconds);
		if (decoded == null)
			throw openmpt.OpenMPT.describeLastError();

		rawData = decoded.bytes;
		channels = decoded.channels;
		samplingRate = decoded.sampleRate;
		samples = decoded.samples;
		sampleFormat = I16;
	}

	override function decodeBuffer(out:Bytes, outPos:Int, sampleStart:Int, sampleCount:Int):Void {
		final bytesPerSample = getBytesPerSample();
		out.blit(outPos, rawData, sampleStart * bytesPerSample, sampleCount * bytesPerSample);
	}
}
