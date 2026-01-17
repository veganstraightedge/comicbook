## [Unreleased]

## [0.2.0] - 2025-01-17

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
