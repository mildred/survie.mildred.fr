
class Nanoc3::Item
  attr_accessor :page_items
  attr_accessor :page_parent
  attr_accessor :sub_pages
  
  def paginated?
    not page_items.nil? and not page_items.empty? and page_parent.nil?
  end
end

module Paginate

  def items_of_kind(kind, it = nil)
    it = items if it.nil?
    it.select { |i| i[:kind] == kind }
  end
  
  def paginated_items(items)
    items.select { |i| i.paginated? }
  end
  
  def create_pages
    items.select { |i| not i[:index_kind].nil? }.each do |index|
      index.page_items = items_of_kind(index[:index_kind], items).sort { |x, y| x[:created_at] <=> y[:created_at] }
    end
    paginated_items(items).each do |item|
      #puts "Paginate #{item.identifier}"
      page_size = item[:page_size] or 10
      # TODO: use config file
      groups = []
      elements = Array.new(item.page_items)
      item.sub_pages = []
      
      # Group items into pages
      until elements.size <= page_size
        groups << elements.shift(page_size)
      end
      groups << elements
      
      groups.each_with_index do |group, i|
        first = i*page_size
        last  = first + group.size - 1

        it = Nanoc3::Item.new(
          item.raw_content,
          item.attributes.merge({
           :paginate   => true,
           :page       => i + 1,
           :first_item => first,
           :last_item  => last,
           :num_pages  => groups.size}),
          "%s%d/" % [item.identifier, i+1])
        it.page_items = group
        it.page_parent = item
        item.sub_pages[i+1] = it
        items << it
        #puts " - #{it.identifier}"
      end
      item[:num_pages] = groups.size
      item[:paginate] = false
    end
  end
  
end

include Paginate

