require 'tk'
require "tkextlib/tile"
require_relative 'settings'

###########################################
### class -> RenameDialog               ###
###########################################

class RenameDialog < TkToplevel
  attr_accessor :entry, :parent
  
  def initialize(parent, filename, current_dir)
    @filename = filename
    @current_dir = current_dir
    @parent = parent
    
    if @filename.start_with? "> "
      return if @filename == "> .."
      @is_directory = true
      @filename.tr!("> ", "")
      @pathname = @current_dir + @filename
      @title_str = "Rename Directory"
      @label_txt = "Enter new name for directory:"
    else
      @is_file = true
      @pathname = @current_dir + @filename
      @title_str = "Rename File"
      @label_txt = "Enter new name for filename:"
    end
    
    super(parent)
    
    self.protocol "WM_DELETE_WINDOW", proc { self.destroy }
    self.title = @title_str
    
    # make this dialog modal ..
    self.grab_set
    self.transient(@parent)
    
    build_dialog(@label_txt, @filename)
  end
  
  def build_dialog(label_txt, filename)
    txt_label = Tk::Tile::Label.new(self) do
      text label_txt
      pack('side' => 'top')
    end
    
    file_label = Tk::Tile::Label.new(self) do
      text filename
      foreground '#217346'
      pack('side' => 'top')
    end
    
    @entry = Tk::Tile::Entry.new(self) do
      pack('side' => 'top')
    end
    @entry.bind("Return", proc { rename(@pathname, @is_directory, @is_file)})
    
    tk_var = TkVariable.new
    @entry.textvariable = tk_var

    buttonbox = Tk::Tile::Frame.new(self) 
    
    ok_button = Tk::Tile::Button.new(buttonbox) do
      text 'Apply'
      pack('padx' => 5, 'pady' => 5, 'side' => 'left')
    end
    ok_button.command{ rename(@pathname, @is_directory, @is_file) } 
    
    cancel_button = Tk::Tile::Button.new(buttonbox) do
      text 'Cancel'
      pack('padx' => 5, 'pady' => 5, 'side' => 'right')
    end
    cancel_button.command{ cancel }
    
    buttonbox.pack('padx' => 5, 'pady' => 5, 'side' => 'bottom')
    @entry.set_focus
  end
  
  def rename(pathname, is_directory=nil, is_file=nil)
    
    new_filename = @entry.textvariable.value
    
    if is_file
      begin
        File.rename(pathname, File.dirname(pathname) + "/" + new_filename)
      rescue
        message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s)   # $! global var for: Error
      ensure
        @parent.refresh
        self.destroy
      end
    
    elsif is_directory
      self.destroy if new_filename == ""
      begin
        File.rename(pathname, File.dirname(pathname) + "/" + new_filename)
      rescue
        message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s)
      ensure
        @parent.refresh
        self.destroy
      end
    end
  
  end
  
  def cancel
    self.destroy
  end
end

###########################################
### class -> CreateDirectoryDialog      ###
###########################################

