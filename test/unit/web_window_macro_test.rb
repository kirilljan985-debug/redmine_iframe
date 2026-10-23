# frozen_string_literal: true

# Тестовое окружение Redmine (тестовые ассерты, fixture-пути).
require File.expand_path('../../test_helper', __FILE__)

# Тесты макроса {{web_window}}.
#
# Прогоняются на GitHub Actions внутри настоящего Redmine
# (rake redmine:plugins:test NAME=redmine_web_window).
#
# Макрос вызывается через штатный Redmine::WikiFormatting::Macros::Definitions
# #exec_macro — тот же путь диспетчеризации, что и при рендере страницы
# (поиск макроса в реестре, разбор арности, перехват ошибок).
class WebWindowMacroTest < ActiveSupport::TestCase
  setup do
    assert Redmine::WikiFormatting::Macros.available_macros.key?(:web_window),
           'макрос web_window не зарегистрирован плагином'
  end

  test 'renders iframe with given url and default height' do
    out = exec_macro('http://192.168.1.10:8000')
    assert_include '<iframe', out
    assert_include 'src="http://192.168.1.10:8000"', out
    assert_include 'height:485px', out
  end

  test 'renders iframe with custom height' do
    out = exec_macro('http://192.168.1.10:8000, height=600')
    assert_include 'height:600px', out
  end

  test 'clamps height into allowed range' do
    assert_include 'height:485px', exec_macro('http://example.com, height=10')
    assert_include 'height:3000px', exec_macro('http://example.com, height=9999')
  end

  test 'rejects non http(s) urls' do
    out = exec_macro('javascript:alert(1)')
    assert_not_include '<iframe', out
    assert_include 'https', out
  end

  test 'shows hint instead of iframe for empty url' do
    out = exec_macro('')
    assert_not_include '<iframe', out
  end

  test 'escapes url before inserting into html attribute' do
    out = exec_macro('http://example.com/"><script>alert(1)</script>')
    assert_not_include '<script>', out
    assert_include '&quot;', out
  end

  private

  # Объект, включающий модуль Definitions, — как у форматтера Redmine.
  def exec_macro(args_string)
    holder = Class.new do
      include Redmine::WikiFormatting::Macros::Definitions
    end.new
    holder.exec_macro('web_window', nil, args_string, nil)
  end
end
