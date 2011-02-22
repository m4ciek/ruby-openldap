#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'rbconfig'
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"
	extdir = libdir + Config::CONFIG['sitearch']

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
	$LOAD_PATH.unshift( extdir.to_s ) unless $LOAD_PATH.include?( extdir.to_s )
}

require 'pp'
require 'yaml'
require 'logger'

require 'openldap'
require 'openldap/mixins'

require 'spec/lib/constants'

### Return a string-comparable version vector from +version+.
def vvec( version )
	return version.split( '.' ).map( &:to_i ).pack( 'N' )
end


### RSpec helper functions.
module OpenLDAP::SpecHelpers
	include OpenLDAP::TestConstants

	class ArrayLogger
		### Create a new ArrayLogger that will append content to +array+.
		def initialize( array )
			@array = array
		end

		### Write the specified +message+ to the array.
		def write( message )
			@array << message
		end

		### No-op -- this is here just so Logger doesn't complain
		def close; end

	end # class ArrayLogger


	unless defined?( LEVEL )
		LEVEL = {
			:debug => Logger::DEBUG,
			:info  => Logger::INFO,
			:warn  => Logger::WARN,
			:error => Logger::ERROR,
			:fatal => Logger::FATAL,
		  }
	end


	###############
	module_function
	###############

	### Reset the logging subsystem to its default state.
	def reset_logging
		OpenLDAP.reset_logger
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=Logger::FATAL )

		# Turn symbol-style level config into Logger's expected Fixnum level
		if OpenLDAP::Loggable::LEVEL.key?( level )
			level = OpenLDAP::Loggable::LEVEL[ level ]
		end

		logger = Logger.new( $stderr )
		OpenLDAP.logger = logger
		OpenLDAP.logger.level = level

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			Thread.current['logger-output'] = []
			logdevice = ArrayLogger.new( Thread.current['logger-output'] )
			OpenLDAP.logger = Logger.new( logdevice )
			# OpenLDAP.logger.level = level
			OpenLDAP.logger.formatter = OpenLDAP::HtmlLogFormatter.new( OpenLDAP.logger )
		end
	end


end


### Mock with Rspec
Rspec.configure do |config|
	config.mock_with :rspec

	config.extend( OpenLDAP::TestConstants )

	config.include( OpenLDAP::TestConstants )
	config.include( OpenLDAP::SpecHelpers )

	config.filter_run_excluding( :ruby_1_9_only => true ) if vvec( RUBY_VERSION ) >= vvec( '1.9.0' )
end

# vim: set nosta noet ts=4 sw=4:

