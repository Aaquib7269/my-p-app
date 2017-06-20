class StatesDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view)
        @view = view
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: states.count.to_i,
            iTotalDisplayRecords: states.total_count,
            aaData: data
        }
    end

    private

    def data
        states.each_with_index.map do |state, index|
            [
                index+1,
                state.name,
                state.country.blank? ? "" : state.country.name,
                state.created_at.blank? ? "" : state.created_at.strftime('%A %d %B, %Y'),
                link_to("<i class='fa fa-edit'></i>".html_safe, url_helpers.edit_state_path(state), { :class => "btn bg-orange btn-xs" }) + " " +link_to("<i class='fa fa-trash'></i>".html_safe, state, {method: :delete, :data => {confirm: 'Are you sure?'}, :class => "btn bg-orange btn-xs"}),
                state.id.to_s,
            ]
        end
    end

    def states
        @states ||= fetch_states
    end

    def fetch_states
        if params[:sSearch].present?
            states ||= State.search(params[:sSearch]).cache
        else
            states ||= State.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        states = Kaminari.paginate_array(states).page(page).per(per_page)
    end

    def page
        params[:iDisplayStart].to_i/per_page + 1
    end

    def per_page
        params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
    end

    def sort_column
        columns = %w[name country_name]
        columns[params[:iSortCol_0].to_i]
    end

    def sort_direction
        params[:sSortDir_0] == "desc" ? "desc" : "asc"
    end
end