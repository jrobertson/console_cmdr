#!/usr/bin/env ruby

# file: console_cmdr.rb

require 'cmdr'
require 'pxindex'
require 'terminfo'
require 'io/console'



class ConsoleCmdr < Cmdr

  def initialize(pxindex: nil)
    super()
    @pxindex_filepath = pxindex
    @pxi = pxindex ? PxIndex.new(pxindex) : nil
    
    @keys = []
  end

  def cli_banner()
    puts "welcome, this code is powered by the cmdr gem\n\n"
    print "> "
  end
  
  def reload()
    @pxi = @pxindex_filepath ? PxIndex.new(@pxindex_filepath) : nil
  end
  
  def start(&blk)
    
    cli_banner()

    seq = []
    
    loop do
      
      c = $stdin.getch
      
      #puts c.ord
      
      # [27, 91, 65] = up_arrow
      # [27, 91, 66] = down_arrow
      # [27, 91, 67] = right_arrow
      # [27, 91, 68] = left_arrow
      # 13 = enter
      
      if c.ord == 27 then
        seq << 27
        #print "\b\b"
      elsif c.ord == 91 and seq.first == 27
        seq << 91
      elsif c.ord == 65 and seq[1] == 91
        seq << 65
        c = :arrow_up
        on_keypress(c)
        input c
      elsif c.ord == 66 and seq[1] == 91
        seq << 66
        c = :arrow_down
        on_keypress(c)
        input c        
      elsif c.ord == 67 and seq[1] == 91
        seq << 67
        c = :arrow_right
        on_keypress(c)
        input c         
      elsif c.ord == 68 and seq[1] == 91
        seq << 68
        c = :arrow_left
        on_keypress(c)
        input c         
        
      elsif c == "\u0003"  # CTRL+C        
        puts 
        @linebuffer = ''
        display_output()
      else
        if block_given? then
          on_keypress(c)
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
      
    end #/ end of loop

  end
  
  protected
  
  def reveal(c)

    char = case c
    when "\u007F" # backspace
      "\b \b"
    else
      c unless c.is_a? Symbol
    end
    print char unless @input_selection and @input_selection.any?
  end

  def display_output(s='') 
    print s + "\n> "
  end
  
  def cli_update(s='')
    print s
  end
  
  def on_keypress(key)
    
    return unless @pxi
    

    if key.is_a? String then
      
      @keys = []

      a = @pxi.q?(@linebuffer+key)
    
      if a then
        unless @input_selection == a.map(&:title) then
          @input_selection = a.map(&:title)
          print ("\b" * @linebuffer.length) + @input_selection.inspect + "\n"
        end
        print ("\b" * @linebuffer.length) + @linebuffer + key
      else
        @input_selection = nil
      end
      
    elsif key == :arrow_down or key == :arrow_right
      
      @keys << :arrow_down
      
      linebuffer = @input_selection[@keys.count(:arrow_down) - 1]
      return if linebuffer.nil?


      oldlinebuffer = @linebuffer
      print ("\b" * oldlinebuffer.length)
      
      @linebuffer = linebuffer

      height, width = TermInfo.screen_size 

      rblankpadding =  ' ' * (width - @linebuffer.length )
      print @linebuffer
      print rblankpadding
      print ("\b" * rblankpadding.length)
      
    elsif key == :arrow_left
      
      return if @keys.empty?
      
      @keys.pop
      oldlinebuffer = @linebuffer
      @linebuffer = @input_selection[@keys.count(:arrow_down) - 1]

      print ("\b" * oldlinebuffer.length) + @linebuffer      
    end
  end

end
