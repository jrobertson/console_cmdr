#!/usr/bin/env ruby

# file: console_cmdr.rb

require 'cmdr'
require 'io/console'


class ConsoleCmdr < Cmdr


  def cli_banner()
    puts "welcome, this code is powered by the cmdr gem\n\n"
    print "> "
  end
  
  def start(&blk)
    
    cli_banner()

    seq = []
    begin
      c = $stdin.getch
      
      #puts c.ord
      if c.ord == 27 then
        seq << 27
        #print "\b\b"
      elsif c.ord == 91 and seq.first == 27
        seq << 91
      elsif c.ord == 65 and seq[1] == 91
        seq << 65
        c = :arrow_up
        input c
      else
        if block_given? then
          input(c, &blk)
        else
          input(c) do |command|
            #puts 'command:  ' + command.inspect
            case command
            when 'time'
              Time.now.to_s
            end
          end
        end
      end
      
    end until c == "\u0003"

  end
  
  protected
  
  def reveal(c)
    
    char = case c
    when "\u007F" # backspace
      "\b \b"
    else
      c unless c.is_a? Symbol
    end
    print char
  end

  def display_output(s='') 
    print s + "\n> "
  end
  
  def cli_update(s='')
    print s
  end

end

