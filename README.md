# hlopenmpt

Native tracker module decoding for HashLink, with optional Heaps integration.

## What it does

- adds `openmpt.OpenMPT` for plain HashLink projects
- adds Heaps integration so tracker resources are treated as `hxd.res.Sound`

## Supported formats

- `mod`
- `xm`
- `it`
- `s3m`

more will be later...

## Plain HashLink usage

```haxe
final bytes = sys.io.File.getBytes("music.it");
final decoded = openmpt.OpenMPT.decodeToPCMFloat(bytes);

if (decoded == null)
	throw openmpt.OpenMPT.describeLastError();
```

There is also `decodeToPCM16()` if you want 16-bit PCM.

If you need a longer loop-aware preview buffer, use:

```haxe
final looped = openmpt.OpenMPT.decodeLoopToPCMFloat(bytes, 30);
```

## Heaps usage

If Heaps is present, tracker files are recognized as `hxd.res.Sound`, so you can use them like normal sound resources:

```haxe
final sound = hxd.Res.music;
final channel = sound.play();
```

This works for tracker resources such as `.it`, `.xm`, `.mod`, and `.s3m`.

## Build

`libopenmpt` is fetched automatically by CMake, so the repository does not need to vendor the full upstream source tree.

Requirements:

- CMake 3.10+
- Ninja
- MSVC build tools
- `HASHLINK` environment variable pointing to your HashLink folder

### Local build

The project includes a single Windows preset in `CMakePresets.json`.

```sh
cmake --preset release
cmake --build --preset release
```

If you use Visual Studio, opening the folder is enough - it uses the same CMake project and preset.

### Outputs

The native build produces:

- `openmpt.hdll`
- `openmpt.lib` on Windows

To run a HashLink app with `hlopenmpt`, place `openmpt.hdll` next to your `.hl` output, or otherwise make sure it is available in the current working directory / HashLink load path.

## Tests

- `tests\test-miniaudio.bat`
- `tests\test-openal.bat`
- `tests\test-heaps.bat`
- `tests\run-tests.bat`

## Notes

- `hlopenmpt` is meant to complement playback backends such as `hlopenal` or `hlminiaudio`
- Heaps integration is implemented through macros in `openmpt.Boot` / `openmpt.Macro`

## TODO

- Linux support
- macOS support
- proper streaming/player API instead of only decode-to-buffer helpers
