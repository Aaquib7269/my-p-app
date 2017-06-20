class UsersDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view)
        @view = view
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: users.count.to_i,
            iTotalDisplayRecords: users.total_count,
            aaData: data
        }
    end

    private

    def data
        users.each_with_index.map do |user, index|
            [
                index+1,
                user.full_name,
                user.email_address,
                user.products.count,
                user.is_premium? ? "Yes" : "No",
                user.created_at.blank? ? "" : user.created_at.strftime('%A %d %B, %Y'),
                link_to("<i class='fa fa-eye'></i>".html_safe, url_helpers.user_path(user), { :class => "btn bg-orange btn-xs" }),
                user.id.to_s,
            ]
        end
    end

    def users
        @users ||= fetch_users
    end

    def fetch_users
        if params[:sSearch].present?
            users ||= User.search(params[:sSearch]).cache
        else
            users ||= User.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        users = Kaminari.paginate_array(users).page(page).per(per_page)
    end

    def page
        params[:iDisplayStart].to_i/per_page + 1
    end

    def per_page
        params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
    end

    def sort_column
        columns = %w[email first_name last_name]
        columns[params[:iSortCol_0].to_i]
    end

    def sort_direction
        params[:sSortDir_0] == "desc" ? "desc" : "asc"
    end
end