class CreateDirectoryDialog < TkToplevel
  attr_accessor :current_dir, :entry
  
  def initialize(parent, filename, current_dir)
    @filename = filename
    @current_dir = current_dir
    @parent = parent
      
    super(parent)
    self.protocol "WM_DELETE_WINDOW", proc { self.destroy }
      
    self.title = "Create Directory"
    
    # make this dialog modal ..
    self.grab_set
    self.transient(@parent)
    
    self.title = @title_str
    
    build_dialog
  end
  
  def build_dialog
    txt_label = Tk::Tile::Label.new(self) do
      text "Create new directory in:"
      pack('side' => 'top')
    end
    
    txt = @current_dir
    dir_label = Tk::Tile::Label.new(self) do
      text txt
      foreground '#217346'
      pack('side' => 'top')
    end
    
    @entry = Tk::Tile::Entry.new(self) do
      pack('side' => 'top')
    end
    @entry.bind("Return", proc { create_directory(@current_dir) })
    
    tk_var = TkVariable.new
    @entry.textvariable = tk_var

    buttonbox = Tk::Tile::Frame.new(self) 
    
    ok_button = Tk::Tile::Button.new(buttonbox) do
      text 'Apply'
      pack('padx' => 5, 'pady' => 5, 'side' => 'left')
    end
    ok_button.command{ create_directory( @current_dir) } 
    
    cancel_button = Tk::Tile::Button.new(buttonbox) do
      text 'Cancel'
      pack('padx' => 5, 'pady' => 5, 'side' => 'right')
    end
    cancel_button.command{ cancel }
    
    buttonbox.pack('padx' => 5, 'pady' => 5, 'side' => 'bottom')
    @entry.set_focus
    
  end
  
  def create_directory(current_dir)
    dirname = @entry.textvariable.value
    begin
      Dir.mkdir(dirname)
    rescue
      message = Tk.messageBox(
        'type' => 'ok',
        'icon' => 'warning',
        'title' => 'Error',
        'message' => $!.to_s)   # $! global var for: Error
    ensure
      @parent.refresh
      self.destroy
    end
  end
  
  def cancel
    self.destroy
  end
end

###########################################
### class -> DeleteItemDialog           ###
###########################################

class DeleteItemDialog < TkToplevel
  attr_accessor :current_dir, :entry
  
  def initialize(parent, filename, current_dir)
    @filename = filename
    @current_dir = current_dir
    @parent = parent

    if @filename.start_with? "> "
      return if @filename == "> .."
      @is_directory = true
      @filename.tr!("> ", "")
      @pathname = @current_dir + @filename
      @title_str = "Delete Directory"
      @label_txt = "Are you sure to delete ?"
    else
      @pathname = @current_dir + @filename
      @title_str = "Delete File"
      @label_txt = "Are you sure to delete ?"
    end

    super(parent)
    self.protocol "WM_DELETE_WINDOW", proc { self.destroy }
    
    # make this dialog modal ..
    self.grab_set
    self.transient(@parent)
    
    self.title = @title_str
    
    build_dialog(@label_txt, @filename)
  end
  
  def build_dialog(label_txt, filename)
    
    txt_label = Tk::Tile::Label.new(self) do
      text label_txt
      pack('side' => 'top')
    end
    
    file_label = Tk::Tile::Label.new(self) do
      text filename
      foreground 'red'
      pack('side' => 'top')
    end

    buttonbox = Tk::Tile::Frame.new(self) 
    
    ok_button = Tk::Tile::Button.new(buttonbox) do
      text 'Apply'
      pack('padx' => 5, 'pady' => 5, 'side' => 'left')
    end
    ok_button.command{ delete( filename) } 
    
    cancel_button = Tk::Tile::Button.new(buttonbox) do
      text 'Cancel'
      pack('padx' => 5, 'pady' => 5, 'side' => 'right')
    end
    cancel_button.command{ cancel }
    
    buttonbox.pack('padx' => 5, 'pady' => 5, 'side' => 'bottom')
    
  end
  
  def delete(filename)
    current_dir = @current_dir
    obj = @current_dir + filename
    
    if @is_directory
      begin
        FileUtils.rm_rf(obj)
      rescue
      message = Tk.messageBox(
        'type' => 'ok',
        'icon' => 'warning',
        'title' => 'Error',
        'message' => $!.to_s)   
      ensure
        @parent.refresh
        self.destroy
      end
    else # must be a file
      begin
        File.delete(obj)
      rescue
      message = Tk.messageBox(
        'type' => 'ok',
        'icon' => 'warning',
        'title' => 'Error',
        'message' => $!.to_s)   
      ensure
        @parent.refresh
        self.destroy
      end
    end
  end
  
  def cancel
    self.destroy
  end
end

###########################################
### class -> GotoLineDialog             ###
###########################################

class GotoLineDialog < TkToplevel
  attr_reader :spinbox, :editor, :spinval
  
  def initialize(parent, editor)
    @parent = parent
    @editor = editor
    @filename = @editor.filename
    
    super(parent)
    self.title = "Goto Line"
    self.protocol "WM_DELETE_WINDOW", proc { cancel }
    
    build_dialog
  end
  
  def build_dialog
    file_base = File.basename(@filename)
    filename_txt = "Filename: #{file_base}"
    
    file_label = Tk::Tile::Label.new(self) do
      text filename_txt
      pack('side' => 'top')
    end
    txt_label = Tk::Tile::Label.new(self) do
      text "Goto Line: "
      pack('side' => 'top')
    end
      
    @spinval = TkVariable.new
    @spinbox = Tk::Tile::Spinbox.new(self) {from 1; to 999999; textvariable @spinval; width 8}
    @spinbox.pack('side' => 'top')
    @spinbox.bind("Return", proc { goto(@editor) })
    buttonbox = Tk::Tile::Frame.new(self) 
    
    ok_button = Tk::Tile::Button.new(buttonbox) do
      text 'Apply'
      pack('padx' => 5, 'pady' => 5, 'side' => 'left')
    end
    ok_button.command{ goto(@editor) } 
    
    cancel_button = Tk::Tile::Button.new(buttonbox) do
      text 'Cancel'
      pack('padx' => 5, 'pady' => 5, 'side' => 'right')
    end
    cancel_button.command{ cancel }
    
    buttonbox.pack('padx' => 5, 'pady' => 5, 'side' => 'bottom')
    @spinbox.set_focus
  end
  
  def goto(editor)
    max = editor.index('end-1c').split('.').first.to_f
    x = @spinbox.value.to_f
    return if x == 0.0
    x = max if x > max
    x = x.to_s
    editor.see(x)
    editor.mark_set('insert', x + " lineend")
    editor.update_pos
    editor.set_focus
    
  end
  
  def cancel
    self.destroy
  end
end


###########################################
### class -> SettingsDialog             ###
###########################################

