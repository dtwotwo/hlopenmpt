import haxe.io.Bytes;
import openal.AL;
import openal.ALC;
import openmpt.OpenMPT;

private function main() {
	final device = ALC.openDevice(null);
	if (device == null) {
		Sys.println("FAIL init: could not open OpenAL device");
		Sys.exit(1);
	}

	final context = ALC.createContext(device, null);
	if (context == null || !ALC.makeContextCurrent(context)) {
		if (context != null)
			ALC.destroyContext(context);

		ALC.closeDevice(device);
		Sys.println("FAIL init: could not create OpenAL context");
		Sys.exit(1);
	}

	var failed = false;

	for (path in TestSupport.fixtures) {
		final label = TestSupport.fixtureLabel(path);
		try {
			final fixture = TestSupport.decodeFixture(path);
			TestSupport.printPlay(label);
			testPlayback(fixture.bytes, label);
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

	try {
		testInvalidLoopDuration();
		TestSupport.printOk("invalid-loop-duration");
	} catch (e) {
		failed = true;
		TestSupport.printFail("invalid-loop-duration", Std.string(e));
	}

	ALC.makeContextCurrent(null);
	ALC.destroyContext(context);
	ALC.closeDevice(device);

	if (failed)
		Sys.exit(1);

	Sys.println("OpenAL tracker tests passed.");
}

private function testPlayback(sourceBytes:Bytes, label:String):Void {
	final loopDecoded = OpenMPT.decodeLoopToPCM16(sourceBytes, 600);
	TestSupport.assert(loopDecoded != null, label + ": loop s16 decode failed: " + OpenMPT.describeLastError());

	final bufferIdBytes = Bytes.alloc(4);
	AL.genBuffers(1, @:privateAccess bufferIdBytes.b);

	final buffer:openal.Buffer = cast bufferIdBytes.getInt32(0);
	TestSupport.assert(AL.isBuffer(buffer), label + ": generated buffer is invalid");

	final sourceIdBytes = Bytes.alloc(4);
	AL.genSources(1, @:privateAccess sourceIdBytes.b);

	final source:openal.Source = cast sourceIdBytes.getInt32(0);
	TestSupport.assert(AL.isSource(source), label + ": generated source is invalid");

	final format = switch ([loopDecoded.channels, loopDecoded.floatFormat]) {
		case [1, false]: AL.FORMAT_MONO16;
		case [2, false]: AL.FORMAT_STEREO16;
		default: throw label + ": unsupported OpenAL buffer format";
	};

	AL.bufferData(buffer, format, @:privateAccess loopDecoded.bytes.b, loopDecoded.bytes.length, loopDecoded.sampleRate);
	TestSupport.assertEquals(AL.NO_ERROR, AL.getError(), label + ": bufferData failed");

	AL.sourcei(source, AL.BUFFER, cast buffer);
	AL.sourcePlay(source);

	TestSupport.assert(waitUntil(() -> return AL.getSourcei(source, AL.SOURCE_STATE) == AL.PLAYING, 0.25), label + ": source never entered playing state");
	TestSupport.assert(waitUntil(() -> return AL.getSourcei(source, AL.SAMPLE_OFFSET) > 0, 0.5), label + ": sample offset did not advance");
	finishPlayback(source, loopDecoded, label);

	AL.sourceStop(source);
	AL.deleteSources(1, @:privateAccess sourceIdBytes.b);
	AL.deleteBuffers(1, @:privateAccess bufferIdBytes.b);

	TestSupport.assertEquals(AL.NO_ERROR, AL.getError(), label + ": cleanup failed");
}

private function testInvalidInput():Void {
	final invalid = Bytes.ofString("not tracker data");
	TestSupport.assert(!OpenMPT.probeModule(invalid), "invalid probe should return false");
	TestSupport.assert(OpenMPT.decodeToPCM16(invalid) == null, "invalid s16 decode should fail");
	TestSupport.assert(OpenMPT.describeLastError().length > 0, "invalid decode should populate error");
}

private function testInvalidLoopDuration():Void {
	final fixture = TestSupport.fixtures[0];
	final bytes = sys.io.File.getBytes(fixture);
	TestSupport.assert(OpenMPT.decodeLoopToPCM16(bytes, 0) == null, "loop s16 decode should reject zero seconds");
	TestSupport.assertEquals("Loop decode duration must be greater than zero", OpenMPT.describeLastError(), "loop s16 decode should explain invalid duration");
	TestSupport.assert(OpenMPT.decodeLoopToPCMFloat(bytes, -1) == null, "loop float decode should reject negative seconds");
	TestSupport.assertEquals("Loop decode duration must be greater than zero", OpenMPT.describeLastError(), "loop float decode should explain invalid duration");
}

private function finishPlayback(source:openal.Source, decoded:openmpt.DecodedAudio, label:String):Void {
	var lastOffset = AL.getSourcei(source, AL.SAMPLE_OFFSET);
	var lastProgressAt = haxe.Timer.stamp();

	while (true) {
		if (TestInput.pollSpace()) {
			AL.sourceStop(source);
			return;
		}

		final state = AL.getSourcei(source, AL.SOURCE_STATE);
		if (state != AL.PLAYING)
			return;

		final offset = AL.getSourcei(source, AL.SAMPLE_OFFSET);
		if (offset != lastOffset) {
			lastOffset = offset;
			lastProgressAt = haxe.Timer.stamp();
		} else if (haxe.Timer.stamp() - lastProgressAt > 0.5)
			throw label + ": playback stalled at sample " + lastOffset + " of " + decoded.samples;

		Sys.sleep(0.01);
	}
}

private function waitUntil(check:Void->Bool, timeoutSeconds:Float):Bool {
	final deadline = haxe.Timer.stamp() + timeoutSeconds;
	while (haxe.Timer.stamp() < deadline) {
		if (check())
			return true;

		Sys.sleep(0.01);
	}

	return check();
}
