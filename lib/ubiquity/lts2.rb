require 'fog'
require 'ubiquity/lts2/version'

module Ubiquity
  class LTS2

    class File < ::File

      def size
        File.size(path)
      end unless File.instance_methods.include?(:size)

    end if RUBY_VERSION.start_with?('1.8')

    DEFAULT_SWIFT_AUTH_URL_V2 = 'https://auth.lts2.evault.com/v2.0'

    attr_accessor :storage

    def initialize(args = { })
      initialize_logger(args)
      initialize_storage(args)
    end

    # @param [Hash] args
    # @option args [Logger]     :logger A logger to be used
    # @option args [IO, String] :log_to An IO device or file to log to
    # @option args [Integer]    :log_level (Logger::DEBUG) The logging level to be set to the logger
    def initialize_logger(args = { })
      @logger = args[:logger] ||= Logger.new(args[:log_to] ||= STDERR)
      logger.level = (log_level = args[:log_level]) ? log_level : Logger::DEBUG
      args[:logger] = logger
    end

    # @param [Hash] args
    # @option args [String] :username The Amazon Web Services (AWS) access key
    # @option args [String] :password The AWS secret key
    def initialize_storage(args = { })

      username = args[:username]
      raise ':username is required to initialize a connection.' unless username

      password = args[:password]
      raise ':password is required to initialize a connection.' unless password

      auth_url = args[:auth_url] ||= DEFAULT_SWIFT_AUTH_URL_V2
      auth_url = File.join(auth_url, 'tokens') unless auth_url.end_with?('/tokens')

      args_out = {
          :provider => :Openstack,
          :openstack_username  => username,      # Your OpenStack Username
          :openstack_api_key   => password,      # Your OpenStack Password
          :openstack_auth_url  => auth_url
      }
      # :persistent, :openstack_service_name, :openstack_service_type, :openstack_tenant, :openstack_region,
      # :openstack_temp_url_key, :openstack_endpoint_type
      Fog::Storage::OpenStack.recognized.each { |k| args_out[k] = args[k] if args.has_key?(k) }

      @storage = Fog::Storage.new(args_out)
    end

    def logger; @logger ||= Logger.new(STDERR) end

    def process_common_upload_arguments(args = { })
      container_name = args[:container_name]
      container = args[:container]
      raise ArgumentError, ':container_name is a required argument.' unless container_name or container

      container ||= storage.directories.get(container_name)
      container_name = container.key

      path_of_file_to_upload = args[:path_of_file_to_upload]
      raise ArgumentError, ':path_of_file_to_upload is a required argument.' unless path_of_file_to_upload
      raise "File Not Found: #{path_of_file_to_upload}" unless File.exists?(path_of_file_to_upload)

      object_key = args[:object_key] || path_of_file_to_upload

      # Trim off any leading slashes
      object_key = object_key[1..-1] while object_key.start_with?('/') if object_key.respond_to?(:start_with?)
      raise ':object_key must be set and cannot be empty.' unless object_key and !object_key.empty?

      progress_callback_method = args[:progress_callback_method]

      overwrite_existing_file = args.fetch(:overwrite_existing_file, false)
      overwrite_existing_file_only_if_size_mismatch = args.fetch(:overwrite_existing_file_if_size_mismatch, false)
      overwrite_existing_file ||= overwrite_existing_file_only_if_size_mismatch



      metadata = args[:metadata] || { }

      {
        :path_of_file_to_upload => path_of_file_to_upload,
        :container_name => container_name,
        :container => container,
        :object_key => object_key,
        :file_to_upload => File.open(path_of_file_to_upload),
        :progress_callback_method => progress_callback_method,
        :overwrite_existing_file => overwrite_existing_file,
        :overwrite_existing_file_only_if_size_mismatch => overwrite_existing_file_only_if_size_mismatch,
        :common_upload_arguments_processed => true,
        :metadata => metadata
      }
    end

    def existing_file_check(args)
      return false if args[:overwrite_existing_file]

      container_name = args[:container_name]
      container = args[:container] ||= container_get(container_name)
      container_name ||= container.key

      object_key = args[:object_key]
      # TODO: Figure out how to update the File's ACL without uploading it again
      logger.debug { "Checking for Existing File. Container Name: '#{container_name}' Object Key: '#{object_key}'" }
      stored_file = object_head_get(container, object_key)
      unless stored_file
        logger.debug { 'Existing File Not Found.' }
        return false
      end

      logger.debug { "Existing File Found. #{stored_file.inspect}" }
      unless args[:overwrite_existing_file_only_if_size_mismatch]
        logger.debug { 'Skipping Upload.' }
        return stored_file
      end

      file_to_upload = args[:file_to_upload]
      file_size = file_to_upload.size

      stored_file_content_length = stored_file.content_length
      if stored_file_content_length == file_size
        logger.debug { "Skipping Upload. File Size Match: #{stored_file_content_length} == #{file_size}" }
        return stored_file
      end

      logger.debug { "Not Skipping Upload. File Size Mis-match: #{stored_file_content_length} != #{file_size}" }
      return false
    end

    def upload(args = { })
      upload_args = args[:common_upload_arguments_processed] ? args : process_common_upload_arguments(args)
      file_to_upload = upload_args[:file_to_upload]
      file_size = file_to_upload.size

      # upload_large_file(upload_args) if file_size > maximum_single_file_upload_size

      #container_name = upload_args[:container_name]
      directory = upload_args[:container]
      object_key = upload_args[:object_key]
      metadata = upload_args[:metadata]
      logger.debug { "Setting File Metadata: #{metadata.inspect}" } if metadata

      file_upload_start = Time.now
      response = directory.files.create( :key => object_key, :body => file_to_upload, :metadata => metadata )
      file_upload_end = Time.now
      file_upload_took  = Float(file_upload_end - file_upload_start)
      logger.debug { "Uploaded #{file_size} bytes in #{file_upload_took} seconds @ #{(file_size/file_upload_took)}Bps" }
      #logger.debug { "Uploaded #{file_size} bytes in #{file_upload_took.round(2)} seconds. #{(file_size/file_upload_took).round(0)} Bps" }
      return response
    ensure
      file_to_upload.close if file_to_upload.respond_to?(RUBY_VERSION.start_with?('1.8.') ? 'close' : :close)
    end

    # TODO: Implement Upload Large File Method
    def upload_large_file(args = { })
      # upload_args = args[:common_upload_arguments_processed] ? args : process_common_upload_arguments(args)
    end

    def container_get(container_name)
      storage.directories.get(container_name)
    end
    alias :get_container :container_get

    def object_head_get(container, object_key)
      directory = container.is_a?(String) ? storage.directories.get(container) : container
      directory.files.head( object_key )
    end
    alias :get_object_head :object_head_get

    def object_post(args = { })

    end
    alias :post_object :object_post

    def object_put(args = { })

    end
    alias :put_object :object_put

  end
end
