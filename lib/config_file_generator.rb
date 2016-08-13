require 'erb'
require 'fileutils'
require 'ostruct'
require 'yaml'

class ConfigFileGenerator
  include ERB::Util
  attr_accessor :environment, :template, :date

  # Set up our instance variables so that we can pass them to the template.
  def initialize(template_path: 'deployment/templates', vars: File.join(template_path, 'vars.yml'))
    @template_vars = load_vars(vars)
    @templates = find_templates(template_path)
  end

  # Load variables for use within the templates.
  # Accepts either a file path or a Hash.
  def load_vars(vars)
    if File.file?(vars)
      YAML.load(File.read(vars))
    elsif vars.is_a?(Hash)
      vars
    else
      raise "Either a Hash or a file path is required to load template variables from. " + \
            "Instead received: #{vars}"
    end
  end

  # Returns an array of templates.
  # If a directory is passed in, then it returns all files within that directory (recursively).
  # If a file is passed in, then just that file is returned.
  def find_templates(template_path)
    if File.directory?(template_path)
      Dir["#{template_path}/**/*"].select do |file|
        File.file?(file) and ! file.include? 'vars.yml'
      end
    elsif File.file?(template_path)
      [template_path]
    else
      raise "Need a valid Template file path. Instead received: '#{template_path}', " + \
             "which doesn't look to exist."
    end
  end

  def read(file_path)
    File.read(file_path)
  end

  # Get all of the variables used within the template so that we can let the user know which
  # variables they need to be passing in.
  def get_vars_used_in_template(template)
    read(template).scan(/<%= ?([a-z]+[0-9a-z_]*)/i).uniq.flatten
  end

  # Check that the caller passed in one of every variable that is needed by the template. If not, raise.
  def check_required_vars(template, environment)
    template_vars = get_vars_used_in_template(template).sort
    passed_vars = @template_vars[environment].keys.sort.map {|x| x.to_s}
    difference = template_vars - passed_vars
    unless difference.empty?
      raise "\n\nNot all required variables were provided for template '#{template}'.\n" + \
            "Missing variables: #{difference}\n" + \
            "The variables provided were: #{passed_vars}\n\n"
    end
  end

  # ERB passes variables to the template from a Binding, an object that provides access to the instance
  #   methods and variables that are owned by another object.
  # If you do not specify a Binding, the result() method only passes the Binding to the template for
  #   the top-level object. To pass the template your class's binding (probably what you want), you
  #   must pass render() your class's private binding() instance method (which Ruby provides) as done here.
  def render(template, environment)
    vars = OpenStruct.new(@template_vars[environment]).instance_eval { binding }
    ERB.new(read(template)).result(vars)
  end

  # Parse the templates given to the class.
  # If an output directory is given to this function, write out the parsed templates to files within that
  #    directory with the same name, without the ".erb"
  #    Directory structure is also preserved.
  # If an output directory isn't given, just print out the parsed templates to stdout.
  #   Basically, this allows for a "dry run" which is useful for testing that your templates are looking solid.
  def generate(environment, output_directory: File.join('deployment', environment), dry_run: false)

    if dry_run
      puts "Running generate() in dry_run. Printing parsed templates to stdout instead of to a file:"
      for template in @templates
        # Fail early if the template uses variables that weren't passed in.
        check_required_vars(template, environment)
        puts "\n~~~~~~~~~~ #{template} ~~~~~~~~~~\n\n"
        puts render(template, environment)
      end
    else
      for template in @templates
        # Fail early if the template uses variables that weren't passed in.
        check_required_vars(template, environment)
        begin
          file_name = File.join(output_directory, File.basename(template, '.erb'))
          File.open(file_name, 'w+') do |f|
            f.write(render(template, environment))
          end
        rescue Errno::ENOENT # if directory path doesn't exist, create it
          FileUtils.mkdir_p(File.dirname(file_name))
          retry
        end

      end
    end

  end

  private :check_required_vars, :find_templates, :get_vars_used_in_template, :load_vars, :read, :render
end
