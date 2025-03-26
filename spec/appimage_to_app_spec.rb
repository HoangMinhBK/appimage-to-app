# frozen_string_literal: true

require 'spec_helper'
require 'appimage_to_app'
require 'fileutils'
require 'pathname'
require 'tmpdir'

RSpec.describe AppimageToApp::CLI do
  let(:test_appimage) { 'test.AppImage' }
  let(:test_icon) { 'test.png' }
  let(:tmp_dir) { Dir.mktmpdir }
  let(:cli) { described_class.new }
  let(:test_appimage_path) { Pathname.new(test_appimage).expand_path }
  let(:desktop_dir) { Pathname.new(tmp_dir) / '.local/share/applications' }
  let(:bin_dir) { Pathname.new(tmp_dir) / '.local/bin' }
  let(:desktop_file) { desktop_dir / "#{test_appimage}.desktop" }

  before do
    # Allow any environment variable lookup and return nil by default
    allow(ENV).to receive(:[]).and_return(nil)
    # Specifically stub HOME to return the temporary directory
    allow(ENV).to receive(:[]).with('HOME').and_return(tmp_dir)
    
    # Create necessary directories
    FileUtils.mkdir_p(desktop_dir)
    FileUtils.mkdir_p(bin_dir)
    
    # Mock Pathname operations
    allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)
    allow_any_instance_of(Pathname).to receive(:expand_path) { |path| path }
    allow_any_instance_of(Pathname).to receive(:basename) { |path| path }
    allow_any_instance_of(Pathname).to receive(:write)
    allow_any_instance_of(Pathname).to receive(:delete)
    allow_any_instance_of(Pathname).to receive(:mkpath)
    
    # Mock file operations with more specific behavior
    allow(File).to receive(:executable?).and_return(true)
    allow(File).to receive(:read) do |path, *args|
      case path.to_s
      when test_appimage
        if args.first == 8
          "\x7fELF"
        else
          "\x7fELF"
        end
      when /\.desktop$/
        '[Desktop Entry]\nExec=/path/to/test.AppImage'
      else
        "\x7fELF"
      end
    end
    allow(FileUtils).to receive(:chmod)
    allow(FileUtils).to receive(:cp)
    allow(FileUtils).to receive(:mkdir_p)
    
    # Mock file existence checks with more specific behavior
    allow(File).to receive(:exist?) do |path|
      case path.to_s
      when /\.desktop$/
        true
      when test_appimage
        true
      when test_icon
        true
      else
        false
      end
    end
    
    # Mock file stats
    allow(File).to receive(:stat) do |path|
      case path.to_s
      when /\.desktop$/
        double(mode: 0o644)
      else
        double(mode: 0o755)
      end
    end
    
    # Mock Dir.glob for desktop files
    allow(Dir).to receive(:glob).with("#{desktop_dir}/*.desktop").and_return([desktop_file.to_s])
  end

  after do
    FileUtils.remove_entry tmp_dir
  end

  describe '#convert' do
    context 'with basic options' do
      it 'converts a valid AppImage with default options' do
        expect(FileUtils).to receive(:chmod).with(0o755, test_appimage_path)
        expect(FileUtils).to receive(:cp).with(test_appimage_path, bin_dir / test_appimage_path.basename)
        expect(FileUtils).to receive(:chmod).with(0o755, bin_dir / test_appimage_path.basename)
        
        cli.convert(test_appimage)
        expect(Dir.glob("#{desktop_dir}/*.desktop").length).to eq(1)
      end

      it 'handles non-existent files' do
        allow(File).to receive(:exist?).with(test_appimage).and_return(false)
        allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
        expect { cli.convert(test_appimage) }.to raise_error(SystemExit)
      end

      it 'handles invalid AppImages' do
        allow(File).to receive(:executable?) do |path|
          case path.to_s
          when test_appimage
            true
          else
            false
          end
        end
        allow(File).to receive(:read) do |path, *args|
          case path.to_s
          when test_appimage
            'not an ELF'
          else
            "\x7fELF"
          end
        end
        allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)
        allow(File).to receive(:exist?).with(test_appimage).and_return(true)
        expect { cli.convert(test_appimage) }.to raise_error(SystemExit)
      end
    end

    context 'with custom options' do
      it 'creates desktop entry with custom name' do
        cli.options = { name: 'Custom App' }
        expect_any_instance_of(Pathname).to receive(:write).with(
          include('Name=Custom App')
        )
        cli.convert(test_appimage)
      end

      it 'creates desktop entry with custom category' do
        cli.options = { category: 'Development' }
        expect_any_instance_of(Pathname).to receive(:write).with(
          include('Categories=Development;')
        )
        cli.convert(test_appimage)
      end

      it 'creates desktop entry with custom icon' do
        cli.options = { icon: test_icon }
        expect_any_instance_of(Pathname).to receive(:write).with(
          include("Icon=#{test_icon}")
        )
        cli.convert(test_appimage)
      end

      it 'creates desktop entry with comment' do
        cli.options = { comment: 'Test Description' }
        expect_any_instance_of(Pathname).to receive(:write).with(
          include('Comment=Test Description')
        )
        cli.convert(test_appimage)
      end

      it 'creates desktop entry with keywords' do
        cli.options = { keywords: 'test,app,desktop' }
        expect_any_instance_of(Pathname).to receive(:write).with(
          include('Keywords=test,app,desktop')
        )
        cli.convert(test_appimage)
      end

      it 'creates desktop entry with terminal option' do
        cli.options = { terminal: true }
        expect_any_instance_of(Pathname).to receive(:write).with(
          include('Terminal=true')
        )
        cli.convert(test_appimage)
      end

      it 'creates desktop entry with startup notification options' do
        cli.options = { startup_notify: false }
        expect_any_instance_of(Pathname).to receive(:write).with(
          include('StartupNotify=false')
        )
        cli.convert(test_appimage)
      end
    end

    context 'file operations' do
      it 'makes AppImage executable' do
        expect(FileUtils).to receive(:chmod).with(0o755, test_appimage_path)
        cli.convert(test_appimage)
      end

      it 'installs AppImage to bin directory' do
        expect(FileUtils).to receive(:cp).with(test_appimage_path, bin_dir / test_appimage_path.basename)
        cli.convert(test_appimage)
      end

      it 'creates desktop entry with correct permissions' do
        expect(FileUtils).to receive(:chmod).with(0o644, desktop_file)
        cli.convert(test_appimage)
      end
    end
  end

  describe '#list' do
    it 'lists converted applications' do
      allow_any_instance_of(Pathname).to receive(:read).and_return('[Desktop Entry]\nExec=/path/to/test.AppImage')
      expect { cli.list }.to output(/test/).to_stdout
    end

    it 'handles empty applications directory' do
      allow(Dir).to receive(:glob).with("#{desktop_dir}/*.desktop").and_return([])
      expect { cli.list }.not_to raise_error
    end
  end

  describe '#remove' do
    it 'removes a converted application' do
      expect_any_instance_of(Pathname).to receive(:delete)
      cli.remove(test_appimage)
    end

    it 'handles non-existent application' do
      allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
      expect { cli.remove('nonexistent') }.to output(/No desktop entry found/).to_stdout
    end
  end
end 