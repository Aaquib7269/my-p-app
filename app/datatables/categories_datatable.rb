class CategoriesDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view)
        @view = view
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: categories.count.to_i,
            iTotalDisplayRecords: categories.total_count,
            aaData: data
        }
    end

    private

    def data
        categories.each_with_index.map do |category, index|
            [
                index+1,
                category.name,
                category.parent_category.blank? ? "" : category.parent_category.name,
                category.created_at.blank? ? "" : category.created_at.strftime('%A %d %B, %Y'),
                link_to("<i class='fa fa-edit'></i>".html_safe, url_helpers.edit_category_path(category), { :class => "btn bg-orange btn-xs" }) + " " +link_to("<i class='fa fa-trash'></i>".html_safe, category, {method: :delete, :data => {confirm: 'Are you sure?'}, :class => "btn bg-orange btn-xs"}),
                category.id.to_s,
            ]
        end
    end

    def categories
        @categories ||= fetch_categories
    end

    def fetch_categories
        if params[:sSearch].present?
            categories ||= Category.search(params[:sSearch]).cache
        else
            categories ||= Category.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        categories = Kaminari.paginate_array(categories).page(page).per(per_page)
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