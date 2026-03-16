final class HeapsSmokeTest extends hxd.App {
	var channel:hxd.snd.Channel;
	var currentSound:hxd.res.Sound;
	var currentLabel = "test.xm";
	var startPos = 0.0;
	var started = false;
	var startupTime = 0.0;
	var skipArmed = false;

	override function init() {
		if (!sys.FileSystem.exists("trackers/" + currentLabel))
			fail("Missing test file: trackers/" + currentLabel);

		playCurrent();
	}

	private function playCurrent():Void {
		final sound:hxd.res.Sound = hxd.Res.test;
		currentSound = sound;
		if (currentSound == null)
			fail(currentLabel + ": failed to load Heaps resource");

		final data = @:privateAccess currentSound.getData();
		if (data == null)
			fail(currentLabel + ": getData() returned null");

		final dataClass = Type.getClassName(Type.getClass(data));
		if (dataClass != "hxd.snd.OpenMPTData")
			fail(currentLabel + ": expected hxd.snd.OpenMPTData, got " + dataClass);

		if (data.samples <= 0)
			fail(currentLabel + ": decoded sample count is zero");

		if (data.channels <= 0)
			fail(currentLabel + ": decoded channel count is zero");

		Sys.println("PLAY " + currentLabel + " [space = stop]");
		Sys.println("[Heaps] sound=" + Type.getClassName(Type.getClass(currentSound)));
		Sys.println("[Heaps] data=" + dataClass);
		Sys.println("[Heaps] rate=" + data.samplingRate + " channels=" + data.channels + " samples=" + data.samples);

		channel = currentSound.play(false, 1);
		if (channel == null)
			fail(currentLabel + ": sound.play() returned null");

		channel.onEnd = () -> {
			if (!started)
				fail(currentLabel + ": playback ended before position advanced");

			Sys.println("OK   " + currentLabel);
			Sys.println("Heaps tracker tests passed.");
			Sys.exit(0);
		};

		startPos = channel.position;
		started = false;
		startupTime = 0.0;
		skipArmed = false;
	}

	override function update(dt:Float) {
		startupTime += dt;

		if (channel == null)
			return;

		if (!started && channel.position > startPos)
			started = true;

		if (!started && startupTime > 2.0)
			fail(currentLabel + ": playback position did not advance");

		if (started && channel.position < 0)
			fail(currentLabel + ": playback position became invalid");

		if (!skipArmed) {
			if (!hxd.Key.isDown(hxd.Key.SPACE))
				skipArmed = true;

			return;
		}

		if (hxd.Key.isPressed(hxd.Key.SPACE)) {
			channel.stop();
			Sys.println("STOP " + currentLabel);
			Sys.println("Heaps tracker tests passed.");
			Sys.exit(0);
		}
	}

	private function fail(message:String):Void {
		Sys.println("FAIL " + message);
		Sys.exit(1);
	}

	static function main() {
		hxd.Res.initLocal();
		new HeapsSmokeTest();
	}
}
