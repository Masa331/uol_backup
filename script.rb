require 'bundler/inline'
require 'open-uri'

gemfile do
  source 'https://rubygems.org'
  gem 'rest-client'
  gem 'pry'
  gem 'json'
end

class UolApi
  @@subdomain = nil
  @@encoded_token = nil

  attr_accessor :json, :parsed, :endpoint

  def initialize(json, endpoint)
    @endpoint = endpoint
    @json = json
    @parsed = JSON.parse(@json)
  end

  # Returns page item which can be further queried
  def self.get(endpoint, page = nil)
    url = assemble_url(endpoint, page)
    authentication = "Basic #{UolApi.encoded_token}"

    response = RestClient.get(url, :Authorization => authentication )
    new response.body, endpoint
  end

  # Collects resource items from all pages and returns them in one array
  def self.collect(endpoint)
    current_page = get(endpoint)
    last_page = current_page.last_page

    results = current_page.items

    (last_page - 1).times do
      current_page = current_page.get_next_page
      results += current_page.items
    end

    results
  end

  def self.subdomain
    @@subdomain
  end
  def self.subdomain=(arg)
    @@subdomain = arg
  end

  def self.encoded_token
    @@encoded_token
  end
  def self.encoded_token=(arg)
    @@encoded_token = arg
  end

  def first_page
    extract_page_num dig('_meta', 'pagination', 'first')
  end

  def next_page
    extract_page_num dig('_meta', 'pagination', 'next')
  end

  def previous_page
    extract_page_num dig('_meta', 'pagination', 'previous')
  end

  def last_page
    extract_page_num dig('_meta', 'pagination', 'last')
  end

  def get_next_page
    self.class.get(endpoint, next_page)
  end

  def dig(*args)
    parsed.dig *args
  end

  def meta
    dig '_meta'
  end

  def items
    parsed['items']
  end

  private

  def self.assemble_url(endpoint, page = 1)
    pagination = "?page=#{page}"
    url = "https://#{UolApi.subdomain}.ucetnictvi.uol.cz/api/v1/#{endpoint}#{pagination}"
  end

  def extract_page_num(href)
    num = href&.scan(/page=(\d+)/)&.first&.first

    num.to_i if num
  end
end

### 1) Configure UolApi
UolApi.subdomain = 'test'
UolApi.encoded_token = '__token__' # <- already base64 encoded token with email as per api docs

### 2) Do your stuff
## eg. collect and save one specific endpoint as json:
# File.open('sales_invoices.json', 'wb') { |f| f.write UolApi.collect('sales_invoices').to_json }

## or collect most of important endpoints:
# endpoints = [
#   'sales_invoices',
#   'purchase_invoices',
#
#   'petty_cash_incomes',
#   'petty_cash_disburstments',
#
#   'retails',
#
#   'sales_orders',
#   'purchase_orders',
#
#   'contacts',
#   'products',
#   'contracts',
#   'petty_cashes',
#   'my_bank_accounts',
#   'contact_bank_accounts',
#   'departments'
# ]
# endpoints.each do |endpoint|
#   File.open("#{endpoint}.json", 'wb') { |f| f.write UolApi.collect(endpoint).to_json }
# end

## or download all uploaded documents with their's originals
# uploaded_documents = UolApi.collect('uploaded_documents')
# with_pairings = uploaded_documents.map do |doc|
#   id = doc['id']
#   UolApi.get("uploaded_documents/#{id}/pairings").parsed
# end
# File.open('uploaded_documents_with_pairings.json', 'wb') { |f| f.write with_pairings.to_json }
# File.open('uploaded_documents.json', 'wb') { |f| f.write uploaded_documents.to_json }
# uploaded_documents.each do |document|
#   uri = URI(document['file'])
#   file_name = uri.path.split('/').last
#
#   open(document['file']) do |content|
#     File.open("temp/#{file_name}", 'wb') { |f| f.write content.read }
#   end
# end

p 'cool!'
