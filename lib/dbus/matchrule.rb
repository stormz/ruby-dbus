# This file is part of the ruby-dbus project
# Copyright (C) 2007 Arnaud Cornet and Paul van Tilburg
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License, version 2.1 as published by the Free Software Foundation.
# See the file "COPYING" for the exact licensing terms.

module DBus
  # Exception raised when an erroneous match rule type is encountered.
  class MatchRuleException < Exception
  end

  # = D-Bus match rule class
  #
  # FIXME
  class MatchRule
    # The list of possible match filters. TODO argN, argNpath
    FILTERS = [:sender, :interface, :member, :path, :destination, :type].freeze
    # The sender filter.
    attr_accessor :sender
    # The interface filter.
    attr_accessor :interface
    # The member filter.
    attr_accessor :member
    # The path filter.
    attr_accessor :path
    # The destination filter.
    attr_accessor :destination
    # The type type that is matched.
    attr_reader :type

    # Create a new match rule
    def initialize
      @sender = @interface = @member = @path = @destination = @type = nil
    end

    # Set the message types to filter to type _t_.
    # Possible message types are: signal, method_call, method_return, and error.
    def type=(t)
      if !["signal", "method_call", "method_return", "error"].member?(t)
        raise MatchRuleException, t
      end
      @type = t
    end

    # Returns a match rule string version of the object.
    # E.g.:  "type='signal',sender='org.freedesktop.DBus',interface='org.freedesktop.DBus',member='Foo',path='/bar/foo',destination=':452345.34',arg2='bar'"
    def to_s
      FILTERS.select do |sym|
        !method(sym).call.nil?
      end.collect do |sym|
        "#{sym}='#{method(sym).call}'"
      end.join(",")
    end

    # Parses a match rule string _s_ and sets the filters on the object.
    def from_s(str)
      str.split(",").each do |eq|
        next unless eq =~ /^(.*)='([^']*)'$/
        # "
        name = Regexp.last_match(1)
        val = Regexp.last_match(2)
        if FILTERS.member?(name.to_sym)
          method(name + "=").call(val)
        else
          raise MatchRuleException, name
        end
      end
      self
    end

    # Sets the match rule to filter for the given _signal_ and the
    # given interface _intf_.
    def from_signal(intf, signal)
      signal = signal.name unless signal.is_a?(String)
      self.type = "signal"
      self.interface = intf.name
      self.member = signal
      self.path = intf.object.path
      self
    end

    # Determines whether a message _msg_ matches the match rule.
    def match(msg)
      if @type
        if { Message::SIGNAL => "signal", Message::METHOD_CALL => "method_call",
             Message::METHOD_RETURN => "method_return",
             Message::ERROR => "error" }[msg.message_type] != @type
          return false
        end
      end
      return false if @interface && @interface != msg.interface
      return false if @member && @member != msg.member
      return false if @path && @path != msg.path
      # FIXME: sender and destination are ignored
      true
    end
  end # class MatchRule
end # module D-Bus
