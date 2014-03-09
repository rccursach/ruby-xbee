#!/usr/bin/env gem build
# -*- encoding: utf-8 -*-

require './lib/version.rb'

Gem::Specification.new do |s|
  s.name = %q{ruby-xbee}
  s.version = XBee::Version::STRING
  s.licenses = ['AGPL']
  s.platform = Gem::Platform::RUBY

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Landon Cox', 'Mike Ashmore', 'Sten Feldman']
  s.date = %q{2014-03-09}
  s.email = %q{exile@chamber.ee}
  s.executables = %w(apicontrol.rb apilisten.rb ruby-xbee.rb xbeeconfigure.rb xbeedio.rb xbeeinfo.rb xbeelisten.rb xbeesend.rb)
  s.extra_rdoc_files = %w(LICENSE agpl.txt README.rdoc)
  s.files = %w(
    LICENSE
    README.rdoc
    Rakefile
    bin/apicontrol.rb
    bin/apilisten.rb
    bin/ruby-xbee.rb
    bin/xbeeconfigure.rb
    bin/xbeedio.rb
    bin/xbeeinfo.rb
    bin/xbeelisten.rb
    bin/xbeesend.rb
    lib/apimode/at_commands.rb
    lib/apimode/frame/at_command.rb
    lib/apimode/frame/at_command_response.rb
    lib/apimode/frame/explicit_addressing_command.rb
    lib/apimode/frame/explicit_rx_indicator.rb
    lib/apimode/frame/frame.rb
    lib/apimode/frame/modem_status.rb
    lib/apimode/frame/receive_packet.rb
    lib/apimode/frame/remote_command_request.rb
    lib/apimode/frame/remote_command_response.rb
    lib/apimode/frame/transmit_request.rb
    lib/apimode/frame/transmit_status.rb
    lib/apimode/xbee_api.rb
    lib/legacy/command_mode.rb
    lib/module_config.rb
    lib/ruby_xbee.rb
    test/ruby_xbee_test.rb
    test/test_helper.rb)

  s.has_rdoc = true
  s.homepage = %q{http://github.com/exsilium/ruby-xbee}
  s.rdoc_options = %w(--charset=UTF-8)
  s.require_paths = %w(lib)
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Controlling an XBee module from Ruby either in AT (Transparent) or API mode. Both Series 1 and Series 2 radio modules are supported.}
  s.description = %q{A Ruby XBee gem}
  s.test_files = %w(test/ruby_xbee_test.rb
                    test/test_helper.rb)

  s.add_runtime_dependency(%q<serialport>, ['~> 1.1', '>= 1.1.0'])
end