class SettingsDialog < TkToplevel
  attr_accessor :editor
  
  def initialize(parent, editor)
    @parent = parent
    @editor = editor
    
    super(parent)
    self.title = "Settings"
    self.protocol "WM_DELETE_WINDOW", proc { cancel }
    
    build_dialog
  end
  
  def build_dialog
    notebook = Tk::Tile::Notebook.new(self)
    
    # commands_frame
    commands_frame = Tk::Tile::Frame.new(notebook)
    run_label = Tk::Tile::Label.new(commands_frame, 'text' => 'Run Command:')
    run_label.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    @run_entry = Tk::Tile::Entry.new(commands_frame)
    @run_entry.pack('padx' => 5, 'pady' => 5, 'side' => 'top', 'fill' => 'x')
    terminal_label = Tk::Tile::Label.new(commands_frame, 'text' => 'Terminal Command:')
    terminal_label.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    @terminal_entry = Tk::Tile::Entry.new(commands_frame)
    @terminal_entry.pack('padx' => 5, 'pady' => 5, 'side' => 'top', 'fill' => 'x')
    interpreter_label = Tk::Tile::Label.new(commands_frame, 'text' => 'Interpreter Command:')
    interpreter_label.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    @interpreter_entry = Tk::Tile::Entry.new(commands_frame)
    @interpreter_entry.pack('padx' => 5, 'pady' => 5, 'side' => 'top', 'fill' => 'x')
    systemvar = TkVariable.new
    @system_combobox = Tk::Tile::Combobox.new(commands_frame, :justify => 'center') {textvariable systemvar}
    @system_combobox.values = [ 'Gnome', 'Kde', 'XTerm', 'Windows', 'Mac']
    @system_combobox.state('readonly')
    @system_combobox.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    
    s = Settings.new
    sys = s.system['system']
    x = 0
    case sys
    when "gnome"
      x = 0
    when "kde"
      x = 1
    when "xterm"
      x = 2
    when "windows"
      x = 3
    when "mac"
      x = 4
    end
    @system_combobox.set(@system_combobox.values[x])
    
    @system_combobox.bind("<ComboboxSelected>", proc { do_combobox_selected(@system_combobox) })
    
    # editor_frame
    editor_frame = Tk::Tile::Frame.new(notebook)
    @theme_var = TkVariable.new
    @theme_switch = Tk::Tile::Checkbutton.new(editor_frame, 'style' => 'Switch', 'variable' => @theme_var, 'offvalue' => "Use Color Theme Dark", 'onvalue' => "Use Color Theme Light")
    @theme_switch.textvariable = @theme_var
    @theme_switch.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    @highlight_var = TkVariable.new
    @highlight_switch = Tk::Tile::Checkbutton.new(editor_frame, 'style' => 'Switch', 'variable' => @highlight_var, 'offvalue' => "Syntax Highlighting On", 'onvalue' => "Syntax Highlighting Off" )
    @highlight_switch.textvariable = @highlight_var
    @highlight_switch.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    tab_width_label = Tk::Tile::Label.new(editor_frame, 'text' => 'Tab Width in Whitespaces:')
    tab_width_label.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    @tab_width_combobox = Tk::Tile::Combobox.new(editor_frame, :justify => 'center')
    @tab_width_combobox.values = [ '2', '3', '4', '8']
    @tab_width_combobox.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    font_size_label = Tk::Tile::Label.new(editor_frame, 'text' => 'Font Size:')
    font_size_label.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    @font_size_combobox = Tk::Tile::Combobox.new(editor_frame, :justify => 'center')
    @font_size_combobox.values = ['8', '9', '10', '11', '12', '13', '14', '15', '16']
    @font_size_combobox.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    last_label = Tk::Tile::Label.new(editor_frame, 'text' => "If you change the Color Theme, a restart is required")
    last_label.pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    
    theme = s.editor_commands['theme']
    @theme_switch.set_value("Use Color Theme Dark") if theme == "dark"
    @theme_switch.set_value("Use Color Theme Light") if theme == "light"
    
    highlight = s.editor_commands['highlight']
    @highlight_switch.set_value("Syntax Highlighting On") if highlight == "true"
    @highlight_switch.set_value("Syntax Highlighting Off") if highlight == "false" 
    
    tabs = s.editor_commands['tabwidth']
    y = 0
    case tabs
    when "2"
      y = 0
    when "3"
      y = 1
    when "4"
      y = 2
    when "8"
      y = 5
    else
      y = 0
    end
    @tab_width_combobox.set(@tab_width_combobox.values[y])

    font = s.editor_commands['fontsize']
    z = 0
    case font
    when "8"
      z = 0
    when "9"
      z = 1
    when "10"
      z = 2
    when "11"
      z = 3
    when '12'
      z = 4
    when '13'
      z = 5
    when '14'
      z = 6
    when '15'
      z = 7
    when '16'
      z = 8
    else
      z = 4
    end
    @font_size_combobox.set(@font_size_combobox.values[z])
    
    notebook.add(commands_frame, 'text' => "Commands")
    notebook.add(editor_frame, 'text' => "Editor")
    
    notebook.pack('padx' => 5, 'pady' => 5, 'side' => 'top', 'fill' => 'both')

    buttonbox = Tk::Tile::Frame.new(self) 
    
    ok_button = Tk::Tile::Button.new(buttonbox) do
      text 'Apply'
      pack('padx' => 5, 'pady' => 5, 'side' => 'left')
    end
    ok_button.command{ apply } 
    
    cancel_button = Tk::Tile::Button.new(buttonbox) do
      text 'Cancel'
      pack('padx' => 5, 'pady' => 5, 'side' => 'right')
    end
    cancel_button.command{ cancel }
    
    standard_button = Tk::Tile::Button.new(buttonbox) do
      text 'Set Standard'
      pack('padx' => 5, 'pady' => 5, 'side' => 'right')
    end
    standard_button.command{ set_standard }
    
    buttonbox.pack('padx' => 5, 'pady' => 5, 'side' => 'bottom')
    
    do_combobox_selected(@system_combobox)
  end
  
  def apply
    ##
    ##
    system = @system_combobox.get.downcase

    str = ""
    
    run = false
    terminal = false
    interpreter = false
    editor = false    # local bool editor ... not: @editor -> Codeeditor
    sys = false
    editor = false
    sys = false
    files = false
    
    File.readlines(__dir__ + "/rubypad.ini").each do |line|
      case line
      when "[Run]\n"
        run = true
        terminal, interpreter, editor, sys, files = false
        str += line
        next
      when "[Terminal]\n"
        terminal = true
        run,  interpreter, editor, sys, files = false
        str += line
        next
      when "[Interpreter]\n"
        interpreter = true
        run, terminal, editor, sys, files = false
        str += line
        next
      when "[Editor]\n"
        editor = true
        run, terminal, interpreter, sys, files = false
        str += line
        next
      when "[System]\n"
        sys = true
        run, terminal, interpreter, files, editor = false
        str += line
        next
      when "[Files]\n"
        @files = true
        run, terminal, interpreter, editor, sys = false
        str += line
        next
      end
      
      if line.start_with? system
        line = "#{system}=" + @run_entry.get + "\n" if run
        line = "#{system}=" + @terminal_entry.get + "\n" if terminal
        line = "#{system}=" + @interpreter_entry.get + "\n" if interpreter
        str += line
      elsif line.start_with? "theme"
        x = @theme_switch.variable.to_s
        line = "theme=dark\n" if x.include? "Dark"
        line = "theme=light\n" if x.include? "Light"
        str += line
      elsif line.start_with? "tabwidth"
        line = "tabwidth=#{@tab_width_combobox.get}" + "\n"
        str += line
      elsif line.start_with? "fontsize"
        line = "fontsize=#{@font_size_combobox.get}" + "\n"
        str += line
      elsif line.start_with? "highlight"
        x = @highlight_switch.variable.to_s
        line = "highlight=true\n" if x.include? "On"
        line = "highlight=false\n" if x.include? "Off"
        str += line
      elsif line.start_with? "system"
        line = "system=#{system}" + "\n"
        str += line
      else
        str += line
      end
    end
    
    filename = __dir__ + "/" + "rubypad.ini"
  
    begin
      File.write(filename, str)
    rescue 
      p $!.to_s
    end
    
    # update editor 
    # tabwidth / fontsize
    @editor.tab_width = @tab_width_combobox.get.to_i
    @editor.font_size = @font_size_combobox.get.to_i
    @editor.config_font(@editor.font_size)
    
    # highlight on / off
    x = @highlight_switch.variable.to_s
    if x.include? "On"
      @editor.highlight = true
      @editor.syntax_highlight_all
    else
      @editor.highlight = false 
      @editor.syntax_unhighlight_all
    end
    
    @editor.set_focus
    self.destroy
  end
  
  def cancel
    self.destroy
  end
  
  def set_standard
    settings = Settings.new
    t = Thread.new {settings.set_standard}
    t.join
    new_dialog = SettingsDialog.new(@parent, @editor)
    new_dialog.apply
    
    self.destroy
  end
  
  def do_combobox_selected(combobox=nil)
    settings = Settings.new
    case combobox.current
    when 0    # gnome
      @run_entry.delete(0, 'end')
      @run_entry.insert(0, settings.run_commands['gnome'])
      @terminal_entry.delete(0, 'end')
      @terminal_entry.insert(0, settings.terminal_commands['gnome'])
      @interpreter_entry.delete(0, 'end')
      @interpreter_entry.insert(0, settings.interpreter_commands['gnome'])
    when 1    # kde
      @run_entry.delete(0, 'end')
      @run_entry.insert(0, settings.run_commands['kde'])
      @terminal_entry.delete(0, 'end')
      @terminal_entry.insert(0, settings.terminal_commands['kde'])
      @interpreter_entry.delete(0, 'end')
      @interpreter_entry.insert(0, settings.interpreter_commands['kde'])
    when 2    # xterm
      @run_entry.delete(0, 'end')
      @run_entry.insert(0, settings.run_commands['xterm'])
      @terminal_entry.delete(0, 'end')
      @terminal_entry.insert(0, settings.terminal_commands['xterm'])
      @interpreter_entry.delete(0, 'end')
      @interpreter_entry.insert(0, settings.interpreter_commands['xterm'])
    when 3    # windows
      @run_entry.delete(0, 'end')
      @run_entry.insert(0, settings.run_commands['windows'])
      @terminal_entry.delete(0, 'end')
      @terminal_entry.insert(0, settings.terminal_commands['windows'])
      @interpreter_entry.delete(0, 'end')
      @interpreter_entry.insert(0, settings.interpreter_commands['windows'])
    when 4    # mac
      @run_entry.delete(0, 'end')
      @run_entry.insert(0, settings.run_commands['mac'])
      @terminal_entry.delete(0, 'end')
      @terminal_entry.insert(0, settings.terminal_commands['mac'])
      @interpreter_entry.delete(0, 'end')
      @interpreter_entry.insert(0, settings.interpreter_commands['mac'])
    end
  end
