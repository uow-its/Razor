# Our puppet plugin which contains the agent & device proxy classes used for hand off

# TODO - Make broker properties open rather than rigid
require "erb"
require "net/ssh"
require 'uri'

# Root namespace for ProjectRazor
module ProjectRazor::BrokerPlugin

  # Root namespace for Puppet Broker plugin defined in ProjectRazor for node handoff
  class PuppetEnterprise < ProjectRazor::BrokerPlugin::Base
    include(ProjectRazor::Logging)

    def initialize(hash)
      super(hash)

      @plugin = :puppetenterprise
      @description = "PuppetLabs Puppet Enterprise"
      @hidden = false
      from_hash(hash) if hash
      @req_metadata_hash = {
        "@server" => {
          :default      => "",
          :example      => "puppet.example.com",
          :validation   => '(^$|^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$)',
          :required     => false,
          :description  => "Hostname of Puppet Master; optional"
        },
        "@package_url" => {
          :default      => "",
          :example      => "http://example.com/puppet-enterprise.tar.gz",
          :validation   => URI::DEFAULT_PARSER.regexp[:ABS_URI].to_s,
          :required     => true,
          :description  => "the URL where the Puppet Enterprise package can be downloaded from."
        }
      }

    end


    def print_item_header
      if @is_template
        return "Plugin", "Description"
      else
        return "Name", "Description", "Plugin", "UUID", "Server", "Package URL"
      end
    end

    def print_item
      if @is_template
        return @plugin.to_s, @description.to_s
      else
        return @name, @user_description, @plugin.to_s, @uuid, @server, @package_url
      end
    end

    def agent_hand_off(options = {})
      @options = options
      @options[:server] = @server
      @options[:package_url] = @package_url
      return false unless validate_options(@options, [:username, :password, :server, :package_url])
      @puppet_script = compile_template
      init_agent(options)
    end

    def proxy_hand_off(options = {})
      res = "
      @@vc_host { '#{options[:ipaddress]}':
        ensure   => 'present',
        username => '#{options[:username]}',
        password => '#{options[:password]}',
        tag      => '#{options[:vcenter_name]}',
      }
      "
      system("puppet apply --certname=#{options[:hostname]} --report -e \"#{res}\"")
      :broker_success
    end

    # Method call for validating that a Broker instance successfully received the node
    def validate_hand_off(options = {})
      # Return true until we add validation
      true
    end

    def init_agent(options={})
      @run_script_str = ""
      begin
        Net::SSH.start(options[:ipaddress], options[:username], { :password => options[:password], :user_known_hosts_file => '/dev/null'} ) do |session|
          logger.debug "Copy: #{session.exec! "echo \"#{@puppet_script}\" > /tmp/puppet_init.sh" }"
          logger.debug "Chmod: #{session.exec! "chmod +x /tmp/puppet_init.sh"}"
          @run_script_str << session.exec!("bash /tmp/puppet_init.sh |& tee /tmp/puppet_init.out")
          @run_script_str.split("\n").each do |line|
            logger.debug "puppet script: #{line}"
          end
        end
      rescue => e
        logger.error "puppet agent error: #{e}"
        return :broker_fail
      end
      # set return to fail by default
      ret = :broker_fail
      # set to wait
      ret = :broker_wait if @run_script_str.include?("Exiting; no certificate found and waitforcert is disabled")
      # set to success (this meant autosign was likely on)
      ret = :broker_success if @run_script_str.include?("Finished catalog run")
      ret
    end

    def compile_template
      logger.debug "Compiling template"
      install_script = File.join(File.dirname(__FILE__), "puppetenterprise/agent_install.erb")
      contents = ERB.new(File.read(install_script)).result(binding)
      logger.debug("Compiled installation script:")
      logger.error install_script
      #contents.split("\n").each {|x| logger.error x}
      contents
    end

    def validate_options(options, req_list)
      missing_opts = req_list.select do |opt|
        options[opt] == nil
      end
      unless missing_opts.empty?
        false
      end
      true
    end

  end
end
