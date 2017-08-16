require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

#activate sessions in sinatra
#secret verifys the data in the session

configure do 
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do 
  session[:lists] ||= []
end

helpers do 
  def list_complete?(list)
    list_size(list) > 0 && list_remaining(list) == 0
  end

  def list_class(list)
    list_complete?(list) ? 'complete' : ''
  end

  def list_size(list)
    list[:todos].size
  end

  def list_remaining(list)
    list[:todos].select { |item| !item[:completed] }.size
  end

  def sort_lists(lists, &block)
    completed_list, incompleted_list = lists. partition { |list| list_complete?(list) }

    incompleted_list.each { |list| yield list, lists.index(list)}
    completed_list.each { |list| yield list, lists.index(list)}
  end

  def sort_todos(todos, &block)
    completed_todos, incompleted_todos = todos.partition { |todo| todo[:completed] }

    incompleted_todos.each { |todo| yield todo, todos.index(todo)}
    completed_todos.each { |todo| yield todo, todos.index(todo)}
  end
end

HOMEPAGE = "/lists"

def error_for_list_name(name)
  if !name.size.between?(1,100)
    "The list name must be between 1 and 100 characaters"
  elsif session[:lists].any? { |list| list[:name] == name }
    "list name must be unique"
  end
end

def error_for_todo(name)
  if !name.size.between?(1,100)
    "The list name must be between 1 and 100 characaters"
  end
end

def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = "The specified list was not found"
  redirect "/list"
end

get "/" do
  redirect HOMEPAGE
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

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  params[:id]
  erb :list, layout: :layout
end

get "/lists/:id/edit" do
  id  = params[:id].to_i
  @list = load_list(id)
  erb :edit, layout: :layout
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
    redirect HOMEPAGE
  end
end

post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = load_list(id)

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @list = list_name
    session[:success] = "The list has been updated"
    redirect "/lists/#{id}"
  end
end

#Delete a todo list
post "/lists/:id/delete" do 
  id = params[:id].to_i
  session[:lists].delete_at(id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" #Rack preprends the header with HTTP
    "/lists"
  else
    session[:success] = "The list had been deleted."
    redirect HOMEPAGE
  end
end

post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, complete:false}
    session[:success] = "The item has been added."
    redirect "/lists/#{@list_id}"
  end
end

#Delete a todo from a list
post "/lists/:list_id/todos/:id/destroy" do 
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  todo_id = params[:id].to_i
  @list[:todos].delete_at todo_id
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" #Rack preprends the header with HTTP
    status 204
  else
    session[:success] = "The todo has been deleted"
    redirect "/lists/#{@list_id}"
  end
end

post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been completed"
  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  @list[:todos].each do |todo_id|
    todo_id[:completed] = true
  end

  session[:success] = "The todos have all been completed!!!"
  redirect "/lists/#{@list_id}"
end
