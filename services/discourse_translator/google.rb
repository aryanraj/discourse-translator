require_relative 'base'
require 'json'

module DiscourseTranslator
  class Google < Base
    TRANSLATE_URI = "https://www.googleapis.com/language/translate/v2".freeze
    DETECT_URI = "https://www.googleapis.com/language/translate/v2/detect".freeze
    SUPPORT_URI = "https://www.googleapis.com/language/translate/v2/languages".freeze

    def self.access_token_key
      "google-translator"
    end

    def self.access_token
      SiteSetting.translator_google_api_key || (raise TranslatorError.new("NotFound: Google Api Key not set."))
    end

    def self.detect(post)
      post.custom_fields[DiscourseTranslator::DETECTED_LANG_CUSTOM_FIELD] ||=
        result(DETECT_URI,
          q: post.cooked
        )["detections"][0].max{ |a, b| a.confidence <=> b.confidence }["language"]
    end

    def self.translate_supported?(source, target)
      res = result(SUPPORT_URI,
        target: target
      )
      res["languages"].any? do |obj|
        obj["language"] == source
      end
    end

    def self.translate(post)
      detected_lang = detect(post)

      raise I18n.t('translator.failed') unless translate_supported?(detected_lang, I18n.locale)

      translated_text = from_custom_fields(post) do
        res = result(TRANSLATE_URI,
          q: post.cooked,
          source: detected_lang,
          target: locale
        )
        res["translations"][0]["translatedText"]
      end

      [detected_lang, translated_text]
    end

    def self.result(url, query)
      query[:key] = access_token
      response = Excon.get(url,
        query: query
      )

      body = JSON.parse(response.body)

      if response.status != 200
        raise TranslatorError.new(body)
      else
        body["data"]
      end
    end
  end
end
