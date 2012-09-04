require File.dirname(File.expand_path(__FILE__)) + '/../test_helper'

class BillingHoursTest < ActiveSupport::TestCase
  include IssueBillingHelper

  def test_under_half_to_half_hour
    [0.12, 0.45, 0.30, 0.25, 0.50].each do |i|
      assert_equal 0.5, get_billable_hours(i), "Not increasing to half hour for #{i.to_s}."
    end
  end

  def test_return_if_exact_quarter_over_half
    [1.25, 10.5, 1.75, 9.00, 0.75].each do |i|
      assert_equal i, get_billable_hours(i), "Not return exact quarter when #{i.to_s}."
    end
  end

  def test_return_round_up_quarter_over_half
    [[0.78, 1.0], [10.67, 10.75], [5.01, 5.25]].each do |i|
      assert_equal i[1], get_billable_hours(i[0]), "Not return exact quarter when #{i[0].to_s}."
    end
  end

end