# frozen_string_literal: true

Rails.application.routes.draw do
  match 'redmineup/settings/:id', to: 'redmineup#settings', as: 'redmineup_settings', via: [:get, :post]
  match 'auto_completes/taggable_tags' => 'auto_completes#taggable_tags',
        via: :get, as: 'auto_complete_taggable_tags'

  mount ActionCable.rup_server => '/rup_cable', as: 'rup_cable' if Redmineup.cable_available?
end
