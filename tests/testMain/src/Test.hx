import haxe.io.Bytes;
import openmpt.OpenMPT;

private function main() {
	var failed = false;

	for (path in TestSupport.fixtures) {
		final label = TestSupport.fixtureLabel(path);
		try {
			testFixture(path);
			TestSupport.printOk(label);
		} catch (e) {
			failed = true;
			TestSupport.printFail(label, Std.string(e));
		}
	}

	try {
		testInvalidInput();
		TestSupport.printOk("invalid");
	} catch (e) {
		failed = true;
		TestSupport.printFail("invalid", Std.string(e));
	}

	if (failed)
		Sys.exit(1);

	Sys.println("HL tracker tests passed.");
}

private function testFixture(path:String):Void {
	final bytes = sys.io.File.getBytes(path);
	final label = TestSupport.fixtureLabel(path);
	TestSupport.assert(OpenMPT.probeModule(bytes), label + ": probe failed");

	final floatDecoded = OpenMPT.decodeLoopToPCMFloat(bytes, 1);
	TestSupport.assert(floatDecoded != null, label + ": loop float decode failed: " + OpenMPT.describeLastError());
	TestSupport.assertDecodedAudio(floatDecoded, label, true);

	final pcm16Decoded = OpenMPT.decodeLoopToPCM16(bytes, 1);
	TestSupport.assert(pcm16Decoded != null, label + ": loop s16 decode failed: " + OpenMPT.describeLastError());
	TestSupport.assertDecodedAudio(pcm16Decoded, label, false);
}

private function testInvalidInput():Void {
	final invalid = Bytes.ofString("not tracker data");
	TestSupport.assert(!OpenMPT.probeModule(invalid), "invalid probe should return false");
	TestSupport.assert(OpenMPT.decodeToPCMFloat(invalid) == null, "invalid float decode should fail");
	TestSupport.assert(OpenMPT.describeLastError().length > 0, "invalid float decode should populate error");
	TestSupport.assert(OpenMPT.decodeToPCM16(invalid) == null, "invalid s16 decode should fail");
	TestSupport.assert(OpenMPT.describeLastError().length > 0, "invalid s16 decode should populate error");
}
