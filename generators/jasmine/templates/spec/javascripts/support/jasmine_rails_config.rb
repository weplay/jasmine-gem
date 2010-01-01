require 'jasmine'

class JasmineRailsConfig < Jasmine::Config
  def proj_root
    File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
  end

  def src_files
    match_files(src_dir, "**/*.js")
  end

  def src_dir
    File.join(proj_root, "public")
  end

  def spec_dir
    File.join(proj_root, 'spec/javascripts')
  end
end
