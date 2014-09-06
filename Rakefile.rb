# Global Build tool configuration
# ===============================

$CPP = ENV['CPP'] || "g++"
$CC = ENV['CC'] || "gcc"

# Global Compilation Options
# ==========================

$COMPILE_FLAGS = %w[
-std=c++11
]

$INCLUDE_PATHS = %w[
include
C:/projects/lib/wxWidgets-3.0.1/include
C:/projects/lib/wxWidgets-3.0.1/lib/gcc_lib/mswu
C:/Ruby-2.1.2-custom/include/ruby-2.1.0
C:/Ruby-2.1.2-custom/include/ruby-2.1.0/i386-mingw32
C:/projects/rubydo/include
]

def compile_options
  flags = $COMPILE_FLAGS.join(" ")
  search_paths = $INCLUDE_PATHS.map { |path| "-I#{path}" }.join(" ")
  "#{flags} #{search_paths}"
end

# Global Linking Options
# ======================

$ARTIFACT = "app.exe"

$LINK_FLAGS = []

$LIBRARY_PATHS = %w[
C:/projects/lib/wxWidgets-3.0.1/lib/gcc_lib
C:/Ruby-2.1.2-custom/lib
C:/projects/rubydo/Debug
]

$LIBRARIES = %w[
wxmsw30u
wxscintilla
wxexpat
wxjpeg
wxpng
wxregexu
wxtiff
wxzlib
rubydo
msvcrt-ruby210.dll
Comctl32
Ole32
Gdi32
Shell32
uuid
OleAut32
Comdlg32
Winspool
]

def link_options
  flags = $LINK_FLAGS.join(" ")
  search_paths = $LIBRARY_PATHS.map { |path| "-L#{path}" }.join(" ")
  "#{flags} #{search_paths}"
end

def link_libraries
  $LIBRARIES.map { |lib| "-l#{lib}" }.join(" ")
end

# Global File Lists
# =================
  
$SOURCE_FILES = FileList["src/**/*.{c,cpp}"]

# Debug Configuration Tasks
# =========================

namespace :debug do
  # Customize compile options for this configuration
  task :compile_options do
    $COMPILE_FLAGS += %w[-DDEBUG]
    $INCLUDE_PATHS += []
  end
  
  # Customize link options for this configuration
  task :link_options do
    $LINK_FLAGS += []
    $LIBRARY_PATHS += []
    $LIBRARIES += []
  end
  
  # Derive the object files & output directories from the source files
  obj_files = $SOURCE_FILES.pathmap("Debug/obj/%X.o")
  output_directories = obj_files.map { |obj| File.dirname obj }
    
  # Make a directory task for each output folder
  output_directories.each { |dir| directory dir }
  
  # Make a file task for each object file
  $SOURCE_FILES.zip(obj_files).each do |source, obj|
    file obj => source do
      sh "#{$CPP} #{compile_options} -c #{source} -o #{obj}"
    end
  end
  
  # Copy over misc files/folders
  file "Debug/app.xrc" => "app.xrc" do
    cp "app.xrc", "Debug/app.xrc"
  end
  
  file "Debug/msvcrt-ruby210.dll" => "C:/Ruby-2.1.2-custom/lib/msvcrt-ruby210.dll" do
    cp "C:/Ruby-2.1.2-custom/lib/msvcrt-ruby210.dll", "Debug/msvcrt-ruby210.dll"
  end
  
  directory "Debug/lib/ruby" do
    mkdir_p "Debug/lib"
    cp_r "C:/Ruby-2.1.2-custom/lib/ruby", "Debug/lib"
  end
  
  desc "Compile all sources"
  task :compile => ([:compile_options] + output_directories + obj_files)
  
  desc "Link the Debug artifact"
  task :link => %w[link_options compile] do
    sh "#{$CPP} #{link_options} #{obj_files.join(' ')} #{link_libraries} -o Debug/#{$ARTIFACT}"
  end
  
  desc "Build the Debug configuration"
  task :build => ["compile", "link", "Debug/app.xrc", "Debug/msvcrt-ruby210.dll", "Debug/lib/ruby"]
end

# Release Configuration Tasks
# ===========================

namespace :release do
  # Customize compile options for this configuration
  task :compile_options do
    $COMPILE_FLAGS += %w[-DRELEASE]
    $INCLUDE_PATHS += []
  end
  
  # Customize link options for this configuration
  task :link_options do
    $LINK_FLAGS += %w[-mwindows]
    $LIBRARY_PATHS += []
    $LIBRARIES += []
  end
  
  # Derive the object files & output directories from the source files
  obj_files = $SOURCE_FILES.pathmap("Release/obj/%X.o")
  output_directories = obj_files.map { |obj| File.dirname obj }
    
  # Make a directory task for each output folder
  output_directories.each { |dir| directory dir }
  
  # Make a file task for each object file
  $SOURCE_FILES.zip(obj_files).each do |source, obj|
    file obj => source do
      sh "#{$CPP} #{compile_options} -c #{source} -o #{obj}"
    end
  end
  
  # Copy over misc files/folders
  file "Release/app.xrc" => "app.xrc" do
    cp "app.xrc", "Release/app.xrc"
  end
  
  file "Release/msvcrt-ruby210.dll" => "C:/Ruby-2.1.2-custom/lib/msvcrt-ruby210.dll" do
    cp "C:/Ruby-2.1.2-custom/lib/msvcrt-ruby210.dll", "Release/msvcrt-ruby210.dll"
  end
  
  directory "Release/lib/ruby" do
    mkdir_p "Release/lib"
    cp_r "C:/Ruby-2.1.2-custom/lib/ruby", "Release/lib"
  end
  
  desc "Compile all sources"
  task :compile => ([:compile_options] + output_directories + obj_files)
  
  desc "Link the Release artifact"
  task :link => %w[link_options compile] do
    sh "#{$CPP} #{link_options} #{obj_files.join(' ')} #{link_libraries} -o Release/#{$ARTIFACT}"
  end
  
  desc "Strip all unneeded binary symbols"
  task :strip do
    Dir["Release/**/*.{o,exe,dll,so}"].each do |binary|
      sh "strip --strip-unneeded #{binary}"
    end
  end
  
  desc "Build the Release configuration"
  task :build => ["compile", "link", "Release/app.xrc", "Release/msvcrt-ruby210.dll", "Release/lib/ruby", "strip"]
end
