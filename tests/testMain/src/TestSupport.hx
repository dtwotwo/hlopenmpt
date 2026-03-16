import haxe.io.Bytes;
import haxe.io.Path;
import openmpt.OpenMPT;
import sys.FileSystem;

typedef FixtureDecode = {
	path:String,
	bytes:Bytes,
	floatDecoded:openmpt.DecodedAudio,
	pcm16Decoded:openmpt.DecodedAudio,
}

class TestSupport {
	public static final supportedExtensions = openmpt.Formats.resourceExtensions;
	public static final fixtures = loadFixtures();

	static function loadFixtures():Array<String> {
		final baseDir = "trackers";
		final result:Array<String> = [];

		for (name in FileSystem.readDirectory(baseDir)) {
			final path = baseDir + "/" + name;
			if (FileSystem.isDirectory(path))
				continue;
			final ext = Path.extension(name).toLowerCase();
			if (supportedExtensions.indexOf(ext) != -1)
				result.push(path);
		}

		result.sort(Reflect.compare);
		assert(result.length > 0, "No tracker fixtures found in " + baseDir);
		return result;
	}

	public static function fixtureLabel(path:String):String {
		return Path.withoutDirectory(path);
	}

	public static function assert(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	public static function assertEquals<T>(expected:T, actual:T, message:String):Void {
		if (expected != actual)
			throw '$message (expected=$expected, actual=$actual)';
	}

	public static function decodeFixture(path:String):FixtureDecode {
		final bytes = sys.io.File.getBytes(path);
		assert(OpenMPT.probeModule(bytes), fixtureLabel(path) + ": probe failed");

		final floatDecoded = OpenMPT.decodeToPCMFloat(bytes);
		assert(floatDecoded != null, fixtureLabel(path) + ": float decode failed: " + OpenMPT.describeLastError());
		assertDecodedAudio(floatDecoded, fixtureLabel(path), true);

		final pcm16Decoded = OpenMPT.decodeToPCM16(bytes);
		assert(pcm16Decoded != null, fixtureLabel(path) + ": s16 decode failed: " + OpenMPT.describeLastError());
		assertDecodedAudio(pcm16Decoded, fixtureLabel(path), false);

		assertEquals(floatDecoded.channels, pcm16Decoded.channels, fixtureLabel(path) + ": channel mismatch between decode paths");
		assertEquals(floatDecoded.sampleRate, pcm16Decoded.sampleRate, fixtureLabel(path) + ": sample rate mismatch between decode paths");
		assertEquals(floatDecoded.samples, pcm16Decoded.samples, fixtureLabel(path) + ": sample count mismatch between decode paths");

		return {
			path: path,
			bytes: bytes,
			floatDecoded: floatDecoded,
			pcm16Decoded: pcm16Decoded,
		};
	}

	public static function assertDecodedAudio(decoded:openmpt.DecodedAudio, label:String, floatFormat:Bool):Void {
		assert(decoded.channels > 0, label + ": invalid channel count");
		assert(decoded.sampleRate > 0, label + ": invalid sample rate");
		assert(decoded.samples > 0, label + ": invalid sample count");
		assertEquals(floatFormat, decoded.floatFormat, label + ": unexpected format flag");
		final bytesPerSample = floatFormat ? 4 : 2;
		assertEquals(decoded.samples * decoded.channels * bytesPerSample, decoded.bytes.length, label + ": unexpected decoded byte count");
	}

	public static function printPlay(label:String):Void {
		Sys.println("PLAY " + label + " [space = skip]");
	}

	public static function printOk(label:String):Void {
		Sys.println("OK   " + label);
	}

	public static function printFail(label:String, message:String):Void {
		Sys.println("FAIL " + label + ": " + message);
	}
}
