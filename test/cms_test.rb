ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
require "rack/test"
require "fileutils"

Minitest::Reporters.use!

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
    
  end
  
  def teardown
    FileUtils.rm_rf(data_path)
  end
  
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { user: "admint" } }
  end

  def test_index
    get "/signin", {}, admin_session
    
    create_document "about.md"
    create_document "changes.txt"
    
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    
  end
  
  def test_viewing_text_document
    create_document "history.txt", "Ruby 0.95 released"
    
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby 0.95 released"
  end
  
  def test_viewing_markdown_document
    create_document "about.md", "# Ruby is..."
    
    get "/about.md"
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end
  
  def test_document_not_found
    get "/notafile.ext"
    
    assert_equal 302, last_response.status
    assert_equal "notafile.ext does not exist.", session[:message]
  end
  
  def test_editing_document
    create_document "changes.txt"
    get "/changes.txt/edit", {}, { "rack.session" => { user: "admin"} }
    
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end
  
  def test_updating_document
    get "/signin", {}, admin_session

    post "/changes.txt", content: "new content"

    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated.", session[:message]

    get last_response["Location"]
    
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
  
  def test_view_new_document_form
    get "/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create_new_document
    get "/signin", {}, admin_session
    
    post "/create", filename: "test.txt"
    assert_equal 302, last_response.status
    
    assert_equal "test.txt has been created.", session[:message]

    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_without_filename
    post "/create", { filename: "" }, { "rack.session" => { user: "admin"} }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_deleting_document
    create_document("test.txt")

    post "/test.txt/delete", {}, { "rack.session" => { user: "admin"} }

    assert_equal 302, last_response.status
    
    assert_equal "test.txt has been deleted.", session[:message]
    get last_response["Location"]
    
    get "/"
    refute_includes last_response.body, "test.txt"
  end

  def test_signin_form
    get "/", {}, { "rack.session" => { user: "admin"} }

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_signin
    get "/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:user]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_signin_with_bad_credentials
    get "/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_signout
    get "/", {}, {"rack.session" => { user: "admin" } }
    assert_includes last_response.body, "Signed in as admin"

    get "/signout"
    assert_equal "You have been signed out.", session[:message]

    get last_response["Location"]
    assert_nil session[:username]
    assert_includes last_response.body, "Sign In"
  end

  def test_visit_edit_page_signed_out
    get "/:filename/edit"
    
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
    end
    
    def test_submit_changes_signed_out
      post "/:filename"
      
      assert_equal 302, last_response.status
      assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_visit_new_document_page_signed_out

  end

  def test_submit_new_document_signed_out
    
  end

  def test_delete_document_signed_out

  end
end

