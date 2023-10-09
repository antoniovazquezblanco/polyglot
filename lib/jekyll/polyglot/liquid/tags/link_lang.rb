module Jekyll
  module Polyglot
    module Liquid
      class LinkLang < :: Liquid::Tag
        def initialize(tag_name, params, tokens)
          super
          @tag_name = tag_name
          params = params.strip
          @lang_param, @doc_path_param = params.split(%r!\s+!, 2)
        end

        def render(context)
          # Parse lang using context if needed...
          lang = ::Liquid::Template.parse("{{#@lang_param}}").render(context)
          if lang.empty? then lang = @lang_param end
          unless valid_lang(lang)
            raise ArgumentError, "\"#{lang}\" is not a valid language!"
          end
          
          # Parse doc_path using context if needed...
          doc_path = ::Liquid::Template.parse("{{#@doc_path_param}}").render(context)
          if doc_path.empty? then doc_path = @doc_path_param || context.environments.first["page"]["path"] end

          # Get site context
          site = context.registers[:site]

          # Get the page object corresponding to the page path...
          page = get_page_by_doc_path(doc_path, site)
          unless page
            raise ArgumentError, "#{@tag_name} could not locate #{doc_path} in among your language pages! Please provide a file available in your lang..."
          end

          # Get the target page url...
          target_page_url = get_page_translation_url(site, page, lang)
          unless target_page_url
            raise ArgumentError, "#{@tag_name} could not locate a \"#{lang}\" translation for  \"#{doc_path}\" among your files! Please review if it is present and if \"lang_id\" variables need to be set..."
          end

          # Return the info
          return target_page_url
        end

        def valid_lang(lang)
          return lang.match(%r![a-z]{2}(-[A-Z]{2})?!)
        end

        def get_page_by_doc_path(doc_path, site)
          relative_path_with_leading_slash = PathManager.join("", doc_path)
          site.each_site_file do |item|
            return item if item.relative_path == doc_path
            # This takes care of the case for static files that have a leading /
            return item if item.relative_path == relative_path_with_leading_slash
          end
          return nil
        end

        def get_page_translation_url(site, page, lang)
          page_lang_id = page['lang_id']
          unless page_lang_id then return page.url end
          if page_lang_id.empty? then return page['permalink'] end
          page_lang_urls = site.file_lang_urls[page_lang_id]
          unless page_lang_id then return nil end
          url = page_lang_urls[lang] || page_lang_urls[site.default_lang]
          return url
        end
      end
    end
  end
end

Liquid::Template.register_tag('link_lang', Jekyll::Polyglot::Liquid::LinkLang)
