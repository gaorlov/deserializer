module Deserializer
  class JsonApi < Base

    class << self
      def from_params(params = {}, &block)
        data_params = params[:data] || {}
        id = data_params[:id]
        type = data_params[:type]

        yield(id, type) if block_given?

        # TODO: account for relationships & links
        super(data_params[:attributes])
      end
    end
  end
end
