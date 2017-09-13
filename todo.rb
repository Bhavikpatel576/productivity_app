require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"
require "pry"
require_relative "session_persistance"


#activate sessions in sinatra
#secret verifys the data in the session

configure do 
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  @storage = SessionPersistance.new(session)
end

helpers do 
  def list_size(list)
    list[:todos].size
  end

  def list_complete?(list)
    list_size(list) > 0 && list_remaining(list) == 0
  end

  def list_class(list)
    list_complete?(list) ? 'complete' : ''
  end

  #returns the amount of uncompleted todo items within a list
  def list_remaining(list)
    list[:todos].select { |item| !item[:completed] }.size
  end

  #divides the lists into completed items and incompleted items
  def sort_lists(lists, &block)
    completed_list, incompleted_list = lists.partition { |list| list_complete?(list) }

    # incompleted_list.each { |list| yield list, lists.index(list)}
    # completed_list.each { |list| yield list, lists.index(list)}
    #why am I passing an explicit block to each of these items?
    incompleted_list.each(&block)
    completed_list.each(&block)
  end

  #divides the todo items within a list into completed items and incompleted items
  def sort_todos(todos, &block)
    completed_todos, incompleted_todos = todos.partition { |todo| todo[:completed] }

    incompleted_todos.each(&block)
    completed_todos.each(&block)
  end
end

HOMEPAGE = "/lists"



def load_list(id)
  list = @storage.find_list(id)
  return list if list
  session[:error] = "The specified list was not found"
  redirect "/lists"
end

#create some validation for an input for a list name. Can't be the same or empty
def error_for_list_name(name)
  if !name.size.between?(1,100)
    "The list name must be between 1 and 100 characaters"
  elsif @storage.all_list(name)
    "list name must be unique"
  end
end

#create a validation for todo items
def error_for_todo(name)
  if !name.size.between?(1,100)
    "The list name must be between 1 and 100 characaters"
  end
end

get "/" do
  redirect HOMEPAGE
end

#View list of lists
get "/lists" do
  @lists = @storage.list
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do 
  erb :new_list, layout: :layout
end

get "/lists/:id" do
  id = params[:id].to_i
  @list = load_list(id)
  @list_id = @list[:id]
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
    @storage.create_new_list(list_name)
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
    erb :edit, layout: :layout
  else
    @storage.update_list(list_name, id)
    session[:success] = "The list has been updated"
    redirect "/lists/#{id}"
  end
end

#Delete a todo list
post "/lists/:id/delete" do 
  id = params[:id].to_i
  @storage.delete_list(id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" #Rack prepends the header with HTTP
    "/lists"
  else
    session[:success] = "The list had been deleted."
    redirect HOMEPAGE
  end
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.create_new_todo(@list_id, text)
    session[:success] = "The item has been added."
    redirect "/lists/#{@list_id}"
  end
end

#Delete a todo from a list
post "/lists/:list_id/todos/:id/destroy" do 
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  @storage.delete_todo_from_list(todo_id, @list_id)

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
  @storage.update_todo_status(@list_id, todo_id, is_completed)
  session[:success] = "The todo has been updated"
  redirect "/lists/#{@list_id}"
end

# Mark all todos as complete for a list
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  @storage.mark_all_todos_as_completed(@list_id)

  session[:success] = "The todos have all been completed!!!"
  redirect "/lists/#{@list_id}"
end
