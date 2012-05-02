require "archiver/version"
require 'pry'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'fileutils'
require 'pathname'
require 'pp'
require 'digest/md5'

module GDC
  
  class Archiver
  
    attr_accessor :pattern
    
    def self.archive(options={})
      a = GDC::Archiver.new(options)
      a.execute
    end
  
    def initialize(options={})
      @pattern      = options[:pattern] || "**/*"
      @source_dir   = Pathname.new(options[:source_dir] || ".").expand_path
      
      fail "You have to define target directory" if options[:target_dir].nil?
      @target_dir   = Pathname.new(options[:target_dir]).expand_path
      
      @archive_name = (options[:archive_name] || "archive") + ".zip"
    end

    def execute
      FileUtils::cd(@source_dir) do
        files = Dir.glob(@pattern)  
        archive = @target_dir + @archive_name
        Zip::ZipFile.open(archive, Zip::ZipFile::CREATE) do |zipfile|
          files.each do |file|
            zipfile.add(file, Pathname.new(file).expand_path) unless Pathname.new(file).directory?
          end
        end    
      end
    end
    
  end
end


#GDC::Archiver.archive({
#  :pattern      => "",
#  :source_dir   => "",
#  :target_dir   => "",
#  :unused_dir  => "",
# :remove_dir => ""
                      #:time
                      #:archive_name
#})

# druhy adresar na source, do jednoho se stahnou nemenne zdroje, do druheho se zprocesi