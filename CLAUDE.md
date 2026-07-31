This is the HaxeFolio framework's own source repository, distributed as a haxelib library (see `haxelib.json`), with @README.md being its manual.

All source lives under `src/haxefolio` (`haxefolio` package and its subpackages), including the bundled `haxefolio.browser` utilities - small helpers wrapping browser/DOM APIs, independent of HaxeUI and of the rest of the framework. HaxeFolio is built over the `HaxeUI` library, and depends on the `morestd` haxelib for small, universal utilities (see `haxelib.json`'s `dependencies`).

The library is written in **Haxe**, targeting **HTML5**.

ANY AMBIGUITY OR MANUAL GAP SURFACING DURING IMPLEMENTATION SHOULD NOT BE RESOLVED SILENTLY. Instead, explicitly ask the question.

If told to take a dubious or possibly suboptimal approach (whether from the UI/UX or technical standpoint), also ask a question, providing details on why you're uncertain about this and what are the better practices or better ways to solve the problem.

To check whether the library compiles and test it, the sample project (located in @sample/, built via @sample/build.hxml) may be used.

# Code style conventions

See `code_style.md`.

# Dependencies

- `haxeui-core` / `haxeui-html5` - the UI library HaxeFolio is built over.
- `morestd` - small, universal utilities.

See `haxelib.json`'s `dependencies` for the authoritative list.
