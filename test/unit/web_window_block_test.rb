# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

# Блок «Веб-окно» в дашбордах additionals. Тесты выполняются только там,
# где установлен additionals (в CI — джоб с with_additionals: true).
class WebWindowBlockTest < ActiveSupport::TestCase
  setup do
    skip 'additionals не установлен' unless Redmine::Plugin.installed?(:additionals)
  end

  test 'block is offered on additionals dashboards' do
    content = DashboardContentWelcome.new
    assert DashboardBlocks.for(content).map(&:block_id).include?('web_window'),
           'блок web_window не попал в реестр блоков дашбордов'
  end

  test 'typed settings: url, height and default' do
    block = DashboardBlocks::WebWindowBlock.new(
      DashboardContentWelcome.new,
      settings: { 'url' => 'http://example.com/app', 'height' => '600' }
    )
    assert_equal 'http://example.com/app', block.url
    assert_equal 600, block.height

    fresh = DashboardBlocks::WebWindowBlock.new(DashboardContentWelcome.new)
    assert_equal 485, fresh.height
    assert_predicate fresh.url, :blank?
  end

  test 'fresh block without url counts as not set up' do
    fresh = DashboardBlocks::WebWindowBlock.new(DashboardContentWelcome.new)
    assert_predicate fresh, :new_block?,
                     'блок без ссылки должен считаться ненастроенным'
  end
end
