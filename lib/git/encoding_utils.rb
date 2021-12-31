# frozen_string_literal: true

require 'rchardet'

module Git
  # Method that can be used to detect and normalize string encoding
  module EncodingUtils
    def self.default_encoding
      __ENCODING__.name
    end

    def self.best_guess_encoding
      # Encoding::ASCII_8BIT.name
      Encoding::UTF_8.name
    end

    def self.detected_encoding(str)
      CharDet.detect(str)['encoding'] || best_guess_encoding
    end

    def self.encoding_options
      { invalid: :replace, undef: :replace }
    end

    def self.normalize_encoding(str)
      return str if str.valid_encoding? && str.encoding.name == default_encoding

      return str.encode(default_encoding, str.encoding, **encoding_options) if str.valid_encoding?

      str.encode(default_encoding, detected_encoding(str), **encoding_options)
    end
  end
end
