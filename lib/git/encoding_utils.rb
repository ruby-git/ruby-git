# frozen_string_literal: true

require 'rchardet'

module Git
  # Provides helpers for detecting and normalizing string encodings
  #
  # `default_encoding` refers to {Git::EncodingUtils.default_encoding}, which is
  # derived from this source file's encoding declaration
  #
  # @api private
  #
  module EncodingUtils
    # Returns the default encoding name used by this source file
    #
    # @return [String] the source file encoding name
    #
    def self.default_encoding
      __ENCODING__.name
    end

    # Returns the fallback encoding name used when detection fails
    #
    # @return [String] the fallback encoding name
    #
    def self.best_guess_encoding
      # Encoding::ASCII_8BIT.name
      Encoding::UTF_8.name
    end

    # Returns the detected encoding name for the given string
    #
    # @param str [String] the string whose encoding should be detected
    #
    # @return [String] the detected encoding name or the fallback encoding name
    #
    def self.detected_encoding(str)
      CharDet.detect(str)['encoding'] || best_guess_encoding
    end

    # Returns replacement options used when transcoding invalid byte sequences
    #
    # @return [Hash<Symbol, Symbol>] options for replacing invalid and undefined bytes
    #
    def self.encoding_options
      { invalid: :replace, undef: :replace }
    end

    # Returns the given string converted to {Git::EncodingUtils.default_encoding}
    #
    # @param str [String] the string to normalize
    #
    # @return [String] the original or transcoded string in
    #   {Git::EncodingUtils.default_encoding}
    #
    def self.normalize_encoding(str)
      return str if str.valid_encoding? && str.encoding.name == default_encoding

      return str.encode(default_encoding, str.encoding, **encoding_options) if str.valid_encoding?

      str.encode(default_encoding, detected_encoding(str), **encoding_options)
    end
  end
end
