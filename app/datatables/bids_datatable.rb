class BidsDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view, product)
        @view = view
        @product = product
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: bids.count.to_i,
            iTotalDisplayRecords: bids.total_count,
            aaData: data
        }
    end

    private

    def data
        bids.each_with_index.map do |bid, index|
            [
                index+1,
                bid.bid_amount,
                bid.user.full_name,
                bid.product.sold_to.blank? ? '' : (bid.product.sold_to_id == bid.id ? "Yes" : ''),
                bid.formatted_created_at,
                bid.id.to_s
            ]
        end
    end

    def bids
        @bids ||= fetch_bids
    end

    def fetch_bids
        if params[:sSearch].present?
            bids ||= @product.bids.where(:bid_amount.gt => 0).search(params[:sSearch]).cache
        else
            bids ||= @product.bids.where(:bid_amount.gt => 0).order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        bids = Kaminari.paginate_array(bids).page(page).per(per_page)
    end

    def page
        params[:iDisplayStart].to_i/per_page + 1
    end

    def per_page
        params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
    end

    def sort_column
        columns = %w[bid_amount]
        columns[params[:iSortCol_0].to_i]
    end

    def sort_direction
        params[:sSortDir_0] == "desc" ? "desc" : "asc"
    end
end
