class UserProductsDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view, user)
        @view = view
        @user = user
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: products.count.to_i,
            iTotalDisplayRecords: products.total_count,
            aaData: data
        }
    end

    private

    def data
        products.each_with_index.map do |product, index|
            [
                index+1,
                product.product_name,
                product.is_approved? ? "Approved" : "Not Approved",
                product.sold_to.blank? ? "No" : "Yes",
                product.created_at.blank? ? "" : product.created_at.strftime('%A %d %B, %Y'),
                link_to("<i class='fa fa-eye'></i>".html_safe, url_helpers.product_path(product), { :class => "btn bg-orange btn-xs" }),
                product.id.to_s,

            ]
        end
    end

    def products
        @products ||= fetch_products
    end

    def fetch_products
        if params[:sSearch].present?
            products ||= @user.products.search(params[:sSearch]).cache
        else
            products ||= @user.products.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        products = Kaminari.paginate_array(products).page(page).per(per_page)
    end

    def page
        params[:iDisplayStart].to_i/per_page + 1
    end

    def per_page
        params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
    end

    def sort_column
        columns = %w[product_name]
        columns[params[:iSortCol_0].to_i]
    end

    def sort_direction
        params[:sSortDir_0] == "desc" ? "desc" : "asc"
    end
end
