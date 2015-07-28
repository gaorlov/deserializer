module Deserializer
  class DeserializerError < StandardError
    def initialize(opts = {})
      @klass    = opts.fetch :class, Deserializer::Base
      @message  = opts.fetch :message, ""
    end

    def message
      "#{@klass}: #{@message}"
    end
  end
end