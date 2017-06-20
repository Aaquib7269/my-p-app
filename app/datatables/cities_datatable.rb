class CitiesDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view)
        @view = view
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: cities.count.to_i,
            iTotalDisplayRecords: cities.total_count,
            aaData: data
        }
    end

    private

    def data
        cities.each_with_index.map do |city, index|
            [
                index+1,
                city.name,
                city.state.blank? ? "" : city.state.name,
                city.created_at.blank? ? "" : city.created_at.strftime('%A %d %B, %Y'),
                link_to("<i class='fa fa-edit'></i>".html_safe, url_helpers.edit_city_path(city), { :class => "btn bg-orange btn-xs" }) + " " +link_to("<i class='fa fa-trash'></i>".html_safe, city, {method: :delete, :data => {confirm: 'Are you sure?'}, :class => "btn bg-orange btn-xs"}),
                city.id.to_s,
            ]
        end
    end

    def cities
        @cities ||= fetch_cities
    end

    def fetch_cities
        if params[:sSearch].present?
            cities ||= City.search(params[:sSearch]).cache
        else
            cities ||= City.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        cities = Kaminari.paginate_array(cities).page(page).per(per_page)
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