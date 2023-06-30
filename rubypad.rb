require "tk"
require "tkextlib/tile"
require 'etc'
require_relative 'editorframe'
require_relative 'filebrowserframe'
require_relative 'codeanalyzerframe'
require_relative 'tkballoonhelp'
require_relative 'settings'

class RubyPad < TkRoot
  attr_accessor :buttonbox, :editor, :notebook, :filebrowser, :editorframe,
                :codeanalyzer, :paned_window_right, :paned_window_left,
                :codecompletion, :current_pos, :statusbar, :theme
  
  def initialize(*args)
    super
    self['minsize'] = 500, 250
    self['geometry'] = '1200x800'
    self['title'] = "RubyPad 1.0"
    icon_filename = __dir__ + '/images/' + "rubypad.png"
    image = TkPhotoImage.new(:file => icon_filename)
    self.iconphoto = image
    
    settings = Settings.new
    @theme = settings.editor_commands['theme']
    
    @editor = nil
    
    @buttonbox = Tk::Tile::Frame.new(self) do
      pack('padx' => 5, 'pady' => 5, 'side' => 'top')
    end
    
    @paned_window_right = Tk::Tile::Paned.new(self, 'orient' => 'horizontal') do
      pack('padx' => 5, 'side' => 'top', 'expand' => 1, 'fill' => 'both')
    end
    
    @paned_window_left = Tk::Tile::Paned.new(self) do
      pack('padx' => 5, 'side' => 'left')
    end
    
    @notebook = Tk::Tile::Notebook.new(@paned_window_right) do
      #pack('padx' => 5, 'side' => 'top', 'expand' => 'true')
    end
  
    @notebook.bind("ButtonRelease-1", proc {|event| on_tab_changed(event) } )
    @notebook.bind("ButtonRelease-3", proc {|event| on_notebook_popup(event) } )
    @notebook.bind("B1-Motion", proc {|event| on_notebook_reorder(event)})
    
    @statusbar = Tk::Tile::Label.new(self) do
      text ''
      pack('padx' => 5, 'side' => 'bottom')
    end
    
    build_buttonbox(@theme, @buttonbox)
    button_new
    
    @filebrowser = FilebrowserFrame.new(@paned_window_left, @editor, self) do
    end
    @editor.filebrowser = @filebrowser
    
    @codeanalyzer = CodeanalyzerFrame.new(@paned_window_left, @editor) do
    end
    @editor.codeanalyzer = @codeanalyzer
    
    @paned_window_left.add(@filebrowser, :weight => 1)
    @paned_window_left.add(@codeanalyzer, :weight => 1)
    @paned_window_right.add(@paned_window_left)
    @paned_window_right.add(@notebook)
    
    @editor.theme_use_dark if @theme == 'dark'
    @editor.theme_use_light if @theme == 'light'
    @editor.config_font(@editor.font_size)
    
    self.protocol "WM_DELETE_WINDOW", proc { quit }
    
    center
    
    filename_list = __dir__ + "/" + "filename_list.ini"
    begin
      # if RubyPad opens and closes again -> delete filename_list.ini
      File.readlines(filename_list).each do |filename|
        return if filename == "" || filename == "\n"
        filename.gsub! /\r\n?/, ""
        filename.gsub! /\n/, ""
        
        begin
          content = File.read(filename)
        rescue
         next
        end
        content.gsub! /\r\n?/, "\n"     # normalize different newlines
        
        file = File.basename(filename)
        
        old_edit = @editor
        button_new(file) unless old_edit.filename == 'noname' && old_edit.get('1.0', 'end-1c') == ""
        @editor.delete('1.0', 'end')
        @editor.insert 'end', content
        @editor.syntax_highlight_all
        @editor.make_completion_list
        @editor.filename = filename
        @editor.modified = false
        @editor.update_pos
        id = @notebook.index("current")
        tabtxt = File.basename(filename)
        @notebook.itemconfigure(id, :text => tabtxt)
        on_tab_changed
      end
    rescue
      p $!.to_s
    end
    
    loop
  end

  
  def build_buttonbox(theme, buttonbox)
    if theme == 'light'
      self.tk_call("source", __dir__ + "/" + "forest-light.tcl")
      ::Tk::Tile::Style.theme_use 'forest-light'
    elsif theme == 'dark'
      self.tk_call("source", __dir__ + "/" + "forest-dark.tcl")
      ::Tk::Tile::Style.theme_use 'forest-dark'
    end
    
    add_on = '' if theme == 'light'
    add_on = '2' if theme == 'dark'
    
    new_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_new}) {
      image TkPhotoImage.new(:file => File.expand_path("images/new#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(new_button, 'text'=>' New ')
    
    
    open_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_open}) {
      image TkPhotoImage.new(:file => File.expand_path("images/open#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(open_button, 'text'=>' Open ')
    
    save_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_save}) {
      image TkPhotoImage.new(:file => File.expand_path("images/save#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(save_button, 'text'=>' Save ')
    
    save_as_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_save_as}) {
      image TkPhotoImage.new(:file => File.expand_path("images/saveAs#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(save_as_button, 'text'=>' Save As ')
    
    print_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_print}) {
      image TkPhotoImage.new(:file => File.expand_path("images/print#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(print_button, 'text'=>' Print to HTML ')
    
    undo_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_undo}) {
      image TkPhotoImage.new(:file => File.expand_path("images/undo#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(undo_button, 'text'=>' Undo ')
    
    redo_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_redo}) {
      image TkPhotoImage.new(:file => File.expand_path("images/redo#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(redo_button, 'text'=>' Redo ')
    
    zoom_in_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_zoom_in}) {
      image TkPhotoImage.new(:file => File.expand_path("images/zoomIn#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(zoom_in_button, 'text'=>' Zoom In ')
    
    zoom_out_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_zoom_out}) {
      image TkPhotoImage.new(:file => File.expand_path("images/zoomOut#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(zoom_out_button, 'text'=>' Zoom Out ')
    
    settings_button = Tk::Tile::Button.new(buttonbox, :command => proc {button_settings}) {
      image TkPhotoImage.new(:file => File.expand_path("images/settings#{add_on}.png", __dir__))
      pack(:side => 'left')
    }
    Tk::RbWidget::BalloonHelp.new(settings_button, 'text'=>' Settings ')
    
    separator = Tk::Tile::Separator.new(buttonbox) {
      pack(:padx => 16, :pady => 16, :side => 'left')
    }
    
    run_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_run}) {
      style "Accent.TButton"
      image TkPhotoImage.new(:file => File.expand_path("images/play2.png", __dir__))
      pack(:side => 'right')
    }
    Tk::RbWidget::BalloonHelp.new(run_button, 'text'=>' Run ')
    
    terminal_button = Tk::Tile::Button.new(buttonbox, :command => proc{button_terminal}) {
      image TkPhotoImage.new(:file => File.expand_path("images/terminal#{add_on}.png", __dir__))
      pack(:side => 'right')
    }
    Tk::RbWidget::BalloonHelp.new(terminal_button, 'text'=>' Open Terminal ')
    
    irb_button = Tk::Tile::Button.new(buttonbox, :command => proc {button_irb}) {
      image TkPhotoImage.new(:file => File.expand_path("images/irb#{add_on}.png", __dir__))
      pack(:side => 'right')
    }
    Tk::RbWidget::BalloonHelp.new(irb_button, 'text'=>' Open IRB ')

    search_button = Tk::Tile::Button.new(buttonbox, :command => proc {button_search}) {
      image TkPhotoImage.new(:file => File.expand_path("images/search#{add_on}.png", __dir__))
      pack(:side => 'right')
    }
    Tk::RbWidget::BalloonHelp.new(search_button, 'text'=>' Search ')
  
  end 
  
  def on_tab_changed(event=nil)
    return if @notebook.tabs == []
    tabs = @notebook.tabs
    x = @notebook.index('current')
    editorframe = tabs[x]
    codeeditor = editorframe.editor
    
    @editor = codeeditor
    @codecompletion = @editor.codecompletion
    @current_pos = @editor.current_pos
    @editor.filebrowser = @filebrowser
    @editor.codeanalyzer = @codeanalyzer
  
    # update all components !
    # -> filebrowser
    if @editor.filename == "noname"
      self['title'] = "RubyPad"
    else
      self['title'] = @editor.filename 
      Dir.chdir(File.dirname(@editor.filename))
      @filebrowser.current_dir = Dir.pwd + "/"
      @filebrowser.refresh
    end
    
    # -> codeanalyzer
    if @codeanalyzer
      @codeanalyzer.editor = @editor
      @codeanalyzer.refresh
      text = @editor.get("1.0",'end-1c')
      @codeanalyzer.analyze(text)
    end

    # -> editor
    @editor.set_focus
    
  end
  
  def on_notebook_reorder(event)
    return if @notebook.tabs == []
    current = @notebook.index('current')
  
    begin
      index = @notebook.index("@#{event.x},#{event.y}")
      @notebook.insert(index, current) if index >= 0
    rescue
    end
  end
  
  def button_new(txt='noname')
    @editorframe = EditorFrame.new(@notebook, @theme, self)
    @notebook.add(editorframe, 'text' => txt)
    x = @notebook.tabs.size - 1
    @notebook.select(x)
    
    on_tab_changed

  end
  
  def button_open
    filename = Tk::getOpenFile('initialdir' => Dir.pwd)
  
    return if filename == "noname" || filename == ""

    begin
      content = File.read(filename)
      content.gsub! /\r\n?/, "\n"     # normalize different newlines
        
      file = File.basename(filename)
      p @notebook.tabs
      if @notebook.tabs == []
        button_new(file)
      else
        button_new(file) unless @editor.filename == 'noname' && @editor.get('1.0', 'end-1c') == ""
      end
      
      @editor.delete('1.0', 'end')
      @editor.insert 'end', content
      @editor.syntax_highlight_all
      @editor.make_completion_list
      @editor.filename = filename
      @editor.modified = false
      @editor.update_pos
      on_tab_changed 
  
    rescue
      message = Tk.messageBox(
        'type' => 'ok',
        'icon' => 'warning',
        'title' => 'Error',
        'message' => $!.to_s) 
      @filebrowser.refresh
    ensure
      return if @notebook.tabs == []
      id = @notebook.index('current')
      tabtxt = File.basename(@editor.filename)
      @notebook.itemconfigure(id, :text => tabtxt)
    end
    
  end
  
  def button_save
    return if @notebook.tabs == []
    
    if @editor.filename == "noname"
      button_save_as 
      return
    end
    
    content = @editor.get('1.0', 'end-1c')
    content.gsub! /\r\n?/, "\n"
    filename = @editor.filename
    
    begin
      File.write(filename, content)
    rescue 
      message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s) 
    ensure
      @filebrowser.refresh
    end
    
    @editor.modified = false
    id = @notebook.index('current')
    tabtxt = File.basename(@editor.filename)
    @notebook.itemconfigure(id, :text => tabtxt)
  end
  
  def button_save_as
    return if @notebook.tabs == []
    filename = Tk::getSaveFile('initialdir' => Dir.pwd)
    
    return if filename == "noname" || filename == ""
    
    @editor.filename = filename
    button_save 
    on_tab_changed
    filename  # -> return value for quit "event"
  end
  
  def button_print
    return if @editor.filename == "noname" || @notebook.tabs == []
    text = @editor.get('1.0', 'end-1c')
    filename = File.basename(@editor.filename)
    
    output = ""
    output << "<head>#{filename}</head>\n"
    output << "<body>\n"
    output << '<pre><code>'
    output << "\n#{text}\n"
    output << '</pre></code>'
    output << "</body>"
    output.gsub! /\r\n?/, "\n"
    
    new_filename = @editor.filename + "_.html"
    
    begin
      File.write(new_filename, output)
    rescue 
      message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s) 
    ensure
      @filebrowser.refresh
    end
    
    # just a gimmick ... comment it out if you dont want to use a browser :)
    os = "windows" if Etc.uname[:sysname].start_with? "Windows"
    os = "linux" if Etc.uname[:sysname].start_with? "Linux"
    os = "mac" if Etc.uname[:sysname].start_with? "Darwin"
    
    case os
    when "linux"
      open_str = "firefox #{new_filename}"
    when "windows"
      open_str = "start msedge #{new_filename}"
    when "darwin"
      open_str = "open -a safari #{new_filename}"
    end
    
    begin
      system(open_str)
    rescue
      #p $!.to_S
      return
    end
  end
  
  def button_undo
    @editor.on_undo
    @editor.syntax_highlight_all
  end
  
  def button_redo
    @editor.on_redo
    @editor.syntax_highlight_all
  end
  
  def button_zoom_in
    font_size = @editor.font_size
    if font_size < 50
      font_size += 1 
      @editor.config_font(font_size)
      self['title'] = "Font Size: #{font_size}"
    end
    @editor.set_focus
  end
  
  def button_zoom_out
    font_size = @editor.font_size
    if font_size > 4
      font_size -= 1
      @editor.config_font(font_size)
      self['title'] = "Font Size: #{font_size}"
    end
    @editor.set_focus
  end
  
  def button_settings
    settings = SettingsDialog.new(self, @editor)
  end
  
  def button_search
    search_dialog = SearchDialog.new(self, @editor)
  end
  
  def button_run
    begin
      s = Settings.new
      sys = s.system['system']
      filename = @editor.filename
      command = s.run_commands[sys]     
      command.gsub!("<filename>", filename) 
      th = Thread.new { system(command) }
    rescue
      p $!.to_s
    end
  end
  
  def button_terminal
    begin
      s = Settings.new
      sys = s.system['system']
      filename = @editor.filename
      command = s.terminal_commands[sys]     
      command.gsub!("<filename>", filename) 
      th = Thread.new { system(command) }
    rescue
      p $!.to_s
    end
  end
  
  def button_irb
    begin
      s = Settings.new
      sys = s.system['system']
      filename = @editor.filename
      command = s.interpreter_commands[sys]     
      command.gsub!("<filename>", filename) 
      th = Thread.new { system(command) }
    rescue
      p $!.to_s
    end
  end
  
  def on_notebook_popup(event)
    return if @notebook.tabs == []
    
    begin
      index = @notebook.index("@#{event.x},#{event.y}")
      @notebook.select(index)
      on_tab_changed
    rescue
      return
    end
    #x = @notebook.index('current')
    txt = File.basename(@editor.filename)
    #@notebook.select(x)
    
    menu = TkMenu.new(self, :tearoff => false)
    menu.add('command', 'label' => "Close: #{txt}", 'command' => proc { on_close_tab })
    menu.popup(event.x_root, event.y_root, 0)
  end
  
  def on_close_tab
    return if @notebook.tabs == []
    @codeanalyzer.refresh if @notebook.tabs.size == 1
    
    x = @notebook.index('current')
    editorframe = @notebook.tabs[x]
    filename = File.basename(@editor.filename)
    if editorframe.editor.modified
      message = Tk.messageBox(
        'type' => 'yesnocancel',
        'icon' => 'question',
        'title' => 'Save ?',
        'message' => "Save changes to #{filename} before closing ?") 
      if message == 'yes'
        button_save
        @notebook.forget(x)
      elsif message == "no"
        @notebook.forget(x)
      else
        return
      end
    else
      @notebook.forget(x)
    end
    
    self['title'] = "RubyPad" if @notebook.tabs == []
    @filebrowser.set_focus if @notebook.tabs == []
    
    begin
      @notebook.select(0)
      on_tab_changed 
    rescue
      return
    end
  end
  
  def center
    self.update
    width = self.winfo_width()
    frm_width = self.winfo_rootx - self.winfo_x
    win_width = width + 2 * frm_width
    
    height = self.winfo_height
    titlebar_height = self.winfo_rooty - self.winfo_y
    win_height = height + titlebar_height + frm_width
    
    x = self.winfo_screenwidth / 2 - win_width / 2
    y = self.winfo_screenheight / 2 - win_height / 2
  
    self.geometry("#{width}x#{height}+#{x}+#{y}")
    self.deiconify()
  end

  def loop
    Tk.mainloop
  end
  
  def quit
    # go through all opened tabs
    # look if file is modified ... save it ?
    # then remember filename with full path to open it next time again
    tab_list_size = @notebook.tabs.size
    tab_list = @notebook.tabs
    filename_list = []
    
    tab_list.each do |editorframe|
      @notebook.select(0)
      on_tab_changed
      filename = @editor.filename
      modified = @editor.modified
      if filename == "noname" && modified == true
        message = Tk.messageBox(
        'type' => 'yesno',
        'icon' => 'question',
        'title' => 'Save ?',
        'message' => "Save changes to #{filename} before closing ?") 
        if message == 'yes'
          filename = button_save_as
          filename_list << filename
          @notebook.forget(0)
        elsif message == "no"
          @notebook.forget(0)
          next
        end
      elsif filename == "noname"
        @notebook.forget(0)
        next
      elsif modified      # true ?
        message = Tk.messageBox(
        'type' => 'yesno',
        'icon' => 'question',
        'title' => 'Save ?',
        'message' => "Save changes to\n\n #{filename} \n\nbefore closing ?") 
        if message == 'yes'
          button_save
          filename_list << filename
          @notebook.forget(0)
        elsif message == "no"
          @notebook.forget(0)
          filename_list << filename
          next
        end
      else
        filename_list << filename
        @notebook.forget(0)
      end
      
    end

    filename = __dir__ + "/" + "filename_list.ini"
    
    file = File.open(filename, "w")

    filename_list.each do |line|
      file.puts line
    end

    file.close

    self.destroy
  end
end

rubypad = RubyPad.new
