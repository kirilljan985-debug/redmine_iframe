# frozen_string_literal: true

# Легаси-поддержка дашбордов additionals 4.0–4.6 (без классовой системы
# DashboardBlocks, появившейся в 4.7): блок добавляется патчем
# DashboardContent#block_definitions по рецепту docs/dashboards.md
# соответствующей версии additionals.
module RedmineWebWindow
  module Patches
    module DashboardContentPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
      end

      module InstanceOverwriteMethods
        def block_definitions
          blocks = super
          blocks['web_window'] = {
            label: l(:label_web_window),
            partial: 'dashboards/blocks/web_window',
            settings_partial: 'dashboards/blocks/web_window_settings',
            max_occurs: 10
          }
          blocks
        end
      end
    end
  end
end
