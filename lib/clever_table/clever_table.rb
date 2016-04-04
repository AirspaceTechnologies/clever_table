module CleverTable
  class CleverTable
    attr_reader :data, :options, :fields, :params, :columns, :count, :pages, :per_page

    PER_PAGE     = 20
    PAGES_BESIDE = 3

    def initialize(data, params, fields)
      @fields        = fields
      @options       = @fields.extract!(:no_sort, :sort_names, :lists, :row_link, :unique, :controller, :per_page)
      @params        = params
      @view          = ActionView::Base.new('app/views', {}, @options[:controller])
      @original_data = data
      @per_page      = @options[:per_page] || PER_PAGE


      @data          = filter(data)

      ActionView::Base.send(:define_method, :protect_against_forgery?) { false }
      ActionView::Base.send :include, Rails.application.routes.url_helpers
    end

    def filter(data)
      paginate(query(sort(data)))
    end

    def render
      @columns = @data.columns
      @data    = @data.reverse if should_invert_sort?
      count    = get_count
      if data.count > 0
        render_query_ui.html_safe +
            render_head.html_safe +
            (@data.map do |datum|
              render_row(datum).html_safe
            end * "\r").html_safe +
            render_tail.html_safe
      else
        '<No data>'
      end
    end

    def pagination
      pagination_ui(data)
    end

    def get_sort_direction(v, col_title)
      inverted_sort_direction if sorting?(col_name(v, col_title))
    end

    def sortable?(fld)
      !(options[:no_sort]) || !options[:no_sort].include?(fld)
    end

    def list?(name)
      options[:lists] && options[:lists].keys.include?(name)
    end

    def list_args(name)
      options[:lists][name].to_json
    end

    def constrained?(name)
      params.any? { |k, v| k.starts_with?(name) }
    end

    def constrained_class(name)
      constrained?(name.underscore) ? 'constrained' : ''
    end

    def column_type(name)
      if list?(name)
        return 'list'
      end
      n = name.to_s
      n = sort_names[n] || n
      @columns.each do |col|
        if col.name == n
          return col.type
        end
      end

      return nil
    end

    def with_constraints
      params.each do |pn, pv|
        split = /(.*)_(.*)/.match(pn)
        if split
          name     = split[1]
          operator = split[2]

          fld = fields.detect { |k, v| v.to_s == name }

          #Interpolation puts quotes around strings which won't work for column names.
          #So check if it's just a name and insert it
          if fld && /\w*/.match(name)
            yield name, operator, operator_map[operator], pv
          end
        end
      end
    end


    private

    #We add the fields in the 'unique' option if provided, to ensure a well-ordering
    def sort(data)
      if should_invert_sort?
        dir = inverted_sort_direction
      else
        dir = sort_direction
      end

      sfs         = sort_fields
      sort_string = if sfs
                      sfs.map { |p| "#{p} #{dir}" } * ', '
                    else
                      ''
                    end

      data.reorder sort_string
    end

    def sort_fields
      ([*sort_field]) + unique_fields
    end

    def sort_values(datum)
      sort_fields.map { |f| normalize(datum.send f) }
    end

    def normalize(datum)
      (datum.is_a? ActiveSupport::TimeWithZone) ? datum.utc : datum
    end

    def unique_fields
      [*options[:unique]] - ([*sort_field])
    end

    def operator_query(data, name, value, op)
      data.where('? ? ?', name, op, value)
    end

    def operator_map
      {
          'eq'   => '=',
          'neq'  => '<>',
          'lt'   => '<',
          'lte'  => '<=',
          'gt'   => '>',
          'gte'  => '>=',
          'dtlt' => '<',
          'dtgt' => '> '
      }
    end

    def query(data)
      executors = {
          'strt' => ->(data, name, value) { data.where("#{name} LIKE ?", "#{value}%") },
          'cont' => ->(data, name, value) { data.where("#{name} LIKE?", "%#{value}%") },
          'betw' => ->(data, name, value) { data.where("#{name} BETWEEN ? AND ?", value[0], value[1]) }
      }
      with_constraints do |name, operator, op_name, value|
        if op = operator_map[operator]
          data = data.where("#{name} #{op} ?", value)
        elsif fn = executors[operator]
          data = fn[data, name, value]
        end
      end

      @data  = data
      @count ||= get_count
      @pages = (@count / per_page.to_f).ceil
      @data
    end

    def get_count
      @data.count
    rescue ActiveRecord::StatementInvalid
      #Be dumb if something goes wrong
      @data = query(sort(@original_data))
      @data = just_go_to_page
      @data.count
    end

    def paginate(data)
      page = page_param
      return data.limit per_page if last_page? || first_page?

      sfs = sort_fields

      if params['after']
        order_symbol = sort_ascending? ? '>' : '<'
        prior_values = params['after']
        #Row value comparisons fail in the presence of nulls
        prior_values += params['after'][1..-1] #Duplicate just unique values
      elsif params['before']
        order_symbol = sort_ascending? ? '<' : '>'
        prior_values = params['before']
        #Row value comparisons fail in the presence of nulls
        prior_values += params['before'][1..-1] #Duplicate just unique values
      else
        prior_values = nil
        order_symbol = nil
      end
      if order_symbol
        # where_string = "(#{sfs * ','}) #{order_symbol} (#{(['?'] * sfs.count) * ', '})"
        where_string = "(#{sfs * ','}) #{order_symbol} (#{(['?'] * sfs.count) * ', '})
        OR
          (#{sort_field} IS NULL AND (#{unique_fields * ', '}) #{order_symbol} (#{(['?'] * (sfs.count - 1)) * ', '}))"

        where = data.where([where_string, *prior_values])
      else
        return just_go_to_page
      end

      where.limit per_page
    end

    def just_go_to_page
      if params['page']
        where = data.offset [(params['page'].to_i - 1), 0].max * per_page
      else
        where = data
      end

      where.limit per_page
    end

    def page_param
      result = params['page']
      return 1 unless result
      result == 'last' ? result : result.to_i
    end

    def render_query_ui
      render_file('clever_table/_query_ui.html.erb', source: self)
    end

    def render_head
      render_file('clever_table/_generic_header.html.erb', source: self)
    end

    def render_tail
      render_file('clever_table/_generic_tail.html.erb', source: self)
    end

    def render_row(datum)
      if options[:row_link]
        "<tr class=\"pointer\" onclick=\"window.location='#{options[:row_link][datum]}'\"> #{fields.map { |k, v| render_cell(datum, v, k.downcase) } * ''}</tr>"
      else
        "<tr>#{fields.map { |k, v| render_cell(datum, v, k.downcase) } * ''}</tr>"
      end
    end

    def sort_names
      options[:sort_names] || {}
    end

    def render_cell(datum, v, col_title)
      if v.is_a? Symbol
        value = datum.send v rescue nil
      else
        value = v[datum]
      end
      if value.is_a? ActiveSupport::TimeWithZone
        result = value.to_s(:short)
      else
        result = CGI.unescape(value.to_s)
      end

      "<td>#{result}</td>"
    end

    def render_file(file, data = {})
      @view.render(file: file, locals: data).html_safe
    end

    def pagination_ui(data)
      goto_beginning_ui + previous_ui(data) + pages_ui(data) + next_ui(data) + goto_end_ui
    end

    def goto_beginning_ui
      render_file 'clever_table/goto_beginning.html.erb', url: get_simple_url(params.merge page: 1)
    end

    def goto_end_ui
      render_file 'clever_table/goto_end.html.erb', url: get_simple_url(page: 'last')
    end

    def previous_ui(data)
      render_file 'clever_table/previous.html.erb', data: data, url: previous_page_url
    end

    def next_ui(data)
      render_file 'clever_table/next.html.erb', data: data, url: next_page_url
    end

    def pages_ui(data)
      # render_file 'clever_table/pages_ui.html.erb', data: data, url: get_url
      (last_page? ? @pages.to_s : page_param.to_s) + '/' + @pages.to_s
    end

    def get_url(merge={})
      controller.url_for(params.merge(page: page_param).merge(merge))
    end

    def get_simple_url(merge = {})
      params.delete(:before)
      params.delete(:after)
      controller.url_for params.merge(page: page_param).merge(merge)
    end

    def next_page_url
      p = page_param
      return get_simple_url(page: 'last') if p == 'last'

      get_simple_url page: page_param + 1, after: sort_values(data.last)
        #In obscure cases involving nulls, the above can fail. Go to simpler pagination in this case
    rescue
      get_simple_url page: page_param + 1
    end

    def previous_page_url
      p = page_param

      return get_simple_url(page: 1) if p != 'last' && p <= 2
      return get_simple_url(page: pages - 1) if p == 'last' || p >= pages

      get_simple_url page: page_param - 1, before: sort_values(data.first)
        #In obscure cases involving nulls, the above can fail. Go to simpler pagination in this case
    rescue
      get_simple_url page: page_param - 1
    end

    def controller
      options[:controller]
    end

    def value(name, options)
      if datum.is_a? ActiveSupport::TimeWithZone
        datum.to_s(:short)
      else
        datum
      end
    end

    def sort_field
      s          = params['sort']
      sort_names = options[:sort_names]
      return sort_names[s] if sort_names
      return s
    end

    def sort_direction
      #sanitize
      params['dir'] == 'desc' ? 'desc' : 'asc'
    end

    def sort_ascending?
      sort_direction == 'asc'
    end

    def col_name(value, col_title)
      if col_title.is_a? Symbol
        col_title.to_s
      else
        value.downcase
      end
    end

    def sorting?(col_name)
      params['sort'] == col_name
    end

    def inverted_sort_direction
      sort_direction == 'desc' ? 'asc' : 'desc'
    end

    def should_invert_sort?
      last_page? || params[:before]
    end

    def last_page?
      page_param == 'last' || page_param == pages
    end

    def first_page?
      page_param == 1
    end
  end
end