# encoding: utf-8
# Плагин «Веб-окно» для Redmine: wiki-макрос {{web_window}} — окно (iframe)
# с любой веб-страницей. Окно можно вставить всюду, где Redmine рендерит
# вики-текст: в блок «Текст» дашбордов additionals (главная страница,
# обзор проекта), в вики-страницы, в текст приветствия.
#
# Использование:
#   {{web_window(http://192.168.1.50:8000)}}
#   {{web_window(http://192.168.1.50:8000, height=600)}
#
# Реализовано через штатный механизм макросов Redmine
# (Redmine::WikiFormatting::Macros) — без привязки к внутреннему API
# какой-либо версии additionals.

Redmine::Plugin.register :redmine_web_window do
  name 'Веб-окно (встраиваемая страница)'
  author 'Отдел инженерии'
  description 'Макрос {{web_window(url, height=N)}}: окно-iframe с любой веб-страницей. Вставляется в блок «Текст» дашбордов additionals, вики-страницы и текст приветствия'
  version '1.0.0'
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
