module TracksHelper
  def split_number_list_for_select
    list = %w(100 1000 10000).map do |n|
      ["#{number_with_delimiter n}件ごと", n]
    end
    list.unshift(["---", nil])
  end
end
