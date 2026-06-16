## [Unreleased]

### Changed

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
