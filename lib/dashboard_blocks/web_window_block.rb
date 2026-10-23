# frozen_string_literal: true

# Блок «Веб-окно» для дашбордов additionals: блок добавляется в дашборд,
# и в его настройках остаётся вписать только ссылку (и при желании высоту).
# Подгружается только при установленном additionals (см. init.rb) и требует
# его актуальную версию с системой блоков DashboardBlocks.
#
# Синхронный блок без async: сервер ничего не читает по сети — страницу
# в рамку грузит браузер пользователя, как у макроса {{web_window}}.
module DashboardBlocks
  class WebWindowBlock < Base
    block_id 'web_window'
    label :label_web_window
    max_occurs 10

    setting :title, **DashboardContent::TITLE_SETTING
    setting :url, type: :string, label: :field_url, required: true,
                  field: 'dashboards/settings/url'
    setting :height, type: :integer, label: :label_web_window_height,
                     min: 100, max: 3000, default: 485
  end
end
