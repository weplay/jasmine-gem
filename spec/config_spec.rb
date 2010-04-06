require File.expand_path(File.join(File.dirname(__FILE__), "spec_helper"))

describe Jasmine::Config do

  describe "configuration" do

    before(:each) do
      @template_dir = File.expand_path(File.join(File.dirname(__FILE__), "../generators/jasmine/templates"))
      @config = Jasmine::Config.new
    end

    describe "defaults" do

      it "src_dir uses root when src dir is blank" do
        @config.stub!(:project_root).and_return('some_project_root')
        @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
        YAML.stub!(:load).and_return({'src_dir' => nil})
        @config.src_dir.should == 'some_project_root'
      end

      it "should use correct default yaml config" do
        @config.stub!(:project_root).and_return('some_project_root')
        @config.simple_config_file.should == (File.join('some_project_root', 'spec/javascripts/support/jasmine.yml'))
      end


      it "should provide dir mappings" do
        @config.mappings.should == {
          '/__root__' => @config.project_root,
          '/__spec__' => @config.spec_dir
        }
      end
    end


    describe "simple_config" do
      before(:each) do
        @config.stub!(:src_dir).and_return(File.join(@template_dir))
        @config.stub!(:spec_dir).and_return(File.join(@template_dir, "spec/javascripts"))
      end

      shared_examples_for "simple_config defaults" do
        it "should return the correct files and mappings" do
          @config.src_files.should == []
          @config.environment_files.should == []
          @config.stylesheets.should == []
          @config.spec_files.should == ['ExampleSpec.js']
          @config.helpers.should == ['helpers/SpecHelper.js']
          @config.js_files.should == [
            '/__spec__/helpers/SpecHelper.js',
            '/__spec__/ExampleSpec.js',
          ]
          @config.js_files("ExampleSpec.js").should ==
            ['/__spec__/helpers/SpecHelper.js',
             '/__spec__/ExampleSpec.js']
          @config.mappings.should == {
            '/__root__' => @config.project_root,
            '/__spec__' => @config.spec_dir
          }
          @config.spec_files_full_paths.should == [
            File.join(@template_dir, 'spec/javascripts/ExampleSpec.js'),
          ]
        end
      end


      describe "if sources.yaml not found" do
        before(:each) do
          File.stub!(:exist?).and_return(false)
        end
        it_should_behave_like "simple_config defaults"
      end

      describe "if jasmine.yml is empty" do
        before(:each) do
          @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
          YAML.stub!(:load).and_return(false)
        end
        it_should_behave_like "simple_config defaults"

      end

      describe "using default jasmine.yml" do
        before(:each) do
          @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
        end
        it_should_behave_like "simple_config defaults"

      end


      it "simple_config stylesheets" do
        @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
        YAML.stub!(:load).and_return({'stylesheets' => ['foo.css', 'bar.css']})
        Dir.stub!(:glob).and_return do |glob_string|
          glob_string
        end
        @config.stylesheets.should == ['foo.css', 'bar.css']
      end

      it "simple_config environments" do
        @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
        YAML.stub!(:load).and_return({'helpers' => [], 'spec_files' => [], 'environment_files' => ['enviroment.js', 'before.js']})
        Dir.stub!(:glob).and_return do |glob_string|
          glob_string
        end
        @config.js_files.should == ['/__spec__/enviroment.js', '/__spec__/before.js']
      end

      it "using rails jasmine.yml" do

        original_glob = Dir.method(:glob)
        Dir.stub!(:glob).and_return do |glob_string|
          if glob_string =~ /public/
            glob_string
          else
            original_glob.call(glob_string)
          end
        end
        @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine-rails.yml'))
        @config.spec_files.should == ['ExampleSpec.js']
        @config.helpers.should == ['helpers/SpecHelper.js']
        @config.src_files.should == ['public/javascripts/prototype.js',
                                     'public/javascripts/effects.js',
                                     'public/javascripts/controls.js',
                                     'public/javascripts/dragdrop.js',
                                     'public/javascripts/application.js']
        @config.js_files.should == [
          '/public/javascripts/prototype.js',
          '/public/javascripts/effects.js',
          '/public/javascripts/controls.js',
          '/public/javascripts/dragdrop.js',
          '/public/javascripts/application.js',
          '/__spec__/helpers/SpecHelper.js',
          '/__spec__/ExampleSpec.js',
        ]
        @config.js_files("ExampleSpec.js").should == [
          '/public/javascripts/prototype.js',
          '/public/javascripts/effects.js',
          '/public/javascripts/controls.js',
          '/public/javascripts/dragdrop.js',
          '/public/javascripts/application.js',
          '/__spec__/helpers/SpecHelper.js',
          '/__spec__/ExampleSpec.js'
        ]

      end

    end

  end

  describe "browser configuration" do
    it "should use firefox by default" do
      ENV.stub!(:[], "JASMINE_BROWSER").and_return(nil)
      config = Jasmine::Config.new
      config.stub!(:start_servers)
      Jasmine::SeleniumDriver.should_receive(:new).
        with(anything(), anything(), "*firefox", anything()).
        and_return(mock(Jasmine::SeleniumDriver, :connect => true))
      config.start
    end

    it "should use ENV['JASMINE_BROWSER'] if set" do
      ENV.stub!(:[], "JASMINE_BROWSER").and_return("mosaic")
      config = Jasmine::Config.new
      config.stub!(:start_servers)
      Jasmine::SeleniumDriver.should_receive(:new).
        with(anything(), anything(), "*mosaic", anything()).
        and_return(mock(Jasmine::SeleniumDriver, :connect => true))
      config.start
    end
    end

  describe "jasmine host" do
    it "should use http://localhost by default" do
      config = Jasmine::Config.new
      config.instance_variable_set(:@jasmine_server_port, '1234')
      config.stub!(:start_servers)

      Jasmine::SeleniumDriver.should_receive(:new).
        with(anything(), anything(), anything(), "http://localhost:1234/").
        and_return(mock(Jasmine::SeleniumDriver, :connect => true))
      config.start
    end

    it "should use ENV['JASMINE_HOST'] if set" do
      ENV.stub!(:[], "JASMINE_HOST").and_return("http://some_host")
      config = Jasmine::Config.new
      config.instance_variable_set(:@jasmine_server_port, '1234')
      config.stub!(:start_servers)

      Jasmine::SeleniumDriver.should_receive(:new).
        with(anything(), anything(), anything(), "http://some_host:1234/").
        and_return(mock(Jasmine::SeleniumDriver, :connect => true))
      config.start
    end
  end

  describe "#start_selenium_server" do
    it "should use an existing selenium server if SELENIUM_SERVER_PORT is set" do
      config = Jasmine::Config.new
      ENV.stub!(:[], "SELENIUM_SERVER_PORT").and_return(1234)
      Jasmine.should_receive(:wait_for_listener).with(1234, "selenium server")
      config.start_selenium_server
    end
  end


end
