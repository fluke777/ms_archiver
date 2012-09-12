require "archiver/version"
require 'pry'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'fileutils'
require 'pathname'
require 'pp'
require 'digest/md5'
require 'aws/s3'
require 'logger'
require 'inifile'
# require 'openpgp'

module GDC

  class Archiver

    attr_accessor :pattern, :logger

    def self.archive(options={})
      a = GDC::Archiver.new(options)
      a.execute
    end

    def initialize(options={})
      @pattern      = options[:pattern] || "**/*"
      @source_dir   = Pathname.new(options[:source_dir] || ".").expand_path
      @store_to_s3  = options[:store_to_s3]
      @logger       = options[:logger] || Logger.new(File.open('/dev/null'))
      @bucket_name  = options[:bucket_name]
      @s3_credentials_file = Pathname.new(options[:s3_credentials_file] || '.s3cfg').expand_path

      if options[:target_dir]
        @target_dir   = Pathname.new(options[:target_dir]).expand_path
      end

      if @store_to_s3
        fail "You have to define bucket name" if @bucket_name.nil?
      end

      fail "You have to define one of target_dir, store_to_s3." if @target_dir.nil? && (@store_to_s3.nil? || !@store_to_s3)

      @archive_name = (options[:archive_name] || "#{Time.now.to_i}_backup.zip")
    end

    def execute
      archive = @source_dir + @archive_name
      begin
        create_zip_archive(archive)
        store_to_s3(archive) if @store_to_s3
        store_to_target(archive) if @target_dir
      ensure
        FileUtils.rm_f(archive) if File.exist?(archive)
      end
    end

    def get_s3_credentials
      ini = IniFile.new( @s3_credentials_file, :parameter => '=' )
      ini[:default]
    end

    def store_to_s3(archive)
      credentials = get_s3_credentials
      AWS::S3::Base.establish_connection!(
        :access_key_id     => credentials["access_key"],
        :secret_access_key => credentials["secret_key"]
      )
      unless bucket_exist?(@bucket_name)
        logger.info "Bucket #{@bucket_name} does not exist. It will be created"
        AWS::S3::Bucket.create(@bucket_name) 
      end
      bucket = AWS::S3::Bucket.find(@bucket_name)

      begin
        AWS::S3::S3Object.store(archive.basename.to_s, open(archive.to_s), bucket.name)
        logger.info("Archive backed up to S3")
      rescue
        logger.warn("Backup to S3 failed")
      end

    end

    def store_to_target(archive)
      target = @target_dir + @archive_name
      # source = @source_dir + @archive_name
      begin
        FileUtils::cp(archive, target)
        logger.info("Archive backed up to target")
      rescue
        logger.warn("Backup to target failed")
      end
      
    end
      
    def bucket_exist?(bucket_name)
      buckets = AWS::S3::Service.buckets
      buckets.any? {|bucket| bucket.name == bucket_name}
    end

    def create_zip_archive(archive)
      FileUtils::cd(@source_dir) do
        files = Dir.glob(@pattern).uniq
        Zip::ZipFile.open(archive, Zip::ZipFile::CREATE) do |zipfile|
          files.each do |file|
            zipfile.add(file, Pathname.new(file).expand_path) unless Pathname.new(file).directory?
          end
        end
      end
    end
  end
end

# EXAMPLE
#
# def run
#   GDC::Archiver.archive({
#    :target_dir          => "/Users/fluke/",
#    :store_to_s3         => true,
#    :logger              => Logger.new(STDOUT),
#    :bucket_name         => "gooddata_com_customer_project",
#    :s3_credentials_file => '.s3cfg'
#   })
# 
# end
# 
