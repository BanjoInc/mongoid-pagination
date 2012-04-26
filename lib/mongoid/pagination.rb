module Mongoid
  module Pagination
    extend ActiveSupport::Concern

    module ClassMethods

      def page_size
        @page_size || 25
      end

      def page_size=(page_size)
        @page_size = page_size
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

      def paginated_collection(opts = {})

        limit = opts[:limit] || page_size

        over_fetched_collection = paginate(opts.merge(limit: limit + 1)).to_a
        has_more_results = over_fetched_collection.size > limit

        over_fetched_collection.pop if has_more_results

        collection = ::Mongoid::Pagination::Collection.new(over_fetched_collection)
        collection.current_offset = opts[:offset] || 0
        collection.current_page_size = limit
        collection.has_more_results = has_more_results

        collection
      end

      # Limit the result set
      #
      # @param [Integer] page_limit the max number of results to return
      # @return [Mongoid::Criteria]
      def per_page(page_limit = page_size)
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

    module CollectionMethods

      def next_offset_at
        current_offset + current_page_size
      end

      def next_offset
        has_more_results ? next_offset_at : nil
      end
    end

    class Collection < Array
      include CollectionMethods
 
      attr_accessor :current_offset, :current_page_size, :has_more_results

      def page
        current_offset / current_page_size + 1
      end
    end
  end
end

