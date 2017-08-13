require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

# activate sessions in sinatra
# secret verifies the data in the session
configure do
  enable :sessions
  set :session_secret, 'secret'
end

# initialize new session if none exist
before do
  session[:lists] ||= []
end

# root url
get "/" do
  redirect "/lists"
end

# view list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# view one list
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  params[:id]
  erb :list, layout: :layout
end

# render the edit list form
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit, layout: :layout
end

# create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

# update list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  error = error_for_list_name(list_name)

  if error
    @list = session[:lists][id]
    session[:error] = error
    erb :edit, layout: :layout
  else
    session[:lists][id][:name] = list_name
    session[:success] = "The list has been updated"
    redirect "/lists/#{id}"
  end
end

# delete list
post "/lists/:id/delete" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list had been deleted."
  redirect "/lists"
end

# create a todo for a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  error = error_for_todo(text)

  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: text, complete: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

# Error handling helper functions
def error_for_list_name(name)
  if !name.size.between?(1,100)
    "List name must be between 1 and 100 characaters"
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique"
  end
end

def error_for_todo(name)
  if !name.size.between?(1,100)
    "Todo name must be between 1 and 100 characaters"
  end
end