end

###########################################
### class -> SearchDialog             ###
###########################################

class SearchDialog < TkToplevel
  attr_reader :editor
  
  def initialize(parent, editor)
    @parent = parent
    @editor = editor
    @filename = @editor.filename
    
    super(parent)
    self.title = "Search"
    self.protocol "WM_DELETE_WINDOW", proc { cancel }
    
    build_dialog
  end
  
  def build_dialog
    file_base = File.basename(@filename)
    filename_txt = "Filename: #{file_base}"
    
    file_label = Tk::Tile::Label.new(self) do
      text filename_txt
      pack('side' => 'top')
    end
    txt_label = Tk::Tile::Label.new(self) do
      text "Search for: "
      pack('side' => 'top')
    end
    
    @search_var = TkVariable.new
    @search_entry = Tk::Tile::Entry.new(self) do
      textvariable @search_var
      pack('side' => 'top', 'expand' => 'true')
    end
    @search_entry.bind('Return', proc { on_search_return })
    
    buttonbox = Tk::Tile::Frame.new(self) 
    
    @mark_search = TkVariable.new
    @mark_search_checkbox = Tk::Tile::Checkbutton.new(buttonbox) do
      text 'Permanent Mark'
      onvalue 'on'
      offvalue 'off'
      grid('padx' => 5, 'pady' => 5, :column => 0, :row => 0)
    end
    @mark_search_checkbox.variable = @mark_search
    @mark_search.value = "off"
    
    @case_sensitive = TkVariable.new
    @case_sensitive_checkbox = Tk::Tile::Checkbutton.new(buttonbox) do
      text 'Case Sensitive'
      onvalue 'on'
      offvalue 'off'
      grid('padx' => 5, 'pady' => 5, :column => 2, :row => 0)
    end
    @case_sensitive_checkbox.variable = @case_sensitive
    @case_sensitive.value = "off"
    
    @clear_button = Tk::Tile::Button.new(buttonbox) do
      text 'Clear Search Tags'
      grid('padx' => 5, 'pady' => 5, :column => 1, :row => 1)
    end
    @clear_button.command { clear }
    
    @all_button = Tk::Tile::Button.new(buttonbox) do
      text 'All'
      grid('padx' => 5, 'pady' => 5, :column => 0, :row => 2)
    end
    @all_button.command{ search_all } 
    
    @next_button = Tk::Tile::Button.new(buttonbox) do
      text 'Next'
      grid('padx' => 5, 'pady' => 5, :column => 1, :row => 2)
    end
    @next_button.command{ search_next } 
    
    cancel_button = Tk::Tile::Button.new(buttonbox) do
      text 'Cancel'
      grid('padx' => 5, 'pady' => 5, :column => 2, :row => 2)
    end
    cancel_button.command{ cancel }
    
    buttonbox.pack('padx' => 5, 'pady' => 5, 'side' => 'bottom')
    @search_entry.set_focus
  end
  
  def search_all
    @editor.tag_delete("search_result")
    @editor.tag_delete('sel')
    if (@search_pos == "" || @search_pos == nil)
      @search_start = "1.0"
    end
    
    loop {
      if @case_sensitive.value == 'off'
        @search_pos = @editor.tksearch(['nocase'], @search_entry.value, @search_start, 'end')
      elsif @case_sensitive.value == "on"
        @search_pos = @editor.search(@search_entry.value, @search_start, 'end')
      end
    
      return if @search_pos == "" || @search_pos == nil
    
      @editor.tag_configure('search_result', :background => 'darkgreen', :foreground => 'white')
      @editor.tag_configure('perm_result', :background => 'darkred', :foreground => 'white')
      @editor.mark_set('insert', "#{@search_pos+@search_entry.value.size}")
      if @mark_search.value == 'off'
        @editor.tag_add("search_result", @search_pos, "#{@search_pos+@search_entry.value.size}")
      elsif @mark_search.value == 'on'
        @editor.tag_add("perm_result", @search_pos, "#{@search_pos+@search_entry.value.size}")
      end
    
      @search_start = @search_pos+@search_entry.value.size
      @editor.see(@search_pos)
      @editor.set_focus
      @editor.update_pos
    }
  end
  
  def search_next
    @editor.tag_delete("search_result")
    @editor.tag_delete('sel')
    if (@search_pos == "" || @search_pos == nil)
      @search_start = "1.0"
    end
    
    if @case_sensitive.value == 'off'
      @search_pos = @editor.tksearch(['nocase'], @search_entry.value, @search_start, 'end')
    elsif @case_sensitive.value == "on"
      @search_pos = @editor.search(@search_entry.value, @search_start, 'end')
    end
    
    if @search_pos == "" || @search_pos == nil
      @editor.mark_set('insert', '1.0')
      @editor.see('insert')
      @editor.set_focus
      show_end_picture(400)
      @editor.update_pos
      return
    end
    
    @editor.tag_configure('search_result', :background => 'green', :foreground => 'white')
    @editor.tag_configure('perm_result', :background => 'darkred', :foreground => 'white')
    @editor.mark_set('insert', "#{@search_pos+@search_entry.value.size}")
    if @mark_search.value == 'off'
      @editor.tag_add("search_result", @search_pos, "#{@search_pos+@search_entry.value.size}")
    elsif @mark_search.value == 'on'
      @editor.tag_add("perm_result", @search_pos, "#{@search_pos+@search_entry.value.size}")
    end
    
    @search_start = @search_pos+@search_entry.value.size
    @editor.see(@search_pos)
    @editor.set_focus
    @editor.update_pos
  end
  
  def clear
    @editor.tag_delete('search_result')
    @editor.tag_delete('perm_result')
    @editor.tag_delete('sel')
  end
  
  def show_end_picture(seconds)
    canvas = Tk::Canvas.new(@editor, :width => 64, :height => 64)
    canvas.place('relx' => 0.5, 'rely' => 0.5, 'anchor' => 'center')
    filename = __dir__ + '/images/' + "up_arrow.png"
    image = TkPhotoImage.new(:file => filename)
    TkcImage.new(canvas, 0, 0, :image => image, :anchor => 'nw')
    @parent.after(seconds) do
      canvas.destroy
    end
  end
  
  def on_search_return
    search_next
    @search_entry.set_focus
  end
  
  def cancel
    clear
    self.destroy
  end
end
