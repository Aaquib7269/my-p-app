class CountriesDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view)
        @view = view
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: countries.count.to_i,
            iTotalDisplayRecords: countries.total_count,
            aaData: data
        }
    end

    private

    def data
        countries.each_with_index.map do |country, index|
            [
                index+1,
                country.name,
                country.shortcode,
                country.created_at.blank? ? "" : country.created_at.strftime('%A %d %B, %Y'),
                link_to("<i class='fa fa-edit'></i>".html_safe, url_helpers.edit_country_path(country), { :class => "btn bg-orange btn-xs" }) + " " +link_to("<i class='fa fa-trash'></i>".html_safe, country, {method: :delete, :data => {confirm: 'Are you sure?'}, :class => "btn bg-orange btn-xs"}),
                country.id.to_s
            ]
        end
    end

    def countries
        @countries ||= fetch_countries
    end

    def fetch_countries
        if params[:sSearch].present?
            countries ||= Country.search(params[:sSearch]).cache
        else
            countries ||= Country.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        countries = Kaminari.paginate_array(countries).page(page).per(per_page)
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