# frozen_string_literal: true

module Jekyll
  # Custom filter to titleize lowercase strings separated by spaces
  module TitleizeFilter
    # Off the dome. NOT exhaustive.
    TITLE_SMALLS = %w[
      a
      and
      for
      of
      the
      to
      with
    ].freeze

    def titleize(input)
      title = input.split(/\s+/).each do |word|
        small_is_good?(word) ? word.downcase! : word.capitalize!
      end.join(' ')

      title[0].upcase + title[1..]
    end

    def small_is_good?(word)
      TITLE_SMALLS.include?(word.downcase)
    end
  end
end

Liquid::Template.register_filter(Jekyll::TitleizeFilter)
