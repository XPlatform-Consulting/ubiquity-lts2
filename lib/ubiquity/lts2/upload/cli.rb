require 'fog'
if RUBY_VERSION.start_with?('1.8')
  require 'fog/json'
  module JSON

    def self.encode(obj)
      MultiJson.encode(obj)
    rescue => err
      raise EncodeError.slurp(err)
    end

    def self.decode(obj)
      MultiJson.decode(obj)
    rescue => err
      raise EncodeError.slurp(err)
    end

  end unless defined?(JSON)

  module JSON
    class << self
      alias :load :decode unless defined?(JSON.load)
      alias :generate :encode unless defined?(JSON.generate)
    end
  end
else
  require 'json'
end
require 'optparse'

require 'ubiquity/cli'
require 'ubiquity/lts2'

module Ubiquity

  class LTS2

    class Upload

      class CLI < Ubiquity::CLI

        def self.help_usage
          help_usage_append '--username <username> --password <password> --file-to-upload <file_path> --container-name <container_name>'
        end

        def self.define_parameters
          argument_parser.on('--username USERNAME', 'The username to authenticate with.') { |v| arguments[:username] = v }
          argument_parser.on('--password PASSWORD', 'The password to authenticate with.') { |v| arguments[:password] = v }
          argument_parser.on('--container-name NAME', 'The name of the container to save the file to.') { |v| arguments[:container_name] = v }
          argument_parser.on('--object-key KEY', 'The unique name to use when saving the file to the bucket.') { |v| arguments[:object_key] = v }
          argument_parser.on('--file-to-upload PATH', 'The path of the file to upload.') { |v| arguments[:path_of_file_to_upload] = v }
          argument_parser.on('--metadata JSON', 'A JSON hash containing metadata to be set for the file.') { |v| arguments[:metadata] = JSON.load(v) }
          # argument_parser.on('--[no-]use-multipart-upload', 'Determines if multipart upload will be used to upload the file') { |v| arguments[:use_multipart_upload] = v }
          # argument_parser.on('--multipart-chunk-size BYTES', 'Determines the size of each chunk in a multipart upload.') { |v| arguments[:multipart_chunk_size] = v }
          # argument_parser.on('--thread-limit NUM', 'Determines the maximum number concurrent of threads to use when performing  a multipart upload. ') { |v| arguments[:multipart_chunk_size] = v }
          argument_parser.on_tail('-h', '--help', 'Display this message.') { puts help; exit }
        end


        def self.run(args = nil, init_options = { }, run_options = { })
          args ||= parse_arguments
          #puts "[#{__FILE__}:#{__LINE__}] RUN ARGS: #{args.inspect}"
          new(args, init_options).run(args, run_options)
        end

        attr_accessor :response, :output_as_hash, :output_for_stdout

        def initialize(args = self.class.arguments, options = { })
          @initial_args = args.dup
          @lts2 = Ubiquity::LTS2.new(args)
        end

        def run(args = self.class.arguments, options = { })
          object = @response = @lts2.upload(args)

          @output_as_hash = {
            :key => object.key,
            :content_length => object.content_length,
            :content_type => object.content_type,
            :content_disposition => object.content_disposition,
            :etag => object.etag,
            :last_modified => object.last_modified,
            :origin => object.origin,
            :access_control_allow_origin => object.access_control_allow_origin,
            :metadata => object.metadata,
            #:url => object.url,
            #:public_url => object.public_url,
            :container_name => object.directory.key,
          }

          @output_for_stdout = JSON.generate(output_as_hash)

          puts @output_for_stdout if options.fetch(:put_stdout_output, true)
          self
        end

      end

    end

  end

end
def cli; @cli ||= Ubiquity::LTS2::Upload::CLI end
