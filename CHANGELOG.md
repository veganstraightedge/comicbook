## [Unreleased]

### Fixed

- Mislabelled archives now open. A comic's type is told from the bytes the file starts with, so a RAR named `.cbz` (common in the wild) loads with `type == :cbr` and is read as one. ZIP, RAR, 7-Zip, TAR, PDF and ACE are recognized, by the new `ComicBook::Signature`. The extension still decides which files are comics at all (a `.zip` is refused as before) and is used when the contents are not recognized
- macOS metadata is no longer part of a comic. Archives made on a Mac can carry AppleDouble members (`._page1.jpg`, written by `tar` beside a file with extended attributes) or a `__MACOSX` folder (where Finder's Compress puts the same data). They were listed as files, counted as pages because their names end in an image extension, and extracted. All formats now leave them out of `files`, `pages` and `extract`, and a folder's `__MACOSX` is left out when it is archived. `ComicBook::Entry#macos_metadata?` is the check

### Changed

- CI runs on `ubuntu-24.04` instead of `ubuntu-latest`: on Ubuntu 26.04 the `seven-zip` gem crashed Ruby when reading an empty 7z
- CI retries a stalled package download instead of hanging, and installs from Ubuntu's main archive: installing `unar` and `libvips-dev` was stalling on the runner's regional mirror
- Bump Ruby version from 4.0.5 to 4.0.9 (`.ruby-version`, `required_ruby_version`, CI matrix)
- Brought `README.md`, `SYSTEM.md`, `AGENT.md` and `TODO.md` up to date: CBR, PDF, `.cb` folders, the CLI, `files`, and `contents:` are documented as they work today; finished roadmap items are removed

## [0.4.0] - 2026-06-18

### Added

- `contents:` option when archiving a folder — choose what goes into the archive: `:all` (default, every file), `:images` (images only), or `:images_and_info` (images plus `ComicInfo.xml` / `MetronInfo.xml`). Lets a comic be repackaged without dropping its metadata sidecars
- `ComicBook#files(type:)` — list a comic's files, filtered the same three ways, as `ComicBook::Entry` objects that answer `#image?` and `#info?`

### Changed

- Pages are now ordered by full entry path; archives previously ordered by basename (affects nested archives only)
- Bump Ruby version from 4.0.2 to 4.0.5 (`.ruby-version`, `required_ruby_version`, CI matrix)

## [0.3.0] - 2026-04-14

### Added

- PDF to comic book conversion (PDF → .cb → .cbz/.cb7/.cbt) with configurable DPI (default 300)
- PDF adapter with extract and pages support using libvips
- `ruby-vips` gem dependency (lazy-loaded, only required for PDF features)
- `ComicBook#info` method to read ComicInfo.xml metadata from archives and folders
- `comicinfo` gem dependency for ComicInfo.xml parsing
- `ComicBook::Info` alias for `ComicInfo::Issue`
- `comicbook info` CLI subcommand with `--format` (verbose, terse, json, yaml), `--only`, and `--except` options
- `--dpi` CLI option for PDF extraction
- `--version`/`-v` CLI flag
- Install `libvips-dev` in CI workflow

## [0.2.0] - 2025-11-17

### Added

- CBR extraction support using vendored `unar`/`lsar` binaries
- `--delete-original` CLI option for both extract and archive commands
- `--images-only` CLI option for extract command
- `images_only` option for Ruby API extraction
- `delete_original` option for Ruby API extraction and archiving
- CLI validation for unsupported archive output formats (CBR, CBA)

## [0.1.0] - 2025-10-26

### Added

- Initial release
- CBZ support (extract and archive)
- CB7 support (extract and archive)
- CBT support (extract and archive)
- CLI tool with `extract` and `archive` commands
- Ruby API with `ComicBook.extract`, `ComicBook.new().archive`, and `ComicBook.new().pages`
