module ScraperKit
  class ScraperScope
    attr_reader :recipe, :scraper_type, :doc, :url

    def initialize(recipe, type, doc, url)
      @recipe = recipe
      @scraper_type = type
      @doc = doc
      @url = url
    end

    # Get the target URL, and send it to another scraper
    #
    # url - URL to be get
    #
    # @return return the scraped result if succeed. return a hash with one key :error if failed.
    def get(url)
      html = IGHTMLQuery::HTTP.get(url)
      if html
        doc = (scraper_type == :text) ? html : HTMLDoc.new(html)
        if doc
          scraper = recipe.scraper_for_url(url)
          if scraper
            scraper.scrape(doc, url)
          else
            {:error => "scraper not found for url: #{url}, recipe: #{recipe}"}
          end
        else
          {:error => "failed processing html"}
        end
      else
        {:error => "failed fetching html from url: #{url}"}
      end
    end
  end

  class Scraper
    attr_reader :url, :recipe, :type

    # recipe - the recipe object
    # url - regexp to the URL support by this scraper
    # type - scraper type, it is either :html or :plain
    #    :text - document as String is passed to the scraper block
    #    :html - document converted to XMLNode is passed to scraper block
    # block - a block to setup the scraper
    def initialize(recipe, url, type=:html, &block)
      @recipe = recipe
      @url = url
      @type = type

      raise ArgumentError.new("Scraper requires a block") unless block_given?
      @scraper_block = block
    end

    def scrape(doc, url)
      ScraperScope.new(recipe, type, doc, url).instance_eval(&@scraper_block)
    end

  end
end