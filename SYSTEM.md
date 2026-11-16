# ComicBook Ruby - System Documentation

## Overview

ComicBook is a Ruby library and CLI for reading, writing, and converting comic book archive files. It provides one interface over several formats: CB (folder), CBZ (ZIP), CB7 (7-Zip), CBT (TAR), CBR (RAR, extract only), and PDF (extract only). CBA (ACE) is recognised but not implemented.

## Project Structure

```
comicbook/
├── exe/
│   └── comicbook                # CLI executable
├── lib/
│   ├── comicbook.rb             # Main entry point and public API
│   └── comic_book/
│       ├── adapter.rb           # Base adapter class
│       ├── cli.rb               # CLI commands (extract, archive, info)
│       ├── cli_helpers.rb       # Runs the lsar / unar tools
│       ├── entry.rb             # One file inside a comic
│       ├── page.rb              # Page representation
│       ├── version.rb           # Version constant
│       ├── cb.rb                # CB (folder) adapter
│       ├── cb/
│       │   ├── archiver.rb
│       │   └── extractor.rb     # Always raises: a .cb folder is already extracted
│       ├── cb7.rb               # CB7 (7-Zip) adapter
│       ├── cb7/
│       │   ├── archiver.rb
│       │   └── extractor.rb
│       ├── cba.rb               # CBA (ACE) stub: every operation raises
│       ├── cbr.rb               # CBR (RAR) adapter
│       ├── cbr/
│       │   └── extractor.rb
│       ├── cbt.rb               # CBT (TAR) adapter
│       ├── cbt/
│       │   ├── archiver.rb
│       │   └── extractor.rb
│       ├── cbz.rb               # CBZ (ZIP) adapter
│       ├── cbz/
│       │   ├── archiver.rb
│       │   └── extractor.rb
│       ├── pdf.rb               # PDF adapter
│       ├── pdf/
│       │   └── extractor.rb     # Renders each PDF page to an image
│       └── vendor/              # lsar / unar binaries (macOS, Windows)
├── spec/                        # RSpec test suite
│   ├── fixtures/                # Test fixtures for all formats
│   └── comic_book/              # One spec per component
└── bin/                         # Development tools (setup, console)
```

## Architecture

### Core Design Patterns

#### 1. Adapter Pattern
Each format implements the interface defined by `ComicBook::Adapter`.

```ruby
class ComicBook::Adapter
  def archive(options = {})  # Create archive from folder
  def extract(options = {})  # Extract archive to folder
  def entries                # Every file in the comic, as Entry objects
  def info                   # ComicInfo::Issue from ComicInfo.xml, or nil
  def pages                  # Page objects (only PDF and CBA define this themselves)
  def images                 # entries that are images
  def images_and_info        # entries that are images or info files
end
```

#### 2. Strategy Pattern
The main `ComicBook` class picks the adapter from the detected type:

```ruby
def adapter
  case type
  when :cb7 then CB7.new path
  when :cba then CBA.new path
  when :cbr then CBR.new path
  when :cbt then CBT.new path
  when :cbz then CBZ.new path
  when :pdf then PDF.new path
  when :cb, :folder then CB.new path
  end
end
```

#### 3. Archiver / Extractor Classes
Each adapter delegates to an `Archiver` and an `Extractor` class that hold the format-specific work. Formats that cannot be written (CBR, PDF) have only an `Extractor`.

### Key Components

#### 1. ComicBook (Main Class)
- **Location**: `lib/comicbook.rb`
- **Purpose**: Public API entry point and file type detection
- **Responsibilities**:
  - Type detection: a folder is `:folder`, or `:cb` if its name ends in `.cb`; a file is typed by its extension
  - Path validation
  - Delegation to the adapter
  - `archive`, `extract`, `info`, `files(type:)`, `pages`
- `ComicBook::Info` is an alias of `ComicInfo::Issue`

#### 2. ComicBook::Adapter (Base Class)
- **Location**: `lib/comic_book/adapter.rb`
- **Purpose**: Abstract base class for all format adapters

#### 3. Format Adapters

**Main Adapter** (`cb.rb`, `cb7.rb`, `cbr.rb`, `cbt.rb`, `cbz.rb`, `pdf.rb`)
- Inherits from `ComicBook::Adapter`
- Delegates to Archiver/Extractor classes
- Implements `entries` and `info`

**Archiver Classes** (`*/archiver.rb`)
- Create an archive from a source folder
- Choose which files go in with the `contents` option

**Extractor Classes** (`*/extractor.rb`)
- Extract an archive to a folder
- Extract every file unless `images_only` is set

#### 4. ComicBook::Entry
- **Location**: `lib/comic_book/entry.rb`
- **Purpose**: One file inside a comic
- **Attributes**: `path` (relative path in a folder, or entry name in an archive), `name` (basename)
- **Predicates**: `image?`, `info?` (`ComicInfo.xml` or `MetronInfo.xml`)

#### 5. ComicBook::Page
- **Location**: `lib/comic_book/page.rb`
- **Purpose**: One page image of a comic
- **Attributes**: `path`, `name`

