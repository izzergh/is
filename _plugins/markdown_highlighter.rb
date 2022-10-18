# frozen_string_literal: true

# taken & tweaked from maximevaillancourt/digital-garden-jekyll-template

# Turns ==something== in Markdown to <mark>something</mark> in output HTML

Jekyll::Hooks.register [:posts], :post_convert do |doc|
  replace(doc)
end

Jekyll::Hooks.register [:pages], :post_convert do |doc|
  # jekyll considers anything at the root as a page,
  # we only want to consider actual pages
  next unless doc.path.start_with?('_pages/')

  replace(doc)
end

def replace(doc)
  # TODO: is the bang necessary? Find out with trial & error
  doc.content.gsub!(/==+([^ ](.*?)?[^ .=]?)==+/, '<mark>\\1</mark>')
end
