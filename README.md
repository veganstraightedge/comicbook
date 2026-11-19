# ComicBook

A Ruby library and CLI tool for managing comic books archives.

- `extract`: to open a `.cb*` file
- `archive`: to create a `.cb*` file
- `info`: to read `ComicInfo.xml` metadata from a `.cb*` file
- `pages`: to list page image files in a `.cb*` file (Ruby API only)
- `arrange_pages`: to reorder, delete, and add pages of an extracted comic (Ruby API only)

---

Support for `archive` and `extract` :

- `CB`: a folder of images, an optional `ComicInfo.xml` metadata file
- `CB7`: [7zip](https://en.wikipedia.org/wiki/7-Zip)
- `CBT`: [Tar](<https://en.wikipedia.org/wiki/Tar_(computing)>)
- `CBZ`: [Zip](<https://en.wikipedia.org/wiki/ZIP_(file_format)>) **default**

Support for only `extract`:

- `CBR`: [RAR](https://en.wikipedia.org/wiki/WinRAR) is proprietary without an open source implementation license.
  Uses the `lsar` / `unar` tools: bundled for macOS and Windows, on Linux install the `unar` package.
  Extracting support because a large number of comic books are archived in .cbr/.rar format.
  No support for creating `.cbr` files will ever be added unless `RAR` is open source (or reverse engineered).
- `PDF`: Convert a PDF to a `.cb*` archive using [libvips](https://www.libvips.org) . Requires `libvips` installed on the system.

A comic's type comes from what the file contains, not its name, so a mislabelled archive still opens: a RAR named `.cbz` is read as a CBR.
The name still decides which files are comics at all (a `.zip` is refused).

Files that macOS adds to archives it makes (`._page1.jpg`, a `__MACOSX` folder) are never listed, counted as pages, or extracted.

Not supported yet:

- `CBA`: [ACE](https://en.wikipedia.org/wiki/WinAce) is both proprietary and very old/outdated/unsupported.
  ACE extracting support is planned, to support historical posterity and completeness.
  **NEEDED: actual `.cba` files** to test against (with and without `ComicInfo.xml`).

## Installation

Install the gem and add to the application's Gemfile by executing:

```sh
bundle add comicbook
```

If bundler is not being used to manage dependencies, install the gem by executing:

```sh
gem install comicbook
```

## Usage

### CLI

```sh
# Extract a comic book archive
comicbook extract path/to/archive.cbz

# Extract to a specific destination
comicbook extract path/to/archive.cbz --to path/to/output

# Extract only image files (exclude metadata like ComicInfo.xml)
comicbook extract path/to/archive.cbz --images-only

# Extract PDF at custom DPI (default: 300)
comicbook extract path/to/comic.pdf --dpi 600

# Delete the source after extracting (or archiving)
comicbook extract path/to/archive.cbz --delete-original

# Create a comic book archive from a folder
comicbook archive path/to/folder

# Create archive at a specific destination (the extension picks the format: .cbz, .cb7, .cbt, .cb)
comicbook archive path/to/folder --to path/to/output.cb7

# Show ComicInfo.xml metadata
comicbook info path/to/archive.cbz

# Show info in different formats
comicbook info path/to/archive.cbz --format json
comicbook info path/to/archive.cbz --format yaml
comicbook info path/to/archive.cbz --format terse
comicbook info path/to/archive.cbz --format verbose # default

# Show only specific fields
comicbook info path/to/archive.cbz --only title,writer,publisher

# Show all fields except specific ones
comicbook info path/to/archive.cbz --except summary,review

# Show help or version
comicbook --help
comicbook --version
```

### Ruby API

```ruby
# Extract a comic book archive (extracts all files by default)
ComicBook.extract 'path/to/archive.cbz'

# Extract to a specific destination
ComicBook.extract 'path/to/archive.cbz', to: 'path/to/output'

# Extract only image files (exclude metadata like ComicInfo.xml)
ComicBook.extract 'path/to/archive.cbz', images_only: true

# Create a comic book archive from a folder (creates .cbz by default)
ComicBook.new('path/to/folder').archive

# Create archive at a specific destination (the extension picks the format)
ComicBook.new('path/to/folder').archive to: 'path/to/output.cbz'

# Choose what goes into the archive: :all (default), :images, or :images_and_info
ComicBook.new('path/to/folder').archive contents: :images_and_info

# Get pages from an archive
comic = ComicBook.new 'path/to/archive.cbz'
comic.pages  # => [#<ComicBook::Page>, ...]

# List files in an archive: :all (default), :images, or :images_and_info
comic.files                # => [#<ComicBook::Entry>, ...]
comic.files type: :images  # => [#<ComicBook::Entry>, ...]

# Reorder, delete, and add pages of an extracted comic, then archive it again.
# Each source is a page already in the folder (relative path) or any image file (absolute path).
extracted = ComicBook.new 'path/to/extracted.cb'
extracted.arrange_pages ['page3.jpg', 'page1.jpg', '/Users/me/Desktop/extra.png']
extracted.archive to: 'path/to/output.cbz'

# Pages are renumbered page_001... in the given order, page images left out are deleted,
# and a ComicInfo.xml in the folder has its <Page> entries and PageCount updated to match.
# Pass a template to name the page files another way. It can use {page} and the comic's
# details, and the names always sort in page order. Write it in single quotes.
extracted.arrange_pages sources, template: '{series}_{number:3}_{page:4}' # Saga_007_0001.jpg ...

# Which formats can be opened, and which can be written
ComicBook::READABLE_TYPES # => [:cb, :cb7, :cbr, :cbt, :cbz, :folder, :pdf]
ComicBook::WRITABLE_TYPES # => [:cb, :cb7, :cbt, :cbz]

# Read ComicInfo.xml metadata
comic = ComicBook.new 'path/to/archive.cbz'
comic.info        # => #<ComicInfo::Issue> or nil
comic.info.title  # => "The Amazing Spider-Man"
comic.info.writer # => "Dan Slott, Christos Gage"
```

## Development

PDF support requires [libvips](https://www.libvips.org/). Install it with `brew bundle` (uses the included `Brewfile`) or manually:

```sh
brew install vips             # macOS
sudo apt install libvips-dev  # Linux
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/veganstraightedge/comicbook. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/veganstraightedge/comicbook/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Comicbook project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/veganstraightedge/comicbook/blob/main/CODE_OF_CONDUCT.md).