#### 6. ComicBook::CLI
- **Location**: `lib/comic_book/cli.rb`, run by `exe/comicbook`
- **Commands**: `extract`, `archive`, `info`

### File Type Support

| Format | Extension    | Archive               | Extract                     | Info            | Dependencies              |
|--------|--------------|-----------------------|-----------------------------|-----------------|---------------------------|
| CB     | `.cb` folder | ✅                    | n/a (already a folder)      | ✅              | Ruby stdlib               |
| CBZ    | `.cbz`       | ✅                    | ✅                          | ✅              | `rubyzip` gem             |
| CB7    | `.cb7`       | ✅                    | ✅                          | ✅              | `seven-zip` gem           |
| CBT    | `.cbt`       | ✅                    | ✅                          | ✅              | Ruby stdlib               |
| CBR    | `.cbr`       | ❌ RAR is proprietary | ✅                          | ✅              | `lsar` / `unar`           |
| PDF    | `.pdf`       | ❌                    | ✅ pages rendered to images | ❌ always `nil` | `ruby-vips` gem + libvips |
| CBA    | `.cba`       | ❌ ACE is proprietary | 🚧 Planned                  | 🚧 Planned      | TBD                       |

`lsar` and `unar` are vendored for macOS and Windows in `lib/comic_book/vendor/`. On Linux they must be installed on the system (`unar` package).

### Data Flow

#### Archive Creation Flow
1. User calls `ComicBook.new(folder_path).archive`
2. Main class checks the path is a folder (or `.cb` folder)
3. The extension of the `to:` option picks the adapter (`.cbz` by default)
4. The adapter's Archiver lists the folder's files, filtered by `contents`
5. Creates the archive
6. Returns the path of the created archive

#### Archive Extraction Flow
1. User calls `ComicBook.new(archive_path).extract`
2. Main class detects file type by extension
3. Delegates to the adapter's Extractor
4. Extracts every file (only images if `images_only` is set) to the destination folder
5. Returns the path of the extracted folder

For a PDF, step 4 renders each page to an image at the `dpi` option's resolution.

#### Page Reading Flow
1. User calls `ComicBook.new(archive_path).pages`
2. Main class asks the adapter for its entries
3. Keeps the image files, sorted by path
4. Returns an array of Page objects

## Configuration & Constants

```ruby
IMAGE_EXTENSIONS   = %w[.jpg .jpeg .png .gif .bmp .webp].freeze
IMAGE_GLOB_PATTERN = '*.{jpg,jpeg,png,gif,bmp,webp}'.freeze
INFO_FILENAMES     = %w[ComicInfo.xml MetronInfo.xml].freeze
```

### Options Support

Archive options:
- `to`: Output path; its extension picks the format (default `.cbz` next to the source folder)
- `contents`: `:all` (default), `:images`, or `:images_and_info`
- `extension`: File extension for the default output path
- `delete_original`: Remove the source folder afterwards

Extract options:
- `to`: Destination folder (default: a `.cb` folder next to the archive)
- `images_only`: Extract only image files
- `extension`: Folder extension for the default destination
- `delete_original`: Remove the source archive afterwards
- `dpi`: PDF render resolution (default 300)

## Dependencies

### Runtime Dependencies
- **comicinfo** (>= 2.0): Reads `ComicInfo.xml`
- **rubyzip** (>= 3.4.0): ZIP file handling for CBZ format
- **seven-zip** (~> 1.4): 7-Zip handling for CB7 format
- **ruby-vips** (>= 2.3): PDF rendering; loaded only when a PDF is used, and needs libvips on the system
- Ruby stdlib: TAR handling for CBT format
- `lsar` / `unar`: RAR handling for CBR format (vendored for macOS and Windows)

### Development Dependencies
- **rspec**: Testing framework
- **rspec-file_fixtures**: Fixture management for tests
- **rubocop** (with `rubocop-performance`, `rubocop-rake`, `rubocop-rspec`): Code linting and style enforcement

## Testing Strategy

### Test Organization
- **Unit Tests**: Individual component testing
- **Integration Tests**: End-to-end format operations
- **Fixture-Based**: Real archive files for accurate testing

### TmpDir Pattern
All tests use `Dir.mktmpdir` for file I/O operations to ensure:
- No files created in repository root
- Proper cleanup after each test
- Isolation between test runs

## Error Handling

```ruby
ComicBook::Error < StandardError
```

### Common Error Cases
- Unsupported file types
- Path does not exist
- Archiving a file, or extracting a folder
- Archiving to CBR, CBA, or PDF
- Any CBA operation (not yet implemented)
- `lsar` / `unar` failing or missing
- libvips missing when a PDF is used

## Adding New Formats

1. Create new adapter class inheriting from `ComicBook::Adapter`
2. Implement archiver and extractor classes
3. Add format detection to main `ComicBook` class
4. Add specs following existing patterns

## Version Information
- **Version**: see `lib/comic_book/version.rb`
- **Ruby Requirement**: >= 4.0.9
- **License**: MIT
