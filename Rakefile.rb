require "./rakelib/rake_gcc"
include RakeGcc

# Settings
# ========

$CPP = ENV['CPP'] || "g++"
$CC = ENV['CC'] || "gcc"
$RUBY = ENV['RUBY'] || "ruby20_mingw"
$RUBYDLL = ENV['RUBYDLL'] || "x64-msvcrt-ruby200.dll"
$RUBYDO = ENV['RUBYDO'] || "C:/projects/rubydo"
$WXWIDGETS = ENV['WXWIDGETS'] || "C:/projects/lib/wxWidgets-3.0.1"

# debug target
# ============

build_target :debug do
  compiler $CPP
  
  before do
    sh "windres \"-I#{$WXWIDGETS}/include\" resources.rc #{@build_target.name}/obj/resources.o"
  end
  
  compile do
    define :DEBUG
    
    flag "-std=c++11"
    
    search [
      "include",
      "#{$WXWIDGETS}/include",
      "#{$WXWIDGETS}/lib/gcc_lib/mswu",
      "#{$RUBY}/include/ruby-2.0.0",
      "#{$RUBY}/include/ruby-2.0.0/x64-mingw32",
      "#{$RUBYDO}/include"
    ]
    
    sources "src/**/*.{c,cpp}"
  end
  
  link do
    search [
      "#{$WXWIDGETS}/lib/gcc_lib",
      "#{$RUBY}/lib",
      "#{$RUBYDO}/Release"
    ]
    
    object "#{@build_target.name}/obj/resources.o"
    
    libs [
      "wxmsw30u",
      "wxscintilla",
      "wxexpat",
      "wxjpeg",
      "wxpng",
      "wxregexu",
      "wxtiff",
      "wxzlib",
      "rubydo",
      $RUBYDLL,
      "Comctl32",
      "Ole32",
      "Gdi32",
      "Shell32",
      "uuid",
      "OleAut32",
      "Comdlg32",
      "Winspool"
    ]
    
    artifact "app.exe"
  end
  
  copy "app.xrc"
end

# release target
# ==============

# release simply inherits from debug, redefining settings as needed
build_target :release, :debug do
  compile do
    undefine :DEBUG
    define :RELEASE
  end
end

# dist target
# ===========

# The dist target builds the release target, copies it into the dist
# folder (ignoring object files) and runs strip to reduce the exe size
namespace :dist do
  directory "dist"
  task :build => ["release:build", "dist"] do
    Dir["Release/*"].each do |file|
      next if File.basename(file) == "obj"
      if File.directory?(file)
        cp_r file, "Dist/#{File.basename file}"
      elsif File.file?(file)
        cp file, "Dist/#{File.basename file}"
      end
    end
    
    Dir["Dist/**/*.{o,exe,dll,so}"].each do |binary|
      sh "strip --strip-unneeded #{binary}"
    end
  end
end

# Clean task
# ==========

task :clean do
  rm_rf "debug" if File.exists? "debug"
  rm_rf "release" if File.exists? "release"
  rm_rf "dist" if File.exists? "dist"
end

