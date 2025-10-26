require_relative 'lib/comicbook/version'

Gem::Specification.new do |spec|
  spec.name    = 'comicbook'
  spec.version = ComicBook::VERSION
  spec.authors = ['Shane Becker']
  spec.email   = ['veganstraightedge@gmail.com']

  spec.summary     = 'Ruby interface for working with comic book archive files'
  spec.description = <<~DESCRIPTION
    Library for reading and writing comic book archive files:
    .cbz, .cbr, .cbt, .cb7, .cba
  DESCRIPTION

  spec.homepage = 'https://github.com/veganstraightedge/comicbook'
  spec.license  = 'MIT'

  spec.required_ruby_version = '>= 3.4.7'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/veganstraightedge/comicbook'
  spec.metadata['changelog_uri']     = 'https://github.com/veganstraightedge/comicbook/blob/main/CHANGELOG.md'

  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename __FILE__

  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |file|
      ignored_files = %w[
        bin/
        Gemfile
        .gitignore
        .rspec
        spec/
        .github/
        .rubocop.yml
        .rubocop_todo.yml
      ]

      (file == gemspec) || file.start_with?(*ignored_files)
    end
  end

  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.bindir        = 'exe'

  # Runtime dependencies
  spec.add_dependency 'rubyzip', '>= 3.2.1'
end
