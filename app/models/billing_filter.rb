class BillingFilter < ActiveRecord::Base
  def self.columns() @columns ||= []; end

  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :start_date, :date
  column :end_date, :date
  column :closed, :boolean

  validate :start_date_is_date
  validate :end_date_is_date
  validate :dates_are_in_order

  after_initialize :set_default_dates

  def set_default_dates
    self.start_date ||= Time.now.beginning_of_month.strftime("%Y-%m-%d")
    self.end_date   ||= Time.now.end_of_month.strftime("%Y-%m-%d")
  end


  def is_date(value)
    value =~ /^\d{4}-\d{2}-\d{2}$/ && begin; value.to_date; rescue; false end
  end

  def start_date_is_date
    return if start_date.nil?
    #errors.add("The start date is not a date.") unless is_date(start_date)
  end

  def end_date_is_date
    return if end_date.nil?
    #errors.add("The end data is not a date.") unless is_date(end_date)
  end

  def dates_are_in_order
    return if start_date.nil? || end_date.nil?
    errors.add(:end_date, " cannot be before start date.") unless start_date <= end_date
  end
end