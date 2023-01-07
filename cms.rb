require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
end

root = File.expand_path("..", __FILE__)

before do
  @file_paths = Dir.glob(root + "/data/*")
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
    headers["Content-Type"] = "text/html"
    @file_contents = File.readlines(file_path)
    erb :file
  else
    session[:error] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end
