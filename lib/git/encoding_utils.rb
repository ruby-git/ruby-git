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
    # When the string is not valid in its own encoding, the source encoding is
    # taken from {Git::EncodingUtils.detected_encoding}. rchardet can name an
    # encoding Ruby has no converter for (`UTF-7` and the two unusual-octet-order
    # `UCS-4` forms, each assigned from a byte-order mark). In that case the
    # invalid bytes are replaced with `String#scrub` instead, which keeps any
    # valid multibyte sequences on the same line.
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
    rescue Encoding::ConverterNotFoundError
      scrub_to_default_encoding(str)
    end

    # Returns the given string with its invalid bytes replaced, in
    # {Git::EncodingUtils.default_encoding}
    #
    # `String#scrub` returns the string in its own encoding, so the result is
    # transcoded afterward. On the gem's own call path the string is already
    # tagged UTF-8 and that step is a no-op.
    #
    # @param str [String] the string to scrub
    #
    # @return [String] the scrubbed string in {Git::EncodingUtils.default_encoding}
    #
    def self.scrub_to_default_encoding(str)
      str.scrub.encode(default_encoding, **encoding_options)
    end
    private_class_method :scrub_to_default_encoding
  end
end
