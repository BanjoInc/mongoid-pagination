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
      def paginated_criteria(opts = {})
        limit = (opts[:limit] || page_size).to_i
        offset = paginate_offset(opts)

        per_page(limit).offset(offset)
      end

      def paginate(opts = {})

        criteria = paginated_criteria(opts)
        limit = criteria.options[:limit]
        criteria.options[:limit] += 1

        over_fetched_collection = criteria.to_a
        has_more_results = over_fetched_collection.size > limit

        over_fetched_collection.pop if has_more_results

        @paginated_collection = ::Mongoid::Pagination::Collection.new(over_fetched_collection)
        @paginated_collection.current_offset = criteria.options[:skip]
        @paginated_collection.current_page_size = limit
        @paginated_collection.has_more_results = has_more_results

        preload(opts[:eager_load]) if opts[:eager_load].present?

        @paginated_collection
      end

      def preload(args)
        return unless args.present? && @paginated_collection.present?

        relations.select { |k,v| args.map(&:to_s).include?(k) }.each_pair do |name,meta|
          field_key = meta.key
          ids = @paginated_collection.map { |c| c.send(field_key.to_sym) }.compact
          meta.class_name.constantize.any_in(_id: ids).to_a if ids.present?
        end
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

      def paginated_collection
        @paginated_collection
      end
    end

    class Collection < Array
      attr_accessor :current_offset, :current_page_size, :has_more_results

      def next_offset_at
        current_offset + current_page_size
      end

      def next_offset
        has_more_results ? next_offset_at : nil
      end
    end
  end
end

