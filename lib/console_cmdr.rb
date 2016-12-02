#!/usr/bin/env ruby

# file: console_cmdr.rb

require 'cmdr'
require 'pxindex'
require 'colored'
require 'terminfo'
require 'io/console'


class ConsoleCmdr < Cmdr

  def initialize(pxindex: nil)
    super()
    @pxindex_filepath = pxindex
    @pxi = pxindex ? PxIndex.new(pxindex) : nil
    
    @keys = []
    @item_selected = ''
    @input_selection = []
    @running = true
  end
  
  def clear()
    @linebuffer = ''
    print "\e[H\e[2J"
    ''
    #cli_banner()
  end  

  def cli_banner()
    puts "welcome, this code is powered by the cmdr gem\n\n"
    print "> "
  end
  
  def reload()
    @pxi = @pxindex_filepath ? PxIndex.new(@pxindex_filepath) : nil
    'reloaded'
  end
  
  def start(&blk)
    
    cli_banner()

    seq = []
    
    while @running do
      
      c = $stdin.getch
      #puts 'c:'  + c.inspect
      #puts c.ord
      
      # [27, 91, 65] = up_arrow
      # [27, 91, 66] = down_arrow
      # [27, 91, 67] = right_arrow
      # [27, 91, 68] = left_arrow
      # [27, 91, 49, 53] = ctrl+right_arrow
      # 13 = enter
      #puts 'seq: ' + seq.inspect
      
      if c.ord == 27 then
        seq << 27
        #print "\b\b"
      elsif c.ord == 91 and seq.first == 27
        seq << 91
      elsif c.ord == 65 and seq[1] == 91
        seq << 65
        c = :arrow_up
        on_keypress(c)
        #input c
      elsif c.ord == 66 and seq[1] == 91
        seq << 66
        c = :arrow_down
        seq = []
        on_keypress(c)
        input c        
        
      elsif c.ord == 68 and seq[1] == 91
        seq << 68
        c = :arrow_left
        seq = []
        on_keypress(c)
        input c         
      elsif c.ord == 49 and seq[1] == 91
        seq << 49
        #puts 'ctrl + right arrow'
      elsif c.ord == 59 and seq[2] == 49
        seq << 59
      elsif c.ord == 53 and seq[3] == 59
        seq << 53        
      elsif c.ord == 67 and seq[4] == 53
        seq << 67
        seq = []
        c = :ctrl_arrow_right
        on_keypress(c)
        input c        
      elsif c.ord == 67 and seq[1] == 91
        seq << 67
        c = :arrow_right
        #puts 'right arrow'
        seq = []
        on_keypress(c)
        input c         
      elsif c.ord == 79 and seq.first == 27
        seq << 79

      elsif c.ord == 72 and seq[1] == 79
        c = :home_key
        seq = []
        on_keypress(c)
      elsif c == "\u0003"  # CTRL+C        
        puts 
        @linebuffer = ''
        display_output()
      else
        if block_given? then
          char = on_keypress(c)

          unless (@linebuffer[0] == ':' and char == ':')
            input(char, &blk) if char
          end
          
        else
          input(c) do |command|

            case command
            when 'time'
              Time.now.to_s
            end
          end
        end
      end
      
    end #/ end of loop

  end
  
  def stop()
    
    @running = false    
    'bye'
  end
  
  alias quit stop
  
  protected
  
  def reveal(c)

    char = case c
    when "\u007F" # backspace
      "\b \b"
    else
      c unless c.is_a? Symbol
    end
    #puts 'inside reveal'
    print char unless @input_selection and @input_selection.any?
  end

  def display_output(s='') 
    print s + "\n> "
  end
  
  def cli_update(s='')
    print s
  end
  
  def on_keypress(key)
    
    return key if @linebuffer[0] == ':'
    return key unless @pxi
    
    if key.is_a? String then
      
      @keys = []

      if key.to_i.to_s == key and @input_selection and @input_selection.any?
        key = select_item(key.to_i-1)        
        
      end

      query key if key
      
    elsif key == :arrow_down or key == :arrow_right      

      return if  @input_selection.nil?      
      
      @keys << :arrow_down      

      i = @keys.count(:arrow_down) - 1
      
      if i == @selection.length then
        @keys.pop
        return nil
      end
      
      select_item(i)
      
    elsif key == :arrow_left

      return nil if @keys.empty?
      
      @keys.pop
      oldlinebuffer = @linebuffer
      @linebuffer = @input_selection[@keys.count(:arrow_down) - 1]
      
      height, width = TermInfo.screen_size 

      print ("\b" * oldlinebuffer.length)
      rblankpadding =  ' ' * (width)
      print rblankpadding
      print ("\b" * rblankpadding.length)      
      
      print @linebuffer
      
    elsif key == :home_key

      height, width = TermInfo.screen_size 

      print ("\b" * @linebuffer.to_s.length)
      @linebuffer = ''
      rblankpadding =  ' ' * (width)
      print rblankpadding
      print ("\b" * rblankpadding.length)   
      
    elsif key == :ctrl_arrow_right
      
      return if  @input_selection.nil?      
      
      @keys << :arrow_down      

      i = @keys.count(:arrow_down) - 1
      
      if i == @selection.length then
        @keys.pop
        return nil
      end
      
      select_item(i, append_command: true)
    end
    
    return key
  end
  
  private
  
  def select_item(i, append_command: false)


    execute_command = false
    
    linebuffer = @input_selection[i]
    @item_selected = @input_selection[i]
    return if linebuffer.nil?


    oldlinebuffer = @linebuffer
    print ("\b" * oldlinebuffer.length)

    type = @selection[-1][-1]
    branch = @selection[i][1] == :branch

    if  branch or append_command or type == :message then
      
      if @linebuffer[-1] != ' ' then
        a = @linebuffer.split(/ /)
        a.pop
        @linebuffer = a.join ' '
      end
      
      linebuffer.prepend @linebuffer
      execute_command = false
    else      

      execute_command = true unless type == :interactive
    end
    
    execute_command = true if type == :message

    if @selection[i][1] == :branch then
      words = @linebuffer.split(/ /)      
      @linebuffer = (words[0..-2] + [linebuffer]).join(' ') 
    else
      @linebuffer = linebuffer
    end

    height, width = TermInfo.screen_size 

    rblankpadding =  ' ' * (width - @linebuffer.length )
    print @linebuffer
    print rblankpadding
    print ("\b" * rblankpadding.length)    
    
    
    return execute_command ? "\r" : (branch and type != :webpage) ? ' ' : nil

  end
  
  def query(key)
    
    a = @pxi.q?(@linebuffer+key)

    if a then
      
      unless @input_selection == a.map(&:title) then
        @input_selection = a.map(&:title)
        @selection = a.map.with_index do |x,i| 
          
          branch = x.records.any? ? :branch : nil

          title = x.title
          # is the target a web page?
          title = title.green  if x.target[0] == 'w' 
          title << '>' if branch
          
          ["%d.%s" % [i+1, title], branch, x.desc.yellow, target(x.target.to_s)]
          
        end
        
        print ("\b" * @linebuffer.length) + @selection.map \
            {|x| x.values_at(0,2).join ' '}.join(" | ") + "\n"

      end
      
      print ("\b" * @linebuffer.length)
      
      if (@linebuffer[/\s/] or a.length == 1) and key == ' ' then

        @linebuffer.sub!(/\w+$/, @item_selected)
        
      end
      
      print @linebuffer + key
      
    else
      
      @input_selection = nil
      
    end  
    
  end

  def target(c)
    
    case c.to_sym
    when :i 
      :interactive
    when :w 
      :webpage      
    when :m
      :message
    else
      :command
    end
  end
  
end