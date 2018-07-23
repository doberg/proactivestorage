# frozen_string_literal: true

require "test_helper"

class ProActiveStorage::FilenameTest < ActiveSupport::TestCase
  test "base" do
    assert_equal "racecar", ProActiveStorage::Filename.new("racecar.jpg").base
    assert_equal "race.car", ProActiveStorage::Filename.new("race.car.jpg").base
    assert_equal "racecar", ProActiveStorage::Filename.new("racecar").base
  end

  test "extension with delimiter" do
    assert_equal ".jpg", ProActiveStorage::Filename.new("racecar.jpg").extension_with_delimiter
    assert_equal ".jpg", ProActiveStorage::Filename.new("race.car.jpg").extension_with_delimiter
    assert_equal "", ProActiveStorage::Filename.new("racecar").extension_with_delimiter
  end

  test "extension without delimiter" do
    assert_equal "jpg", ProActiveStorage::Filename.new("racecar.jpg").extension_without_delimiter
    assert_equal "jpg", ProActiveStorage::Filename.new("race.car.jpg").extension_without_delimiter
    assert_equal "", ProActiveStorage::Filename.new("racecar").extension_without_delimiter
  end

  test "sanitize" do
    "%$|:;/\t\r\n\\".each_char do |character|
      filename = ProActiveStorage::Filename.new("foo#{character}bar.pdf")
      assert_equal "foo-bar.pdf", filename.sanitized
      assert_equal "foo-bar.pdf", filename.to_s
    end
  end

  test "sanitize transcodes to valid UTF-8" do
    { "\xF6".dup.force_encoding(Encoding::ISO8859_1) => "ö",
      "\xC3".dup.force_encoding(Encoding::ISO8859_1) => "Ã",
      "\xAD" => "�",
      "\xCF" => "�",
      "\x00" => "",
    }.each do |actual, expected|
      assert_equal expected, ProActiveStorage::Filename.new(actual).sanitized
    end
  end

  test "strips RTL override chars used to spoof unsafe executables as docs" do
    # Would be displayed in Windows as "evilexe.pdf" due to the right-to-left
    # (RTL) override char!
    assert_equal "evil-fdp.exe", ProActiveStorage::Filename.new("evil\u{202E}fdp.exe").sanitized
  end

  test "compare case-insensitively" do
    assert_operator ProActiveStorage::Filename.new("foobar.pdf"), :==, ProActiveStorage::Filename.new("FooBar.PDF")
  end

  test "compare sanitized" do
    assert_operator ProActiveStorage::Filename.new("foo-bar.pdf"), :==, ProActiveStorage::Filename.new("foo\tbar.pdf")
  end
end
