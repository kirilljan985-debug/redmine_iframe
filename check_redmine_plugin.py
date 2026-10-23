# -*- coding: utf-8 -*-
"""Проверка плагина «Веб-окно» для Redmine (R1, вариант 2 — макрос).

Плагин живёт вне репозитория портала (по решению заказчика) — эта папка
и есть его источник. Запуск проверки: python check_redmine_plugin.py

Проверяется: состав файлов, регистрация плагина и макроса {{web_window}},
валидация адреса в макросе (только http/https, экранирование), офлайн-
инвариант (никаких внешних URL — только LAN-примеры) и синтаксис Ruby,
если на машине установлен ruby.
"""

import re
import shutil
import subprocess
import unittest
from pathlib import Path

BASE = Path(__file__).resolve().parent
# Скрипт работает в двух раскладках: лежит рядом с папкой плагина (рабочая
# папка на рабочем столе) или внутри самого плагина (так он выложен на GitHub).
if (BASE / 'init.rb').is_file():
    PLUGIN = BASE
else:
    PLUGIN = BASE / 'redmine_web_window'

# Разрешены LAN-примеры, плейсхолдеры, тестовый example.com и ссылки на
# собственный репозиторий и источник additionals (только CI-шаг установки).
ALLOWED_URL_PREFIXES = ('http://192.168.', 'http://localhost', 'http://<',
                        'http://адрес', 'http://example.com',
                        'https://github.com/kirilljan985-debug/',
                        'https://github.com/alphanodes/')

EXPECTED_FILES = (
    'init.rb',
    'README.md',
    'lib/dashboard_blocks/web_window_block.rb',
    'app/views/dashboards/blocks/_web_window.html.erb',
    'config/locales/en.yml',
    'config/locales/ru.yml',
    'test/test_helper.rb',
    'test/unit/web_window_macro_test.rb',
    'test/unit/web_window_block_test.rb',
    '.github/workflows/test.yml',
)


class TestRedminePlugin(unittest.TestCase):

    def read(self, rel):
        return (PLUGIN / rel).read_text(encoding='utf-8')

    def test_composition(self):
        for rel in EXPECTED_FILES:
            self.assertTrue((PLUGIN / rel).is_file(), 'нет файла: %s' % rel)

    def test_registers_plugin_and_macro(self):
        init = self.read('init.rb')
        self.assertIn('Redmine::Plugin.register :redmine_web_window', init)
        self.assertIn('Redmine::WikiFormatting::Macros.register', init)
        self.assertIn("macro :web_window", init)

    def test_dashboard_block_is_gated_on_additionals(self):
        init = self.read('init.rb')
        # блок подключается только при установленном additionals
        self.assertIn('Redmine::Plugin.installed?(:additionals)', init)
        # и не может уронить Redmine при старте: проверка возможностей
        # системы блоков + rescue с деградацией в «только макрос»
        self.assertIn('defined?(DashboardBlocks::Base)', init)
        self.assertIn('rescue StandardError', init)
        self.assertIn("loader.extends %w[dashboard_blocks]", init)
        block = self.read('lib/dashboard_blocks/web_window_block.rb')
        self.assertIn("block_id 'web_window'", block)
        self.assertIn('setting :url', block)
        self.assertIn('required: true', block)
        self.assertIn('default: 485', block)

    def test_macro_validates_url(self):
        init = self.read('init.rb')
        # разрешены только http/https
        self.assertIn(r'%r{\Ahttps?://}i', init)
        # значение адреса экранируется перед вставкой в HTML
        self.assertIn('html_escape', init)
        # высота ограничена и имеет значение по умолчанию
        self.assertIn('height.between?(100, 3000)', init)
        self.assertIn('485', init)

    def test_readme_documents_usage(self):
        readme = self.read('README.md')
        self.assertIn('{{web_window(', readme)
        # инструкция про размещение окна в дашбордах additionals
        self.assertIn('additionals', readme.lower())
        self.assertIn('plugins', readme)

    def test_offline_only_urls(self):
        for path in PLUGIN.rglob('*'):
            if not path.is_file():
                continue
            if '.git' in path.parts:
                continue  # служебные файлы git-репозитория (бинарные)
            text = path.read_text(encoding='utf-8')
            for url in re.findall(r'https?://[^\s"\'<>)`]+', text):
                self.assertTrue(
                    url.startswith(ALLOWED_URL_PREFIXES),
                    '%s: внешний URL %s' % (path.name, url))

    @unittest.skipUnless(shutil.which('ruby'), 'ruby недоступен')
    def test_ruby_syntax(self):
        for rb in sorted(PLUGIN.rglob('*.rb')):
            subprocess.run(
                ['ruby', '-c', str(rb)],
                check=True, capture_output=True)


if __name__ == '__main__':
    unittest.main()
