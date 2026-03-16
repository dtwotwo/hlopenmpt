package hxd.snd;

import haxe.io.Bytes;

class OpenMPTData extends hxd.snd.Data {
	final rawData:Bytes;

	public function new(bytes:Bytes) {
		final decoded = openmpt.OpenMPT.decodeToPCM16(bytes);
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
