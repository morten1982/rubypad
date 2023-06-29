require "tk"
require "tkextlib/tile"
require 'fileutils'
require_relative 'faf'
require_relative 'dialogs'

class FilebrowserFrame < Tk::Tile::TFrame
  attr_accessor :codecompletion, :editor, :current_pos, :parent, 
                :selected_item, :hidden, :current_dir
  
  def initialize(parent, editor, overlord)
    @parent = parent
    @selected_item = []
    @hidden = false
    @current_dir = Dir.pwd + '/'
    @editor = editor
    @overlord = overlord        # root
    
    super(parent)
    
    build_gui
    fill(@current_dir, @hidden)     # list hidden files ?
  end
  
  def build_gui
    y_scrollbar = Tk::Tile::Scrollbar.new(self) {orient 'vertical'}
    @filebrowser = Tk::Tile::Treeview.new(self)
    
    
    y_scrollbar.pack('side' => 'right', 'fill' => 'y')
    @filebrowser.pack('side' => 'top', 'fill' => 'both', 'expand' => true)
    
    y_scrollbar['command'] = proc { |*args| @filebrowser.yview(*args) }
    @filebrowser['yscrollcommand'] = proc{ |*args| y_scrollbar.set(*args) }
    
    @filebrowser['show'] = 'tree'     # show just the tree
    
    @filebrowser.bind("Double-1", proc {|event| on_double_click(event) } )
    @filebrowser.bind("Button-1", proc {|event| on_click(event) } ) 
    @filebrowser.bind("Return", proc {|event| on_return(event) } )
    @filebrowser.bind("ButtonRelease-3", proc {|event| on_popup(event) } )
    @filebrowser.bind('Control-h', proc { show_hidden })

  end
  
  def fill(directory=@current_dir, hidden=false)
    faf = FilesAndFolders.new(directory, hidden) 
  
    folder_list = faf.get_all_folders
    file_list = faf.get_all_files
    
    @filebrowser.tag_configure('folder', :foreground => 'dodgerblue')
    @filebrowser.tag_configure('rubyfile', :foreground => '#E0115F')
    
    folder_list.each do |folder|
      @filebrowser.insert('', 'end', :text => "> " + folder, :tags => ['folder'])
    end

    file_list.each do |file|
      if file.end_with? ".rb"
        @filebrowser.insert('', 'end', :text => file, :tags => ['rubyfile'])
      else
        @filebrowser.insert("", 'end', :text => file)
      end
    end 
    
    
  end
  
  def refresh
    @filebrowser.delete(@filebrowser.children('')) # delete all
    fill(@current_dir, @hidden)
  end

  def on_click(event)
    item = @filebrowser.identify(event.x, event.y) 
    if item
      filename = item.text
      @overlord.title = @current_dir + filename
    else
      return
    end
  end
  
  def on_double_click(event)
    item = @filebrowser.identify(event.x, event.y)
    change_folder_or_open_file(item)
  end
  
  def on_return(event)
    item = @filebrowser.identify(event.x, event.y)
    change_folder_or_open_file(item)
  end
  
  def change_folder_or_open_file(item)
    filename = item.text
    if filename.start_with? "> "      # directory -> change dir
      pathname = filename.tr("> ", "")
      begin
        Dir.chdir(pathname)
        @current_dir = Dir.pwd + "/"    # !
        refresh
      rescue
        message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s) 
        Dir.chdir('..')
        refresh
      end
    else                              # file -> open it
      filename = @current_dir + filename
      begin
        content = File.read(filename)
        content.gsub! /\r\n?/, "\n"     # normalize different newlines
        
        file = File.basename(filename)
        
        old_edit = @overlord.editor
        @overlord.button_new(file) unless old_edit.filename == 'noname' && old_edit.get('1.0', 'end-1c') == ""
        @editor = @overlord.editor
        @editor.delete('1.0', 'end')
        @editor.insert 'end', content
        @editor.syntax_highlight_all
        @editor.make_completion_list
        @editor.filename = filename
        @editor.modified = false
        @editor.update_pos
        @overlord.on_tab_changed
  
      rescue
        message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s) 
        refresh
      ensure
        notebook = @editor.parent.parent
        return if notebook.tabs == []
        id = notebook.index('current')
        tabtxt = File.basename(@editor.filename)
        notebook.itemconfigure(id, :text => tabtxt)
        @overlord.on_tab_changed
      end
    @overlord.on_tab_changed
    end
  end
  
  def show_hidden
    unless @hidden
      @hidden = true
    else
      @hidden = false
    end
    
    refresh
    @filebrowser.set_focus
  end
  
  def on_popup(event)
    item = @filebrowser.identify(event.x, event.y)
    @filebrowser.selection_set(item)
    
    menu = TkMenu.new(@parent, :tearoff => false)
    menu.add('command', 'label' => "Info", 'command' => proc {|event| popup_info_item(event, item) })
    menu.add_separator
    menu.add('command', 'label' => 'Create New Folder', 'command' => proc {|event| popup_new_folder(event, item) })
    menu.add_separator
    menu.add('command', 'label' => 'Copy Item', 'command' => proc {|event| popup_copy_item(event, item) })
    menu.add('command', 'label' => 'Paste Item', 'command' => proc {popup_paste_item })
    menu.add('command', 'label' => 'Rename Item', 'command' => proc {|event|  popup_rename_item(event, item) })
    menu.add_separator
    menu.add('command', 'label' => 'Delete Item', 'command' => proc {|event| popup_delete_item(event, item)})
    menu.add_separator
    menu.add('command', 'label' => 'Show Hidden', 'command' => proc {show_hidden})
    menu.add_separator
    menu.add('command', 'label' => 'Open Terminal', 'command' => proc { popup_terminal })
    menu.popup(event.x_root, event.y_root, 0)
  end
  
  def popup_info_item(event, item)
    return unless item
    filename = item.text
    if filename.start_with? "> "
      msg = "Type:\t Directory\n"
      pathname = filename.tr("> ", "") + "/"
    else
      msg = "Type:\t File\n"
      pathname = @current_dir + filename
    end
    size = File.size(pathname)
    # format size -> readable
    formatted_size = size.to_s.reverse.gsub(/...(?=.)/,'\& ').reverse

    msg += "\n" + formatted_size + "\t Bytes\n" if formatted_size.size < 10
    msg += "\n" + formatted_size + "  Bytes\n" if formatted_size.size >= 10
    
    message = Tk.messageBox(
      'type' => 'ok',
      'icon' => 'info',
      'title' => 'Information',
      'message' => msg
    )
  end
  
  def popup_new_folder(event, item)
    return unless item
    filename = item.text
    current_dir = @current_dir
    dialog = CreateDirectoryDialog.new(self, filename, current_dir)
  end
  
  def popup_copy_item(event, item)
    return unless item
    item_name = item.text
    current_dir = @current_dir
    if item_name.start_with? "> "
      directory = true
      item_name.tr!("> ", "")
      filename = current_dir + item_name
    else
      directory = false
      filename = current_dir + item_name
    end
    @overlord.title = "#{filename} -> marked"
    @selected_item = [directory, filename]
  end
  
  def popup_paste_item
    return unless @selected_item.size >= 1
    directory = @selected_item.first
    filename = @selected_item.last
    if directory
      puts "current dir: #{@current_dir}"
      new_dir = File.basename(filename)
      Dir.mkdir(new_dir)
      begin
        FileUtils.copy_entry(filename, @current_dir+ new_dir)
      rescue
        message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s)   # $! global var for: Error
      ensure
        refresh
      end
    else  # must be a file
      begin
        FileUtils.cp(filename, @current_dir)
      rescue
        message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s)        
      ensure
        refresh
      end
    end
  end
  
  def popup_rename_item(event, item)
    return unless item
    filename = item.text
    current_dir = @current_dir
    dialog = RenameDialog.new(self, filename, current_dir)
  end
  
  def popup_delete_item(event, item)
    return unless item
    filename = item.text
    current_dir = @current_dir
    dialog = DeleteItemDialog.new(self, filename, current_dir)
  end
  
  def popup_terminal
    begin
      s = Settings.new
      sys = s.system['system']
      command = s.terminal_commands[sys]
      system(command)
    rescue
      p $!.to_s
    ensure
      refresh
    end
  end
end

def center(root)
    # Center the root screen
    root.update
    width = root.winfo_width()
    frm_width = root.winfo_rootx - root.winfo_x
    win_width = width + 2 * frm_width
    
    height = root.winfo_height
    titlebar_height = root.winfo_rooty - root.winfo_y
    win_height = height + titlebar_height + frm_width
    
    x = root.winfo_screenwidth / 2 - win_width / 2
    y = root.winfo_screenheight / 2 - win_height / 2
  
    root.geometry("#{width}x#{height}+#{x}+#{y}")
    root.deiconify()
end

if __FILE__ == $0 
  root = TkRoot.new {title "Codeeditor - Test"
                    width 1200
                    height 800}
  
  filebrowser_frame = FilebrowserFrame.new(root, nil, nil) do
    pack('padx' => 5, 'pady' => 5, 'expand' => true, 'fill' => 'both')
  end
  
  root.tk_call("source", "forest-dark.tcl")
  ::Tk::Tile::Style.theme_use 'forest-dark'
  
  center(root)
  Tk.mainloop
end

