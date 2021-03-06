module SendFileWithRange
  module ControllerExtension
    def send_file(path, options = {})
      if options[:range]
        send_file_with_range(path, options)
      else
        super path, options
      end
    end

    def send_file_with_range(path, options = {})
      if File.exist?(path)
        file_size = File.size(path)
        options[:buffer_size] ||= file_size

        begin_point = 0
        end_point = file_size - 1

        status = 200
        if request.headers['range']
          status = 206
          if request.headers['range'] =~ /bytes\=(\d+)\-(\d*)/
            logger.info("Range: #{request.headers['range']}")
            begin_point = Regexp.last_match(1).to_i
            end_point = Regexp.last_match(2).to_i if Regexp.last_match(2).present?
            # Only override requested end point if the buffer size doesn't
            # overflow the end of the file.
            end_point = begin_point + options[:buffer_size] if begin_point + options[:buffer_size] <= file_size - 1
          end
        end
        content_length = end_point - begin_point + 1
        response.header['Content-Range'] = "bytes #{begin_point}-#{end_point}/#{file_size}"
        response.header['Content-Length'] = content_length.to_s
        response.header['Accept-Ranges'] = 'bytes'
        send_data IO.binread(path, content_length, begin_point), options.merge(status: status)
      else
        raise ActionController::MissingFile, "Cannot read file #{path}"
      end
    end
  end
end
