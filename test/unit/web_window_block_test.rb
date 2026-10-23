# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

# Блок «Веб-окно» в дашбордах additionals. Тесты адаптивны: выполняется
# та ветка, которая соответствует установленной версии additionals —
# классовая система (4.7+) или легаси-патч (4.0–4.6). В CI обе ветки
# покрываются матрицей по версиям additionals.
class WebWindowBlockTest < ActiveSupport::TestCase
  def modern_additionals?
    defined?(DashboardBlocks::Base) ? true : false
  end

  test 'dashboard block is registered in additionals dashboards' do
    skip 'additionals не установлен' unless Redmine::Plugin.installed?(:additionals)

    if modern_additionals?
      content = DashboardContentWelcome.new
      assert DashboardBlocks.for(content).map(&:block_id).include?('web_window'),
             'блок web_window не попал в реестр блоков дашбордов'
    else
      assert DashboardContent.ancestors.include?(RedmineWebWindow::Patches::DashboardContentPatch),
             'легаси-патч не подключён к DashboardContent'
      defs = DashboardContent.new.block_definitions
      assert defs.key?('web_window'), 'блока web_window нет в block_definitions'
      assert_equal 'dashboards/blocks/web_window', defs['web_window'][:partial]
      assert_equal 'dashboards/blocks/web_window_settings', defs['web_window'][:settings_partial]
      assert_equal 10, defs['web_window'][:max_occurs]

      # регрессия рестарт-лупа: файл класса блока обязан безопасно
      # загружаться без системы блоков (eager-загрузка production грузит
      # его независимо от версии additionals)
      assert_nothing_raised(NameError) do
        load File.expand_path('../../../lib/dashboard_blocks/web_window_block.rb', __FILE__)
      end
    end
  end

  test 'typed settings: url, height and default' do
    skip 'additionals не установлен' unless Redmine::Plugin.installed?(:additionals)
    skip 'легаси-версия additionals: типизация через SettingsSchema отсутствует' unless modern_additionals?

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
    skip 'additionals не установлен' unless Redmine::Plugin.installed?(:additionals)
    skip 'легаси-версия additionals: поведение new_block? отсутствует' unless modern_additionals?

    fresh = DashboardBlocks::WebWindowBlock.new(DashboardContentWelcome.new)
    assert_predicate fresh, :new_block?,
                     'блок без ссылки должен считаться ненастроенным'
  end
end
