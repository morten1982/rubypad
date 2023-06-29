class Settings
  attr_accessor :run_commands, :terminal_commands, :interpreter_commands,
                :system, :files_list, :editor_commands
  
  def initialize
    @filename = __dir__ + "/rubypad.ini"
    @run_commands = {}
    @terminal_commands = {}
    @interpreter_commands = {}
    @editor_commands = {}
    @system = {}
    @files_list = []
    @run = false
    @terminal = false
    @interpreter = false
    @editor = false
    @sys = false
    @files = false
    
    open_settings_file(@filename)
    #show
  end
  
  def open_settings_file(filename)
    File.readlines(filename).each do |line|
      case line
      when "[Run]\n"
        @run = true
        @terminal, @interpreter, @editor, @sys, @files = false
        next
      when "[Terminal]\n"
        @terminal = true
        @run,  @interpreter, @editor, @sys, @files = false
        next
      when "[Interpreter]\n"
        @interpreter = true
        @run, @terminal, @editor, @sys, @files = false
        next
      when "[Editor]\n"
        @editor = true
        @run, @terminal, @interpreter, @sys, @files = false
        next
      when "[System]\n"
        @sys = true
        @run, @terminal, @interpreter, @files, @editor = false
        next
      when "[Files]\n"
        @files = true
        @run, @terminal, @interpreter, @editor, @sys = false
        next
      when "\n"
        next
      else
        key, value = line.split('=')
        @run_commands[key] = value.chomp if @run
        @terminal_commands[key] = value.chomp if @terminal
        @interpreter_commands[key] = value.chomp if @interpreter
        @editor_commands[key] = value.chomp if @editor
        @system[key] = value.chomp if @sys
      end
    end
  end
  
  def show
    p @run_commands["gnome"]
    p @interpreter_commands["gnome"]
    p @terminal_commands["gnome"]
    p @editor_commands["theme"]
    p @editor_commands["tabwidth"]
    p @editor_commands['fontsize']
    p @system["system"]
  end
  
  def set_standard
    str = "[Run]\n"
    str += 'gnome=gnome-terminal -- sh -c "ruby <filename>; exec bash"'
    str += "\n"
    str += 'kde=konsole --hold -e "ruby <filename>"'
    str += "\n"
    str += 'xterm=xterm -hold -e "ruby <filename>"'
    str += "\n"
    str += 'windows=start cmd /K ruby <filename>'
    str += "\n"
    str += 'mac=open -a Terminal ./ruby <filename>'
    str += "\n"
    str += "\n"
    str += "[Terminal]\n"
    str += "gnome=gnome-terminal\n"
    str += "kde=konsole\n"
    str += "xterm=xterm\n"
    str += "windows=start cmd\n"
    str += "mac=open -a Terminal ./\n"
    str += "\n"
    str += "[Interpreter]\n"
    str += 'gnome=gnome-terminal -- "irb"'
    str += "\n"
    str += "kde=konsole -e irb\n"
    str += "xterm=xterm irb\n"
    str += "windows=start cmd /K irb\n"
    str += "mac=open -a Terminal ./irb\n"
    str += "\n"
    str += "[Editor]\n"
    str += "theme=dark\n"
    str += "tabwidth=2\n"
    str += "fontsize=11\n"
    str += "highlight=true\n"
    str += "\n"
    str += "[System]\n"
    str += "system=gnome\n"
    str += "\n"
    
    filename = __dir__ + "/" + "rubypad.ini"
  
    begin
      File.write(filename, str)
    rescue 
      p $!.to_s
    end
  end

end

# current script
# current_dir = __dir__ + "/" 
# filename = __dir__ + "/rubypad.ini"

settings = Settings.new
