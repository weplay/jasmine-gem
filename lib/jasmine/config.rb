module Jasmine
  class Config
    require 'yaml'
    require 'erb'
    
    attr_reader :jasmine_server_port

    def initialize(options = {})
      require 'selenium_rc'
      @selenium_jar_path = SeleniumRC::Server.allocate.jar_path

      @browser = ENV["JASMINE_BROWSER"] || 'firefox'
      @selenium_pid = nil
      @jasmine_server_pid = nil
    end

    def start_server(port = 8888)
      handler = Rack::Handler.default
      handler.run Jasmine.app(self), :Port => port, :AccessLog => []
    end

    def start
      start_servers
      @client = Jasmine::SeleniumDriver.new("localhost", @selenium_server_port, "*#{@browser}", "#{jasmine_host}:#{@jasmine_server_port}/")
      @client.connect
    end

    def stop
      @client.disconnect
      stop_servers
    end

    def jasmine_host
      ENV["JASMINE_HOST"] || 'http://localhost'
    end

    def start_jasmine_server
      @jasmine_server_port = Jasmine::find_unused_port
      @jasmine_server_pid = fork do
        Process.setpgrp
        start_server(@jasmine_server_port)
        exit! 0
      end
      puts "jasmine server started.  pid is #{@jasmine_server_pid}"
      Jasmine::wait_for_listener(@jasmine_server_port, "jasmine server")
    end

    def external_selenium_server_port
      ENV['SELENIUM_SERVER_PORT'] && ENV['SELENIUM_SERVER_PORT'].to_i > 0 ? ENV['SELENIUM_SERVER_PORT'].to_i : nil
    end

    def start_selenium_server
      @selenium_server_port = external_selenium_server_port
      if @selenium_server_port.nil?
        @selenium_server_port = Jasmine::find_unused_port
        @selenium_pid = fork do
          Process.setpgrp
          exec "java -jar #{@selenium_jar_path} -port #{@selenium_server_port} > /dev/null 2>&1"
        end
        puts "selenium started.  pid is #{@selenium_pid}"
      end
      Jasmine::wait_for_listener(@selenium_server_port, "selenium server")
    end

    def start_servers
      start_jasmine_server
      start_selenium_server
    end

    def stop_servers
      puts "shutting down the servers..."
      stop_selenium_server
      stop_jasmine_server
    end

    def stop_jasmine_server
      if @jasmine_server_pid
        if Rack::Handler.default == Rack::Handler::WEBrick
          Jasmine::kill_process_group(@jasmine_server_pid, "INT")
        else
          Jasmine::kill_process_group(@jasmine_server_pid)
        end
      end
    end

    def stop_selenium_server
      Jasmine::kill_process_group(@selenium_pid) if @selenium_pid
    end

    def run
      begin
        start
        puts "servers are listening on their ports -- running the test script..."
        tests_passed = @client.run
      ensure
        stop
      end
      return tests_passed
    end

    def eval_js(script)
      @client.eval_js(script)
    end

    def match_files(dir, patterns)
      dir = File.expand_path(dir)
      patterns.collect do |pattern|
        Dir.glob(File.join(dir, pattern)).collect {|f| f.sub("#{dir}/", "")}.sort
      end.flatten.uniq
    end

    def simple_config
      config = File.exist?(simple_config_file) ? YAML::load(ERB.new(File.read(simple_config_file)).result(binding)) : false
      config || {}
    end


    def spec_path
      "/__spec__"
    end

    def root_path
      "/__root__"
    end

    def js_files(spec_filter = nil)
      if spec_filter.nil?
        spec_files_to_include = spec_files
        src_files_to_include  = src_files
      else
        spec_files_to_include = match_files(spec_dir, spec_filter)
        src_files_to_include  = src_files + src_files_by_require_line(spec_files_to_include)
      end
      src_files_to_include.collect {|f| "/" + f } + [helpers, spec_files_to_include].map { |files| files.collect {|f| File.join(spec_path, f) } }.flatten
    end

    def css_files
      stylesheets.collect {|f| "/" + f }
    end

    def spec_files_full_paths
      spec_files.collect {|spec_file| File.join(spec_dir, spec_file) }
    end

    def project_root
      Dir.pwd
    end

    def simple_config_file
      File.join(project_root, 'spec/javascripts/support/jasmine.yml')
    end

    def src_dir
      if simple_config['src_dir']
        File.join(project_root, simple_config['src_dir'])
      else
        project_root
      end
    end

    def spec_dir
      if simple_config['spec_dir']
        File.join(project_root, simple_config['spec_dir'])
      else
        File.join(project_root, 'spec/javascripts')
      end
    end

    def helpers
      files = match_files(spec_dir, "helpers/**/*.js")
      if simple_config['helpers']
        files = match_files(spec_dir, simple_config['helpers'])
      end
      files
    end

    def src_files
      files = []
      if simple_config['src_files']
        files = match_files(src_dir, simple_config['src_files'])
      end
      files
    end
    
    def src_files_by_require_line(spec_files)
      files = []
      spec_files.collect {|spec_file| File.join(spec_dir, spec_file) }.each do |file|
        next unless File.exists?(file)
        File.open(file) do |file|
          file.each do |line|
            src_match = line.match(/^\s*\/\/(?:.*)=\s+require\s+\"(.*?)\"\s*$/)
            files << src_match[1] unless src_match.nil?
          end
        end
      end
      files.uniq
    end

    def spec_files
      files = match_files(spec_dir, "**/*[sS]pec.js")
      if simple_config['spec_files']
        files = match_files(spec_dir, simple_config['spec_files'])
      end
      files
    end

    def stylesheets
      files = []
      if simple_config['stylesheets']
        files = match_files(src_dir, simple_config['stylesheets'])
      end
      files
    end

  end
end
