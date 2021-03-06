require 'rake'

module RakeGcc
  include Rake::DSL
  
  @targets = {}
  
  class << self
    attr_accessor :targets
  end
  
  def build_target(name, parent_target_name = nil, &block)
    target = BuildTarget.new name
    
    if parent_target_name
      parent_target = RakeGcc.targets[parent_target_name.to_sym]
      raise "No build target named #{parent_target_name} yet defined" unless parent_target
      target.parent = parent_target
    end
    
    RakeGcc.targets[name.to_sym] = target
    target.defining_block = block
    target_dsl_context = BuildTargetDslContext.new(target)
    
    blocks = []
    blocks.unshift block
    
    current_target = target
    while current_target.parent
      blocks.unshift(current_target.parent.defining_block)
      current_target = current_target.parent
    end
    
    blocks.each do |b|
      target_dsl_context.instance_eval &b
    end
    
    # All tasks defined for a build target are namespaced under the target name
    namespace name do
      target.define_tasks
    end
  end

  class BuildTarget
    attr_accessor :name,
      :compiler,
      :directories,
      :compile_options,
      :link_options,
      :before_block,
      :after_block,
      :file_copy_lists,
      :defining_block,
      :parent
      
    def initialize(name)
      @name = name
      @compiler = "gcc"
      @directories = ["#{name}/obj"]
      @compile_options = CompileOptions.new
      @link_options = LinkOptions.new
      @file_copy_lists = {}
    end
    
    def define_tasks
      define_obj_tasks(obj_files)
      
      all_directories.each do |dir|
        directory dir
      end
      
      task :before do
        self.before_block.call() if self.before_block
      end
      
      task :compile => obj_files
      
      define_link_artifact_task(obj_files)
      
      define_file_copy_tasks
      
      task :after do
        self.after_block.call() if self.after_block
      end
      
      task :build => [all_directories, :before, :compile, "#{name}/#{@link_options.artifact}", copied_files, :after].flatten do
        puts "Build Complete"
      end
      
      task :clean do
        rm_rf name.to_s
      end
    end
    
    def define_obj_tasks(obj_files)
      @compile_options.sources.zip(obj_files).each do |source, obj|
        file obj => source do
          # TODO: allow specification of compiler command (gcc/g++)
          flags = @compile_options.flags.join(' ')
          defines = @compile_options.defines.map { |d| "-D#{d}" }.join(' ')
          includes = @compile_options.include_dirs.map { |dir| "-I#{dir}" }.join(' ')
          sh "#{@compiler} #{flags} #{defines} #{includes} -c #{source} -o #{obj}"
        end
      end
    end
    
    def define_link_artifact_task(obj_files)
      file "#{name}/#{@link_options.artifact}" => obj_files do
        flags = @link_options.flags.join(' ')
        link_libraries = @link_options.libs.map { |lib| "-l#{lib}" }.join(' ')
        search_path = @link_options.dirs.map { |dir| "-L#{dir}" }.join(' ')
        sh "#{@compiler} #{flags} #{search_path} #{obj_files.join(' ')} #{link_libraries} -o #{name}/#{@link_options.artifact}"
      end
    end
    
    def define_file_copy_tasks
      @file_copy_lists.each do |from_list, to_list|
        from_list.zip(to_list).each do |from, to|
          file to => from do
            cp from, to
          end
        end
      end
    end
    
    def copied_files
      @file_copy_lists.values.flat_map { |l| l.to_a }
    end
    
    def obj_files
      if defined? @obj_files
        @obj_files
      else
        @obj_files = @compile_options.sources.pathmap("#{name}/obj/%X.o")
        @obj_files += @link_options.object_files
        @obj_files
      end
    end
    
    def all_files
      if defined? @all_files
        @all_files
      else
        @all_files = obj_files
        @all_files += @file_copy_lists.values.flatten
        @all_files
      end
    end
    
    def all_directories
      if defined? @all_directories
        @all_directories
      else
        @all_directories = all_files.map { |obj| File.dirname obj }
        @all_directories += @directories
        @all_directories
      end
    end
    
  end
  
  class BuildTargetDslContext
    def initialize(build_target)
      @build_target = build_target
    end
    
    def compiler(command)
      @build_target.compiler = command
    end
    
    def directories(*args)
      args = args.flatten
      @build_target.directories += args.map { |arg| "#{@build_target.name}/#{arg}" }
    end
    alias directory directories
    
    def before(&block)
      @build_target.before_block = block
    end
    
    def after(&block)
      @build_target.after_block = block
    end
    
    def copy(*args)
      args = args.flatten
      @build_target.file_copy_lists
      args.each do |arg|
        if arg.kind_of? Hash
          from_list = Rake::FileList.new(arg.keys[0])
          to_list = Rake::FileList.new(arg.values[0]).pathmap "#{@build_target.name}/%p"
        else
          from_list = Rake::FileList.new(arg).select { |f| File.file? f }
          to_list = from_list.pathmap "#{@build_target.name}/%p"
        end
        @build_target.file_copy_lists[from_list] = to_list
      end
    end
    
    def compile(&block)
      compile_context = CompileDslContext.new(@build_target)
      compile_context.instance_eval &block
    end
    
    def link(&block)
      link_context = LinkDslContext.new(@build_target)
      link_context.instance_eval &block
    end
  end
  
  class CompileOptions
    attr_accessor :flags,
      :defines,
      :include_dirs,
      :sources
      
    def initialize
      @flags = []
      @defines = []
      @include_dirs = Rake::FileList.new
      @sources = Rake::FileList.new
    end
  end
  
  class CompileDslContext
    def initialize(build_target)
      @build_target = build_target
      @compile_options = build_target.compile_options
    end
    
    def flags(*args)
      args = args.flatten
      @compile_options.flags += args
    end
    alias flag flags
    
    def dont_flag(*args)
      args = args.flatten
      @compile_options.flags = @compile_options.flags.reject do |old_flag|
        args.any? { |arg| arg == old_flag }
      end
    end
    
    def define(*args)
      args = args.flatten
      @compile_options.defines += args
    end
    
    def dont_define(*args)
      args = args.flatten
      @compile_options.defines = @compile_options.defines.reject do |old_define|
        args.any? { |arg| arg == old_define }
      end
    end
    alias undefine dont_define
    
    def search(*args)
      args = args.flatten
      args.each { |arg| @compile_options.include_dirs.add arg }
    end
    
    def dont_search(*args)
      args = args.flatten
      @compile_options.include_dirs = @compile_options.include_dirs.reject do |old_search|
        args.any? { |arg| arg == old_search }
      end
    end
    
    def sources(*args)
      args = args.flatten
      args.each { |arg| @compile_options.sources.add arg }
    end
    alias source sources
  end
  
  class LinkOptions
    attr_accessor :flags,
      :dirs,
      :libs,
      :object_files,
      :artifact
      
    def initialize
      @flags = []
      @dirs = Rake::FileList.new
      @libs = []
      @object_files = []
    end
  end
  
  class LinkDslContext
    def initialize(build_target)
      @build_target = build_target
      @link_options = build_target.link_options
    end
    
    def flags(*args)
      args = args.flatten
      @link_options.flags += args
    end
    alias flag flags
    
    def search(*args)
      args = args.flatten
      @link_options.dirs.add args
    end
    
    def libs(*args)
      args = args.flatten
      @link_options.libs = args + @link_options.libs
    end
    alias lib libs
    
    def object(*args)
      args = args.flatten
      @link_options.object_files += args
    end
    alias objects object
    alias object_file object
    alias object_files object
    
    def artifact(name)
      @link_options.artifact = name
    end
  end
end