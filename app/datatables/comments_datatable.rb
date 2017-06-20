class CommentsDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view, product)
        @view = view
        @product = product
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: comments.count.to_i,
            iTotalDisplayRecords: comments.total_count,
            aaData: data
        }
    end

    private

    def data
        comments.each_with_index.map do |comment, index|
            [
                index+1,
                comment.comment_text,
                comment.user.full_name,
                comment.show_on_app == true ? "Yes" : "No",
                comment.formatted_created_at,
                comment.id.to_s
            ]
        end
    end

    def comments
        @comments ||= fetch_comments
    end

    def fetch_comments
        if params[:sSearch].present?
            comments ||= @product.comments.search(params[:sSearch]).cache
        else
            comments ||= @product.comments.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        comments = Kaminari.paginate_array(comments).page(page).per(per_page)
    end

    def page
        params[:iDisplayStart].to_i/per_page + 1
    end

    def per_page
        params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
    end

    def sort_column
        columns = %w[comment_text]
        columns[params[:iSortCol_0].to_i]
    end

    def sort_direction
        params[:sSortDir_0] == "desc" ? "desc" : "asc"
    end
end