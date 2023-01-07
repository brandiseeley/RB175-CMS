ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
require "rack/test"

Minitest::Reporters.use!

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_root
    get "/"
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "history.txt")
  end

  def test_viewing_text_document
    get "/about.txt"
    assert_equal(200, last_response.status)
    assert_equal("text/html", last_response["Content-Type"])
    assert_includes(last_response.body, "Here's some text that belongs to the 'about' file.")

    get "/changes.txt"
    assert_equal(200, last_response.status)
    assert_equal("text/html", last_response["Content-Type"])
    assert_includes(last_response.body, "Here's some text that belongs to the 'changes' file.\n")

    get "/history.txt"
    assert_equal(200, last_response.status)
    assert_equal("text/html", last_response["Content-Type"])
    assert_includes(last_response.body, "Here's some text that belongs to the 'history' file.\n")
  end

  def test_viewing_nonexistant_document
    get "/notafile.ext"
    assert_equal(302, last_response.status)
    assert_equal("", last_response.body)
    
    get last_response["Location"]

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "notafile.ext does not exist.")
    get "/"
    refute_includes(last_response.body, "notafile.ext does not exist.")
  end

  def test_viewing_markdown_document
    get "/samplemarkdown.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Markdown!</h1>"
  end
end
