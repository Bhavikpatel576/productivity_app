class SessionPersistance
    attr_reader :session

    def initialize(session)
      @session = session
      @session[:lists] ||= []
    end

    def list
      @session[:lists]
    end

    def find_list(id)
      @session[:lists].find { |list| list[:id] == id }
    end

    def all_list(name)
      @session[:lists].any? { |list| list[:name] == name }
    end

    def next_todo_id(todos)
      max = todos.map { |todo| todo[:id] }.max || 0
      max + 1
    end

    def next_list_id(list)
      max = list.map {|item| item[:id] }.max || 0
      max + 1
    end

    def create_new_list(list_name)
      id = next_list_id(@session[:lists])
      @session[:lists] << { id: id, name: list_name, todos: []}
    end

    def update_list(list_name, id)
      list = find_list(id)
      list[:name] = list_name
    end

    def delete_list(id)
      session[:lists].reject! { |list| list[:id] == id }
    end

    def create_new_todo(id, text)
      list = find_list(id)
      id = next_todo_id(list[:todos])
      list[:todos] << { id: id, name: text, complete:false}
    end

    def delete_todo_from_list(todo_id, list_id)
        list = find_list(list_id)
        list[:todos].reject! { |todo| todo[:id] == todo_id }
    end

    def update_todo_status(list_id, todo_id, new_status)
      list = find_list(list_id)
      todo = list[:todos].find { |t| t[:id] == todo_id }
      todo[:completed] = new_status
    end

    def mark_all_todos_as_completed(list_id)
      list = find_list(list_id)
      list[:todos].each do |todo|
        todo[:completed] = true
      end
    end
end