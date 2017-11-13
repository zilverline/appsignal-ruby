module Appsignal
  # System environment detection module.
  #
  # Provides useful methods to find out more about the host system.
  #
  # @api private
  module System
    MUSL_TARGET = "linux-musl".freeze
    GEM_EXT_PATH = File.expand_path("../../../ext", __FILE__).freeze

    def self.heroku?
      ENV.key? "DYNO".freeze
    end

    # Returns the platform for which the agent was installed.
    #
    # This value is saved when the gem is installed in `ext/extconf.rb`.
    # We use this value to build the diagnose report with the installed
    # platform, rather than the detected platform in {.agent_platform} during
    # the diagnose run.
    #
    # @api private
    # @return [String]
    def self.installed_agent_platform
      platform_file = File.join(GEM_EXT_PATH, "appsignal.platform")
      return unless File.exist?(platform_file)
      File.read(platform_file)
    end

    # Detect agent and extension platform build
    #
    # Used by `ext/extconf.rb` to select which build it should download and
    # install.
    #
    # Use `export APPSIGNAL_BUILD_FOR_MUSL=1` if the detection doesn't work
    # and to force selection of the musl build.
    #
    # @api private
    # @return [String]
    def self.agent_platform
      return MUSL_TARGET if ENV["APPSIGNAL_BUILD_FOR_MUSL"]

      local_os = Gem::Platform.local.os
      if local_os =~ /linux/
        ldd_output = ldd_version_output
        return MUSL_TARGET if ldd_output.include? "musl"
        ldd_version = ldd_output.match(/\d+\.\d+/)
        if ldd_version && versionify(ldd_version[0]) < versionify("2.15")
          return MUSL_TARGET
        end
      end

      local_os
    end

    # @api private
    def self.versionify(version)
      Gem::Version.new(version)
    end

    # @api private
    def self.ldd_version_output
      `ldd --version 2>&1`
    end
  end
end
