require 'rails/generators/named_base'

module WebAppTheme
  class ThemedGenerator < Rails::Generators::NamedBase
  
    # argument :controller_routing_path
  
    class_option :app_name, :default => 'Web App'
    class_option :type, :default => :crud
    class_option :include_layout
    class_option :will_paginate, :default => false
    class_option :engine, :default => :erb
  
    argument :singular_controller_routing_path, :required => false
  
    argument :columns, :required => false
    argument :model_name, :required => false
    argument :plural_model_name, :required => false
    argument :resource_name, :required => false
    argument :plural_resource_name, :required => false
    
    attr_reader :controller_routing_path, 
                :singular_controller_routing_path,
                :columns,
                :model_name,
                :plural_model_name,
                :resource_name,
                :plural_resource_name,
                :engine
    
    def manifest
      @engine = options[:engine]
      @plural_controller_path  = name
      @model_name       = singular_controller_routing_path
    
      @controller_routing_path          = table_name    
      @singular_controller_routing_path = table_name.singularize    
      base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@plural_controller_path)    
      @model_name = base_name.singularize unless @model_name

      # Post
      @model_name           = @model_name.camelize 
      # Posts
      @plural_model_name    = @model_name.pluralize
      # post 
      @resource_name        = @model_name.underscore 
      # posts
      @plural_resource_name = @resource_name.pluralize                

      manifest_method = "manifest_for_#{options[:type]}"
    
      method(manifest_method).call if respond_to?(manifest_method)
    end
  
    def self.gem_root
      File.expand_path("../../../../../", __FILE__)
    end
  
    def self.source_root
      File.join(gem_root, 'templates', 'themed')
    end
    
    protected
  
    def manifest_for_crud
      @columns = []
      empty_directory(File.join('app/views', @controller_file_path))
      template("view_tables.html.#{@engine}",  File.join("app/views", @controller_file_path, "index.html.#{@engine}"))
      template("view_new.html.#{@engine}",     File.join("app/views", @controller_file_path, "new.html.#{@engine}"))
      template("view_edit.html.#{@engine}",    File.join("app/views", @controller_file_path, "edit.html.#{@engine}"))
      template("view_form.html.#{@engine}",    File.join("app/views", @controller_file_path, "_form.html.#{@engine}"))
      template("view_show.html.#{@engine}",    File.join("app/views", @controller_file_path, "show.html.#{@engine}"))
      template("view_sidebar.html.#{@engine}", File.join("app/views", @controller_file_path, "_sidebar.html.#{@engine}"))
    
      if options[:include_layout]
        gsub_file(File.join("app/views/layouts", "application.html.erb"), /\<div\s+id=\"main-navigation\">.*\<\/ul\>/mi) do |match|
          match.gsub!(/\<\/ul\>/, "")
          %|#{match} <li class="<%= controller.controller_path == '#{@controller_file_path}' ? 'active' : '' %>"><a href="<%= #{@plural_controller_routing_path}_path %>">#{plural_model_name}</a></li></ul>|
        end
      end
    end
  
    def manifest_for_restful_authentication
      signup_controller_path  = @controller_file_path
      signin_controller_path  = @model_name.downcase # just here I use the second argument as a controller path
      @resource_name          = @controller_routing_path.singularize
      m.template("view_signup.html.#{@engine}",  File.join("app/views", signup_controller_path, "new.html.#{@engine}"))
      m.template("view_signin.html.#{@engine}",  File.join("app/views", signin_controller_path, "new.html.#{@engine}"))
    end
  
    def manifest_for_text
      empty_directory(File.join('app/views', @controller_file_path))    
      template("view_text.html.#{@engine}", File.join("app/views", @controller_file_path, "show.html.erb"))
      template("view_sidebar.html.#{@engine}", File.join("app/views", @controller_file_path, "_sidebar.html.erb"))
    end
  
    def get_columns
      excluded_column_names = %w[id created_at updated_at]
      Kernel.const_get(@model_name).columns.reject{|c| excluded_column_names.include?(c.name) }.collect{|c| Rails::Generator::GeneratedAttribute.new(c.name, c.type)}
    end
  
    def banner
      "Usage: #{$0} web_app_theme:themed ControllerPath [ModelName] [options]"
    end
  
    def extract_modules(name)
      modules = name.include?('/') ? name.split('/') : name.split('::')
      name = modules.pop
      path = modules.map { |m| m.underscore }
      file_path = (path + [name.underscore]).join('/')
      nesting = modules.map { |m| m.camelize }.join('::')
      [name, path, file_path, nesting, modules.size]
    end
    
    
  end
end