class BrandsDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view)
        @view = view
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: brands.count.to_i,
            iTotalDisplayRecords: brands.total_count,
            aaData: data
        }
    end

    private

    def data
        brands.each_with_index.map do |brand, index|
            [
                index+1,
                brand.name,
                brand.category.blank? ? "" : brand.category.name,
                brand.created_at.blank? ? "" : brand.created_at.strftime('%A %d %B, %Y'),
                link_to("<i class='fa fa-edit'></i>".html_safe, url_helpers.edit_brand_path(brand), { :class => "btn bg-orange btn-xs" }) + " " +link_to("<i class='fa fa-trash'></i>".html_safe, brand, {method: :delete, :data => {confirm: 'Are you sure?'}, :class => "btn bg-orange btn-xs"}),
                brand.id.to_s,
            ]
        end
    end

    def brands
        @brands ||= fetch_brands
    end

    def fetch_brands
        if params[:sSearch].present?
            brands ||= Brand.search(params[:sSearch]).cache
        else
            brands ||= Brand.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        brands = Kaminari.paginate_array(brands).page(page).per(per_page)
    end

    def page
        params[:iDisplayStart].to_i/per_page + 1
    end

    def per_page
        params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
    end

    def sort_column
        columns = %w[name]
        columns[params[:iSortCol_0].to_i]
    end

    def sort_direction
        params[:sSortDir_0] == "desc" ? "desc" : "asc"
    end
end