package openmpt;

/**
	Known tracker module file extensions used by the library.
**/
enum abstract TrackerFormat(String) from String to String {
	final MOD = "mod";
	final XM = "xm";
	final IT = "it";
	final S3M = "s3m";

	/**
		Extensions that should be treated as tracker sound resources.
	**/
	public static final resourceExtensions:Array<TrackerFormat> = [MOD, XM, IT, S3M];

	/**
		Resolves a tracker format from a file extension.
	**/
	public static function fromExtension(extension:String):Null<TrackerFormat> {
		if (extension == null || extension.length == 0)
			return null;

		return switch (extension.toLowerCase()) {
			case MOD: MOD;
			case XM: XM;
			case IT: IT;
			case S3M: S3M;
			default: null;
		}
	}

	/**
		Resolves a tracker format from a file path.
	**/
	public static inline function fromPath(path:String):Null<TrackerFormat> {
		return fromExtension(haxe.io.Path.extension(path));
	}

	/**
		Returns `true` when the extension is recognized as a tracker module.
	**/
	public static inline function hasExtension(extension:String):Bool {
		return fromExtension(extension) != null;
	}

	/**
		Returns `true` when the file path points to a supported tracker module.
	**/
	public static inline function isTrackerPath(path:String):Bool {
		return fromPath(path) != null;
	}
}
