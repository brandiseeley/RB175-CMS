require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'pathname'

configure do
  enable :sessions
end

root = File.expand_path("..", __FILE__)

before do
  @file_paths = Dir.glob(root + "/data/*")
end

def suffix(filename)
  point_index = filename.index(".")
  filename[point_index..-1]
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/html"
    content
  when ".md"
    render_markdown(content)
  end
end

get "/" do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index
end

get "/:filename" do
  file_path = root + "/data/" + params[:filename]
  
  if File::file?(file_path)
    @file_content = load_file_content(file_path)
    erb :file
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  @filename = params[:filename]
  @file_path = root + "/data/" + @filename
  @file_content = load_file_content(@file_path)
  erb :edit_file
end

post "/:filename" do
  file_path = root + "/data/" + params[:filename]

  File.write(file_path, params[:new_content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end
