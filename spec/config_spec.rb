require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

describe Jasmine::Config do
  before(:each) do
    @template_dir = File.expand_path(File.join(File.dirname(__FILE__), "../templates"))
    @config = Jasmine::Config.new
    @config.stub!(:src_dir).and_return(File.join(@template_dir, "public"))
    @config.stub!(:spec_dir).and_return(File.join(@template_dir, "spec"))
  end

  it "should provide a list of all src and spec files" do
    @config.src_files.should == ['javascripts/Example.js']
    @config.spec_files.should == ['javascripts/ExampleSpec.js', 'javascripts/SpecHelper.js']
  end

  it "should provide a list of all spec files with full paths" do
    @config.spec_files_full_paths.should == [
        File.join(@template_dir, 'spec/javascripts/ExampleSpec.js'),
        File.join(@template_dir, 'spec/javascripts/SpecHelper.js')
    ]
  end

  it "should provide a list of all js files" do
    @config.js_files.should == [
        '/javascripts/Example.js',
        '/__spec__/javascripts/ExampleSpec.js',
        '/__spec__/javascripts/SpecHelper.js',
    ]
  end

  it "should provide dir mappings" do
    @config.mappings.should == {
        '/__root__' => @config.project_root,
        '/__spec__' => @config.spec_dir
    }
  end

end