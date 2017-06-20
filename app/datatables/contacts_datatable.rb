class ContactsDatatable
    delegate :params, :h, :link_to, :number_to_currency, to: :@view
    delegate :url_helpers, to: 'Rails.application.routes'

    def initialize(view)
        @view = view
    end

    def as_json(options = {})
        {
            sEcho: params[:sEcho].to_i,
            iTotalRecords: contacts.count.to_i,
            iTotalDisplayRecords: contacts.total_count,
            aaData: data
        }
    end

    private

    def data
        contacts.each_with_index.map do |contact, index|
            [
                index+1,
                contact.full_name,
                contact.email_address,
                contact.created_at.blank? ? "" : contact.created_at.strftime('%A %d %B, %Y'),
                link_to("<i class='fa fa-edit'></i>".html_safe, url_helpers.edit_contact_path(contact), { :class => "btn bg-orange btn-xs" }) + " " +link_to("<i class='fa fa-trash'></i>".html_safe, contact, {method: :delete, :data => {confirm: 'Are you sure?'}, :class => "btn bg-orange btn-xs"}),
                contact.id.to_s,
            ]
        end
    end

    def contacts
        @contacts ||= fetch_contacts
    end

    def fetch_contacts
        if params[:sSearch].present?
            contacts ||= Contact.search(params[:sSearch]).cache
        else
            contacts ||= Contact.order_by([:"#{sort_column}", :"#{sort_direction}"]).cache
        end
        contacts = Kaminari.paginate_array(contacts).page(page).per(per_page)
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