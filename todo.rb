require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/content_for"

#activate sessions in sinatra
#secret verifys the data in the session

configure do 
  enable :sessions
  set :session_secret, 'secret'
end

before do 
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

#View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do 
  erb :new_list, layout: :layout
end

def error_for_list_name(name)
  if !name.size.between?(1,100)
    "The list name must be between 1 and 100 characaters"
  elsif session[:lists].any? { |list| list[:name] == name }
    "list name must be unique"
  end
end
    

#Create a new list
post "/lists" do 
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: []}
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

post "/edit/:id" do
  id = params[:id].to_i
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists][id] = { name: list_name, todos: []}
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

get "/lists/:id" do
  id = params[:id].to_i
  @id = id
  @list = session[:lists][id]
  params[:id]
  erb :list, layout: :layout
end

get "/edit/:id" do
  id = params[:id].to_i
  @id = id
  @list = session[:lists][id]
  params[:id]
  erb :edit, layout: :layout
end