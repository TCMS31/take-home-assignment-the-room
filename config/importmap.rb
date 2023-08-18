# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'

# Shipped by the bootstrap gem; required for the navbar toggle and dismissible
# alerts, which are markup-only without it.
pin '@popperjs/core', to: 'popper.js', preload: true
pin 'bootstrap', to: 'bootstrap.min.js', preload: true
