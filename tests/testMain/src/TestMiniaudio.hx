import haxe.io.Bytes;
import miniaudio.Miniaudio;
import miniaudio.Miniaudio.Buffer;
import miniaudio.Miniaudio.Sound;
import miniaudio.Miniaudio.SoundGroup;
import openmpt.OpenMPT;

private function main() {
	if (!Miniaudio.init()) {
		Sys.println("FAIL init: " + Miniaudio.describeLastError());
		Sys.exit(1);
	}

	var failed = false;
	final group = new SoundGroup();

	for (path in TestSupport.fixtures) {
		final label = TestSupport.fixtureLabel(path);
		try {
			final fixture = TestSupport.decodeFixture(path);
			TestSupport.printPlay(label);
			testPlayback(fixture.bytes, label, group);
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

	group.dispose();
	Miniaudio.uninit();

	if (failed)
		Sys.exit(1);

	Sys.println("Miniaudio tracker tests passed.");
}

private function testPlayback(sourceBytes:Bytes, label:String, group:SoundGroup):Void {
	final loopDecoded = OpenMPT.decodeLoopToPCMFloat(sourceBytes, 600);
	TestSupport.assert(loopDecoded != null, label + ": loop float decode failed: " + OpenMPT.describeLastError());

	final buffer = Buffer.fromPCMFloat(loopDecoded.bytes, loopDecoded.channels, loopDecoded.sampleRate);
	TestSupport.assert(buffer != null, label + ": fromPCMFloat failed: " + Miniaudio.describeLastError());

	final sound = new Sound(buffer, group);
	TestSupport.assert(sound != null, label + ": sound init failed: " + Miniaudio.describeLastError());
	TestSupport.assert(sound.start(), label + ": playback start failed");
	TestSupport.assert(waitUntil(() -> return sound.isPlaying(), 0.25), label + ": playback never started");

	final startCursor = sound.getCursorSamples();
	TestSupport.assert(waitUntil(() -> return sound.getCursorSamples() > startCursor, 0.5), label + ": playback cursor did not advance");

	finishPlayback(sound, loopDecoded, label);

	sound.dispose();
	buffer.dispose();
}

private function finishPlayback(sound:Sound, decoded:openmpt.DecodedAudio, label:String):Void {
	var lastCursor = sound.getCursorSamples();
	var lastProgressAt = haxe.Timer.stamp();

	while (true) {
		if (TestInput.pollSpace()) {
			sound.stop();
			waitUntil(() -> return !sound.isPlaying(), 0.25);
			return;
		}

		if (!sound.isPlaying())
			return;

		final cursor = sound.getCursorSamples();
		if (cursor > lastCursor) {
			lastCursor = cursor;
			lastProgressAt = haxe.Timer.stamp();
		} else if (haxe.Timer.stamp() - lastProgressAt > 0.5)
			throw label + " playback stalled at sample " + lastCursor + " of " + decoded.samples;

		Sys.sleep(0.01);
	}
}

private function testInvalidInput():Void {
	final invalid = Bytes.ofString("not tracker data");
	TestSupport.assert(!OpenMPT.probeModule(invalid), "invalid probe should return false");
	TestSupport.assert(OpenMPT.decodeToPCMFloat(invalid) == null, "invalid float decode should fail");
	TestSupport.assert(OpenMPT.describeLastError().length > 0, "invalid float decode should populate error");
	TestSupport.assert(OpenMPT.decodeToPCM16(invalid) == null, "invalid s16 decode should fail");
	TestSupport.assert(OpenMPT.describeLastError().length > 0, "invalid s16 decode should populate error");
}

private function testInvalidLoopDuration():Void {
	final fixture = TestSupport.fixtures[0];
	final bytes = sys.io.File.getBytes(fixture);
	TestSupport.assert(OpenMPT.decodeLoopToPCMFloat(bytes, 0) == null, "loop float decode should reject zero seconds");
	TestSupport.assertEquals("Loop decode duration must be greater than zero", OpenMPT.describeLastError(), "loop float decode should explain invalid duration");
	TestSupport.assert(OpenMPT.decodeLoopToPCM16(bytes, -1) == null, "loop s16 decode should reject negative seconds");
	TestSupport.assertEquals("Loop decode duration must be greater than zero", OpenMPT.describeLastError(), "loop s16 decode should explain invalid duration");
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
