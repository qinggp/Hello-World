# UI部品の基底クラス
class Mars::UI::Element

  # initialize に渡される options に関するエラー
  class OptionError < StandardError; end

  attr_reader :name, :visibility, :element_set_id

  def initialize(name, options = {})
    @name= name
    @visibility = [options[:for], options[:visibility]].flatten.compact
    @visibility = [:all] if @visibility.empty?
    @element_set_id = options[:element_set_id]
  end

  # 表示可能なユーザか？
  def shown_for?(user)
    visibility.include?(:all) ||
      (visibility.include?(:logged_in) && user) ||
      visibility.any? { |role| user.send("#{role}?") if user }
  end

  def display(view, options={})
    display_template(view, options) if shown_for?(view.current_user)
  end

  private

  def display_template(view, options={})
    raise NotImplementedError
  end

  # 必要なoptionsのキーがあるかチェックする
  def check_requirement_options(options, *requirements)
    requirements.each do |key|
      raise(OptionError, "require :#{key.to_s} key for options to add method") unless options.has_key?(key)
    end
  end
end
