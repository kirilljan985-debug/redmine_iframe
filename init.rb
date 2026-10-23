# encoding: utf-8
# Плагин «Веб-окно» для Redmine: окно (iframe) с любой веб-страницей.
#
# Два способа:
# 1) wiki-макрос {{web_window(url, height=N)}} — штатный механизм макросов
#    Redmine, работает без зависимостей: в блоке «Текст» дашбордов
#    additionals, в вики-страницах, в тексте приветствия;
# 2) блок «Веб-страница (окно)» в дашбордах additionals («Добавить блок»,
#    в настройках — только ссылка) — подключается, если additionals
#    установлен и содержит систему блоков DashboardBlocks.
#
# Использование макроса:
#   {{web_window(http://192.168.1.50:8000)}}
#   {{web_window(http://192.168.1.50:8000, height=600)}}

# Блок дашбордов: подключаем только при установленном additionals
# (загружается раньше нас по алфавиту, поэтому installed? здесь уже видит его)
# и только если его система блоков реально доступна в этой версии.
# Любая несовместимость деградирует в «только макрос», а не роняет Redmine
# при старте.
if defined?(RedminePluginKit::Loader) &&
   defined?(DashboardBlocks::Base) &&
   defined?(DashboardContent) &&
   Redmine::Plugin.installed?(:additionals)
  begin
    loader = RedminePluginKit::Loader.new plugin_id: 'redmine_web_window'
    loader.extends %w[dashboard_blocks]
  rescue StandardError => e
    msg = "web_window: блок дашбордов не подключён, работает только макрос (#{e.class}: #{e.message})"
    Rails.logger ? Rails.logger.warn(msg) : warn(msg)
  end
end

Redmine::Plugin.register :redmine_web_window do
  name 'Веб-окно (встраиваемая страница)'
  author 'Отдел инженерии'
  description 'Окно-iframe с любой веб-страницей: блок «Веб-страница (окно)» в дашбордах additionals (в настройках — только ссылка) и макрос {{web_window(url, height=N)}} для блока «Текст», вики и текста приветствия'
  version '1.1.0'
end

Redmine::WikiFormatting::Macros.register do
  desc 'Окно (iframe) с другой веб-страницей: {{web_window(http://адрес, height=600)}}. height — высота окна в пикселях (100–3000), по умолчанию 485'
  macro :web_window do |obj, args|
    url = args[0].to_s.strip
    height = 485
    args.each do |a|
      if a.to_s =~ /\Aheight=(\d+)\z/
        height = Regexp.last_match(1).to_i
      end
    end
    height = 485 unless height.between?(100, 3000)

    if url.empty?
      next '<p class="hint">Веб-окно: укажите адрес страницы, например ' \
           '{{web_window(http://192.168.1.50:8000)}}}</p>'
    end
    unless url =~ %r{\Ahttps?://}i
      next '<p class="hint">Веб-окно: адрес должен начинаться с http:// или https://</p>'
    end

    safe_url = ERB::Util.html_escape(url)
    '<iframe src="' + safe_url + '" loading="lazy" ' \
    'style="width:100%;height:' + height.to_s + 'px;border:1px solid #c0c0c0;' \
    'border-radius:3px;background:#fff"></iframe>'
  end
end
