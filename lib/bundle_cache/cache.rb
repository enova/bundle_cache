require "digest"
require "aws-sdk"

module BundleCache
  def self.cache
    acl_to_use = ENV["KEEP_BUNDLE_PRIVATE"] ? :private : :public_read
    bundle_dir = ENV["BUNDLE_DIR"] || "~/.bundle"
    processing_dir = ENV["PROCESS_DIR"] || ENV["HOME"]

    bucket_name     = ENV["AWS_S3_BUCKET"]
    architecture    = `uname -m`.strip

    file_name       = "#{ENV['BUNDLE_ARCHIVE']}-#{architecture}.tgz"
    file_path       = "#{processing_dir}/#{file_name}"
    digest_filename = "#{file_name}.sha2"
    old_digest      = File.expand_path("#{processing_dir}/remote_#{digest_filename}")
    lock_file       = if ENV["BUNDLE_GEMFILE"]
                        File.expand_path("#{ENV['BUNDLE_GEMFILE']}.lock")
                      else
                        File.join(File.expand_path(ENV["TRAVIS_BUILD_DIR"].to_s), "Gemfile.lock")
                      end

    puts "Checking for changes"
    bundle_digest = Digest::SHA2.file(lock_file).hexdigest
    old_digest    = File.exists?(old_digest) ? File.read(old_digest) : ""

    if bundle_digest == old_digest
      puts "=> There were no changes, doing nothing"
    else
      if old_digest == ""
        puts "=> There was no existing digest, uploading a new version of the archive"
      else
        puts "=> There were changes, uploading a new version of the archive"
        puts "  => Old checksum: #{old_digest}"
        puts "  => New checksum: #{bundle_digest}"
      end

      puts "=> Preparing bundle archive"
      `tar -C #{File.dirname(bundle_dir)} -cjf #{file_path} #{File.basename(bundle_dir)} && split -b 5m -a 3 #{file_path} #{file_path}.`

      if 1 == $?.exitstatus
        puts "=> Archive failed. Please make sure '--path=#{bundle_dir}' is added to bundle_args."
        exit 1
      end


      parts_pattern = File.expand_path(File.join(processing_dir, "#{file_name}.*"))
      parts = Dir.glob(parts_pattern).sort

      s3 = AWS::S3.new
      bucket = s3.buckets[bucket_name]

      puts "=> Uploading the bundle"
      gem_archive = bucket.objects[file_name]

      puts "  => Uploading #{parts.length} parts"
      gem_archive.multipart_upload(:acl => acl_to_use) do |upload|
        parts.each_with_index do |part, index|
          puts "    => Uploading #{part}"
          File.open part do |part_file|
            upload.add_part(part_file)
            puts "      => Uploaded"
          end
        end
      end
      puts "  => Completed multipart upload"

      puts "=> Uploading the digest file"
      hash_object = bucket.objects[digest_filename]
      hash_object.write(bundle_digest, :acl => acl_to_use, :content_type => "text/plain")
    end

    puts "All done now."
  end
end
