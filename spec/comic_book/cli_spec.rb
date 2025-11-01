require 'spec_helper'
require 'comic_book/cli'
require 'tmpdir'

RSpec.describe ComicBook::CLI do
  let(:cli) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:cbz_file) { File.join temp_dir, 'test.cbz' }
  let(:test_folder) { File.join temp_dir, 'test_folder' }

  after { FileUtils.rm_rf temp_dir }

  describe '.start' do
    let(:cli_instance) { instance_double described_class }

    before do
      allow(described_class).to receive(:new).and_return cli_instance
      allow(cli_instance).to receive(:start).with ['--help']
      described_class.start '--help'
    end

    it 'creates new instance and calls start' do
      expect(cli_instance).to have_received(:start).with ['--help']
    end
  end

  describe '#start' do
    context 'with help flags' do
      it 'shows help for -h' do
        expect { cli.start('-h') }.to output(/ComicBook CLI/).to_stdout
      end

      it 'shows help for --help' do
        expect { cli.start('--help') }.to output(/ComicBook CLI/).to_stdout
      end

      it 'shows help for no arguments' do
        expect { cli.start [] }.to output(/ComicBook CLI/).to_stdout
      end
    end

    context 'with unknown command' do
      it 'shows error and help' do
        expect { cli.start 'unknown' }
          .to raise_error(SystemExit)
          .and output(/Unknown command: unknown/)
          .to_stdout
      end
    end

    context 'with ComicBook::Error' do
      before do
        allow(ComicBook).to receive(:extract).and_raise ComicBook::Error, 'Test error'
        allow(File).to receive(:exist?).and_return true
      end

      it 'shows error message and exits' do
        expect { cli.start ['extract', 'test.cbz'] }
          .to raise_error(SystemExit)
          .and output(/Error: Test error/)
          .to_stdout
      end
    end
  end

  describe 'extract command' do
    before do
      load_fixture('cbz/simple.cbz').copy_to cbz_file
    end

    context 'with valid file' do
      before do
        allow(ComicBook).to receive(:extract).with cbz_file, {}
      end

      it 'extracts cbz file' do
        expect { cli.start ['extract', cbz_file] }
          .to output(/Extracted #{Regexp.escape(cbz_file)}/)
          .to_stdout

        expect(ComicBook).to have_received(:extract).with cbz_file, {}
      end

      context 'with --to option' do
        let(:to_path) { File.join(temp_dir, 'output') }

        before do
          allow(ComicBook).to receive(:extract).with cbz_file, { to: to_path }
        end

        it 'extracts file' do
          expect { cli.start ['extract', cbz_file, '--to', to_path] }
            .to output(/Extracted.*to #{Regexp.escape(to_path)}/)
            .to_stdout

          expect(ComicBook).to have_received(:extract).with cbz_file, { to: to_path }
        end
      end

      context 'with --from option' do
        it 'extracts file' do
          expect { cli.start ['extract', '--from', cbz_file] }
            .to output(/Extracted #{Regexp.escape(cbz_file)}/)
            .to_stdout

          expect(ComicBook).to have_received(:extract).with cbz_file, {}
        end
      end
    end

    context 'with missing source file' do
      it 'shows error for nonexistent file' do
        expect { cli.start ['extract', 'nonexistent.cbz'] }
          .to raise_error(SystemExit)
          .and output(/Error: Source file not found/)
          .to_stdout
      end

      it 'shows error for no source file' do
        expect { cli.start 'extract' }
          .to raise_error(SystemExit)
          .and output(/Error: Source file required/)
          .to_stdout
      end
    end

    context 'with existing destination' do
      let(:existing_path) { File.join temp_dir, 'existing' }

      before do
        FileUtils.touch existing_path
      end

      it 'shows error when destination exists' do
        expect { cli.start ['extract', cbz_file, '--to', existing_path] }
          .to raise_error(SystemExit)
          .and output(/Error: Destination already exists/)
          .to_stdout
      end
    end

    context 'with unsupported formats' do
      context 'with CBR files' do
        let(:cbr_file) { File.join temp_dir, 'test.cbr' }

        before do
          FileUtils.touch cbr_file
        end

        it 'shows error' do
          expect { cli.start ['extract', cbr_file] }
            .to raise_error(SystemExit)
            .and output(/Error: Unsupported format: .cbr/)
            .to_stdout
        end
      end

      context 'with CBA files' do
        let(:cba_file) { File.join temp_dir, 'test.cba' }

        before do
          FileUtils.touch cba_file
        end

        it 'shows error' do
          expect { cli.start ['extract', cba_file] }
            .to raise_error(SystemExit)
            .and output(/Error: Unsupported format: .cba/)
            .to_stdout
        end
      end
    end
  end

  describe 'archive command' do
    before do
      FileUtils.mkdir_p test_folder
      FileUtils.touch File.join(test_folder, 'page1.jpg')
    end

    context 'with valid folder' do
      let(:comic_book) { instance_double ComicBook }

      before do
        allow(ComicBook).to receive(:new).with(test_folder).and_return comic_book
        allow(comic_book).to receive(:archive).with(test_folder, {})
      end

      it 'archives folder' do
        expect { cli.start ['archive', test_folder] }
          .to output(/Archived #{Regexp.escape(test_folder)}/)
          .to_stdout
      end

      context 'with --to option' do
        let(:to_path) { File.join(temp_dir, 'output.cbz') }

        before do
          allow(ComicBook).to receive(:new).with(test_folder).and_return comic_book
          allow(comic_book).to receive(:archive).with test_folder, { to: to_path }
        end

        it 'archives folder to specified path' do
          expect { cli.start ['archive', test_folder, '--to', to_path] }
            .to output(/Archived.*to #{Regexp.escape(to_path)}/)
            .to_stdout
        end
      end

      context 'with --from option' do
        before do
          allow(ComicBook).to receive(:new).with(test_folder).and_return comic_book
          allow(comic_book).to receive(:archive).with test_folder, {}
        end

        it 'archives folder with --from option' do
          expect { cli.start ['archive', '--from', test_folder] }
            .to output(/Archived #{Regexp.escape(test_folder)}/)
            .to_stdout
        end
      end
    end

    context 'with missing source folder' do
      it 'shows error for nonexistent folder' do
        expect { cli.start %w[archive nonexistent] }
          .to raise_error(SystemExit)
          .and output(/Error: Source folder not found/)
          .to_stdout
      end

      it 'shows error for no source folder' do
        expect { cli.start 'archive' }
          .to raise_error(SystemExit)
          .and output(/Error: Source folder required/)
          .to_stdout
      end

      context 'when source is not a directory' do
        let(:file_path) { File.join temp_dir, 'notdir.txt' }

        before do
          FileUtils.touch file_path
        end

        it 'shows error' do
          expect { cli.start ['archive', file_path] }
            .to raise_error(SystemExit)
            .and output(/Error: Source must be a directory/)
            .to_stdout
        end
      end
    end

    context 'with existing destination' do
      let(:existing_path) { File.join temp_dir, 'existing.cbz' }

      before do
        FileUtils.touch existing_path
      end

      it 'shows error when destination exists' do
        expect { cli.start ['archive', test_folder, '--to', existing_path] }
          .to raise_error(SystemExit)
          .and output(/Error: Destination already exists/)
          .to_stdout
      end
    end
  end
end
