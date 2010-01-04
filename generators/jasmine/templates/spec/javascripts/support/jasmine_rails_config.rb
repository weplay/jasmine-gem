require 'jasmine'

class JasmineRailsConfig < Jasmine::Config

  def project_root
    File.expand_path(File.join(File.dirname(__FILE__), "..", "..", ".."))
  end

# Return an array of files to include before jasmine specs. Override if needed.
#  def src_files
#    match_files(src_dir, "**/*.js")
#  end

  # Path to your JavaScript source files
  def src_dir
    File.join(project_root, "public")
  end

end
