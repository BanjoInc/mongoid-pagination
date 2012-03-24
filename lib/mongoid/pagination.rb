module Mongoid
  module Pagination
    extend ActiveSupport::Concern

    module ClassMethods

      def page_size
        25
      end

      def default_page_size(page_size)
        module_eval <<EOF
          def self.page_size
            #{page_size}
          end
EOF
      end

      # Paginate the results
      #
      # @param [Hash] opts
      # @option [Integer] :page (default: 1)
      # @option [Integer] :offset (default: 0)
      # @option [Integer] :limit (default: 25)
      #
      # @return [Mongoid::Criteria]
      def paginate(opts = {})

        opts[:limit] = (opts[:limit] || page_size).to_i

        offset = paginate_offset(opts)
        per_page(opts[:limit]).offset(offset)
      end

      # Limit the result set
      #
      # @param [Integer] page_limit the max number of results to return
      # @return [Mongoid::Criteria]
      def per_page(page_limit = 25)
        limit(page_limit.to_i)
      end

      def paginate_offset(opts = {})
        case
          when opts[:page] && (page = opts[:page].to_i) > 0 then (page - 1) * (opts[:limit] || page_size).to_i
          when opts[:offset] && (offset = opts[:offset].to_i) >= 0 then offset
          else 0
        end
      end

      def has_more_result?(opts = {})
        count > next_offset_at(opts)
      end

      def next_offset_at(opts = {})
        paginate_offset(opts) + (opts[:limit] || page_size).to_i
      end

      def next_offset(opts = {})
        has_more_result?(opts) ? next_offset_at(opts) : nil
      end
    end
  end
end

