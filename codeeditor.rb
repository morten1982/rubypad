require 'tk'
require 'tkextlib/tile'
require_relative 'settings'

class Codeeditor < Tk::Text
  attr_accessor :codecompletion, :current_pos, :filename, :document,
                :filebrowser, :codeanalyzer, :parent, :modified,
                :font_size, :tab_width, :standard_font, :highlight
  
  ##
  # init
  ##
  def initialize(parent, theme)
    
    @parent = parent
    @keywords = %w[__ENCODING__ __LINE__ __FILE__ BEGIN END alias and \
                begin break case class def defined? do else elsif \
                end ensure false for if in module next nil not or \
                redo rescue retry return self super then true undef \
                unless until when while yield puts gets super \
                self require require_relative proc]
    @operators = %w[+ - * / ** = == < > >= <= <=> \~ =~ *= += -= /= << >> < > \
                    % === != !~ **= %= => ]
    
    @current_input = ""
    @codecompletion = parent.codecompletion   # -> need label in parent frame !
    @current_pos = parent.current_pos         # -> label for position
    @filename = "noname"
    @completion_list = []
    @document = ''
    @filebrowser = nil
    @codeanalyzer = nil
    @modified = false
    @theme = theme
    
    super(parent)
    
    theme_use_dark if @theme == "dark"
    theme_use_light if @theme == 'light'
    
    self.bind("KeyRelease", proc {|event| on_key_release(event) } )
    self.bind("Tab") { on_key_tab; break; }    # break prevent "Tab" to tab
    self.bind('Return') { try_indent; break; }
    self.bind('BackSpace') { on_key_backspace }
    self.bind('Control-x') { on_cut; break; }
    self.bind('Control-c') { on_copy; break; }
    self.bind('Control-v') { on_paste; break; }
    self.bind('<Selection>', proc {|event| on_selection(event) } )
    self.bind("ButtonRelease-3", proc {|event| on_popup(event) } )
    self.bind("ButtonRelease-1", proc { update_pos} )
    self.bind('Control-g', proc {@parent.on_double_click_pos(self)} )
    self.bind('<Modified>', proc {mark_modified})
    # shortcuts
    self.bind("Control-n", proc {@parent.overlord.button_new})
    self.bind("Control-o", proc {@parent.overlord.button_open})
    self.bind("Control-s", proc {@parent.overlord.button_save})
    self.bind("Control-Shift-KeyPress-S", proc {@parent.overlord.button_save_as})
    self.bind("Control-p", proc {@parent.overlord.button_print})
    self.bind("Control-plus", proc {@parent.overlord.button_zoom_in})
    self.bind("Control-minus", proc {@parent.overlord.button_zoom_out})
    self.bind("F5", proc {@parent.overlord.button_run})
    self.bind("F8", proc {@parent.overlord.button_terminal})
    self.bind("F7", proc {@parent.overlord.button_irb})
    self.bind("F2", proc {@parent.overlord.button_settings})
    self.bind("Control-f", proc {@parent.overlord.button_search})
    
    
        
    
    
    

    make_completion_list
    
    settings = Settings.new
    @tab_width = settings.editor_commands['tabwidth'].to_i
    @font_size = settings.editor_commands['fontsize'].to_i
    config_font(@font_size)
    
    @highlight = settings.editor_commands['highlight']
    
  end
  
  def theme_use_dark
    self.configure('insertbackground' => 'orange')
    self.configure('background' => '#343d46')   
    self.configure('foreground' =>'#ffffff')
    self.tag_configure("sel", background: "#053582", foreground: "white")
    self.tag_configure('keyword', foreground: 'dodgerblue')  # #448DC4 lightblue
    self.tag_configure('string', foreground: 'green')   
    self.tag_configure('operator', foreground: 'red')  
    self.tag_configure('number', foreground: 'lime')  
    self.tag_configure('decorator', foreground: 'darkorange') 
    self.tag_configure('global', foreground: 'chocolate')
    self.tag_configure('comment', foreground: 'gray')
    self.tag_configure('regex', foreground: 'olive')
  end
  
  def theme_use_light
    self.configure('insertbackground' => 'black')
    self.configure('background' => '#F2F2F2')       # #FFFFFF
    self.configure('foreground' =>'#000000')
    self.tag_configure("sel", background: "#e0e0e0", foreground: "black")
    self.tag_configure('keyword', foreground: 'blue') 
    self.tag_configure('string', foreground: 'green')   
    self.tag_configure('operator', foreground: 'red')  
    self.tag_configure('number', foreground: 'lime')  
    self.tag_configure('decorator', foreground: 'darkorange') 
    self.tag_configure('global', foreground: 'chocolate')
    self.tag_configure('comment', foreground: 'gray')
    self.tag_configure('regex', foreground: 'olive')
  end
  
  ##
  # syntaxhighlight line
  ##
  def syntax_highlight_line(current_index=nil)
    return if @highlight == "false"
    if current_index
      start_index = current_index
    else 
      start_index = "1.0"
    end

    line_number = start_index.split('.')[0]
    line_beginning = line_number + "." + "0"
    line_text = self.get(line_beginning, line_beginning + " lineend")
    
    line_words = line_text.split
    y = leading_spaces = line_text.count(' ') - line_text.lstrip.count(' ')
  
    # delete old tags
    self.tag_names.each do |tag|
      if tag == 'sel'
        next
      else
        self.tag_remove(tag, line_beginning, line_beginning + " lineend")
      end
    end
    
    
    is_string = false
    case line_text           # complete line
    when /("|').*("|')/      # string
      start_i = line_number + "." + line_text.index(/("|').*("|')/).to_s
      end_i = line_number + "." + ($`.size + $&.size).to_s
      self.tag_add('string', start_i, end_i)
    end
    
    #stripped_line_text = line_text.tr("(){}[],.", " ")
    #stripped_line_words = stripped_line_text.split
    
    line_words.each do |word|   # words in complete line
      word_start = y.to_s
      word_end = (y + word.size).to_s
      start_index = line_number + "." + word_start
      end_index = line_number + "." + word_end
    
      stripped_word = word.tr("(){}[],.", " ")
      #p stripped_word         # debugging ?
      stripped_word = stripped_word.split.first
      
      if stripped_word          # stripped word to detect strings, etc...
        w_end = (y + stripped_word.size).to_s     # modifed start
        e_index = line_number + "." + w_end       # modified end
      else
        w_end = "0"
        e_index = line_number + "." + w_end
      end
      
      case stripped_word                # take stripped word for....
      when /^(\+|\-|\*|\/|=|>|<|!|%|\,)/       # operator?
        self.tag_add('operator', start_index, e_index) #unless is_string
      #when /^\d+/
        #self.tag_add('number', start_index, e_index) unless is_string
      when /^'.*/, /^".*/     # start_with? string
        is_string = true
      when /.*'$/, /.*"$/     # end_with? string
        is_string = false
      when /^@/                   # is decorator?
        self.tag_add('decorator', start_index, e_index) unless is_string
      when /^\$/                  # is global?
        self.tag_add('global', start_index, e_index) unless is_string
      end
      
      @keywords.each do |keyword|
        if keyword == stripped_word 
          self.tag_add('keyword', start_index, e_index) #unless is_string
        end
      end
      
      # comment ?
      if word.start_with? "#"
        end_of_line = line_number + "." + word_start + " lineend"
        self.tag_add('comment', start_index, end_of_line) # end_index word !
      end
      
      if word.start_with?(/\#\{.*\}/) # if #{} in text -> delete    
        self.tag_remove("comment", start_index, end_index + " lineend")
      end
      
      if word.start_with?(/^\/.*\//) # regex
        self.tag_add('regex', start_index, end_index) unless is_string
      end
      
    y += word.size + 1
    end
  end
  
  ##
  # syntaxhighlight all
  ##
  
  def syntax_highlight_all  # <- remember
    final_index = self.index('end')
    final_line_number = final_index.split('.')[0].to_i
    (0..final_line_number).step(1) do |n|
      line_to_tag = n.to_s << "." << "0"
      syntax_highlight_line(line_to_tag) # -> call line
    end
  end
  
  def syntax_unhighlight_all
    final_index = self.index('end')
    final_line_number = final_index.split('.')[0].to_i
    (0..final_line_number).step(1) do |n|
      line_to_tag = n.to_s << "." << "0"
      syntax_unhighlight_line(line_to_tag) # -> call line
    end
  end
  
  def syntax_unhighlight_line(current_index=nil)
    if current_index
      start_index = current_index
    else 
      start_index = "1.0"
    end
    
    line_number = start_index.split('.')[0]
    line_beginning = line_number + "." + "0"
    line_text = self.get(line_beginning, line_beginning + " lineend")
    
    line_words = line_text.split
    y = leading_spaces = line_text.count(' ') - line_text.lstrip.count(' ')
  
    # delete old tags
    self.tag_names.each do |tag|
      if tag == 'sel'
        next
      else
        self.tag_remove(tag, line_beginning, line_beginning + " lineend")
      end
    end
  end

  def try_indent
    index = self.index('insert')
    line_number = index.split('.')[0]
    line_beginning = line_number + "." + "0"
    line_text = self.get(line_beginning, line_beginning + " lineend")
    leading_spaces = line_text.count(' ') - line_text.lstrip.count(' ')
    indented_str = "\n" + " " * leading_spaces
    self.insert(index, indented_str)
    update_completion_list
    self.see('insert')
    
    if @codeanalyzer
      @codeanalyzer.refresh
      text = self.get("1.0",'end-1c')
      @codeanalyzer.analyze(text)
    end
  end

  def on_selection(event)
    # do
  end

  def on_key_release(event=none)
    # debugging
    #p event.keysym
    @modified = true
    mark_modified
    
    index = self.index('insert').split(".")
    current_line = index.first
    current_char = index.last
    current_pos = current_line << "." << current_char
    x = event.keysym
    unwanted_keys = %w[Super_L Super_R Space Backspace \
                      Alt_L Alt_R Shift_L Shift_R]
  
    if x.size == 1
      @current_input += x unless x =~ /\A[-+]?[0-9]+\z/
    elsif unwanted_keys.include? x
      return
    elsif @current_input.size >= 25
      @current_input = ""
    else
      @current_input = ""
    end
    
    compare_input_to_completion_list
    syntax_highlight_line(current_pos) if @highlight
    update_pos
    
  end

  def compare_input_to_completion_list
    input = @current_input
    if input.size >= 3
      @completion_list.each do |word|
        if word.start_with?(input)
          @codecompletion.text = word
          break
        else
          @codecompletion.text = "---"
        end
      end
    else
      @codecompletion.text = "---"
    end
  end

  def on_key_tab
    current_pos = self.index('insert')
    txt = @codecompletion.text
    input = @current_input
    x , y = current_pos.split('.')
    y = y.to_i - (input.size)
    old_position = "#{x}.#{y}"
    unless txt == "---"
      self.delete(old_position, current_pos)
      self.insert('insert', txt)
      @codecompletion.text = "---" 
    else
      tab_width = @tab_width
      current_y_pos = self.index('insert').split('.').last.to_i
      #p current_y_pos    debugging
      if @tab_width == 2
        if current_y_pos.even?
          self.insert('insert', " " * tab_width)  
        else
          self.insert('insert', " ")
        end
      else
        self.insert('insert', ' ' * tab_width)
      end
    end
    self.see('insert')
  end

  def make_completion_list
    text = self.get("1.0", "end")
    symbol_list = %w[( ) { } : , . = ; < > ' " !]
    symbol_list.each do |c|
      text.tr!(c, " ")
      text.tr!('(', ' ')
      text.tr!(')', ' ')
    end
  
    first_list = []
    second_list = []
    third_list = []
  
    text.each_line do |line|
      l = line.lstrip
      if l.start_with? '#'
        next
      else
        first_list << l
      end
    end
   
    first_list.each do |line|
      if line.start_with? '#'  # delete comment line
        next
      else
        second_list << line
      end
    end
  
    second_list = first_list.map{ |s| s.split }
    second_list.each do |item|
      item.each do |i|
        if i.to_s == "#"
          break                 # comment in line or substitution
        elsif i.size < 3
          next
        elsif i.size > 25
          next
        elsif i =~ /\A\d+\Z/    # number?
          next
        elsif i =~ /[<>%\${}]/
          next
        else
          third_list << i.rstrip
        end
      end
    end
    
    @keywords.each do |keyword|
      third_list << keyword
    end
    
    third_list = third_list.uniq # delete duplicates !
    @completion_list = third_list
  end

  def update_completion_list
    index = self.index('insert')
    line_number = index.split('.')[0]
    l_number = (line_number.to_i)-1
    line_beginning = "#{l_number}.0"
    line_text = self.get(line_beginning, line_beginning + " lineend")
    text_str = line_text.strip
    text_lst = text_str.split
    update_list = []
    text_lst.each do |word|
      stripped_word = word.tr('(', '').tr(')', '').tr( \
                              ':', '').tr(';', '').tr('[', '').tr(\
                              ']', '').tr('"', ' ').tr("'", ' ')
      if word.start_with?('#')
        break
      elsif stripped_word.size < 3
        next
      elsif stripped_word.size > 25
        next
      elsif stripped_word =~ /\A\d+\Z/    # number?
        next
      elsif stripped_word =~ /[<>%\${}]/
        next
      else
        update_list << stripped_word.rstrip
      end
    end
    
    update_list.each {|word| @completion_list << word}
    @completion_list << "initialize"
    @completion_list = @completion_list.uniq
  end
  
  def update_pos
    pos = self.index('insert').split('.')
    @current_pos.text = "Ln #{pos[0]}, Col #{(pos[1].to_i+1).to_s}" 
    @parent.overlord.title = @filename unless @filename == "noname"
    @parent.overlord.title = "RubyPad" if @filename == "noname"
    if @parent.overlord.filebrowser
      @parent.overlord.filebrowser.refresh
      @parent.overlord.on_tab_changed 
    end
    
    @current_pos.text
  end
  
  def on_key_backspace
    current_y_pos = self.index('insert').split('.')[1]
    line_text = self.get('insert linestart', 'insert')
    tab_width = @tab_width
    x = tab_width - 1 
    str = "insert-#{x}c"
  
    if line_text =~ /\s{#{tab_width},}$/ && current_y_pos.to_i >= 1
      self.delete(str, 'insert')
    else
      self.delete('insert', str)
    end
  end

  def on_cut
    self.event_generate("<Cut>")
    syntax_highlight_all
  end
  
  def on_copy
    self.event_generate("<Copy>")
    syntax_highlight_all
  end
  
  def on_paste
    self.event_generate("<Paste>")
    syntax_highlight_all
  end
  
  def on_undo
    begin
      self.edit_undo
    rescue
    end
  end
  
  def on_redo
    begin
      self.edit_redo
    rescue
    end
  end
  
  def on_select_all
    self.tag_add('sel', '1.0', 'end-1c')
  end
  
  def on_highlight
    if @highlight
      syntax_unhighlight_all
      @highlight = false
    else
      syntax_highlight_all
      @highlight = true
    end
  end
  
  def on_terminal
    begin
      s = Settings.new
      sys = s.system['system']
      command = s.terminal_commands[sys]
      system(command)
    rescue
      p $!.to_s
    end
  end
  
  
  def on_popup(event)
    menu = TkMenu.new(@parent, :tearoff => false)
    menu.add('command', 'label' => "Undo", 'command' => proc { on_undo })
    menu.add('command', 'label' => "Redo", 'command' => proc { on_redo })
    menu.add_separator
    menu.add('command', 'label' => 'Cut', 'command' => proc { on_cut })
    menu.add('command', 'label' => 'Copy', 'command' => proc { on_copy })
    menu.add('command', 'label' => 'Paste', 'command' => proc { on_paste})
    menu.add_separator
    menu.add('command', 'label' => 'Select All', 'command' => proc { on_select_all})
    menu.add_separator
    menu.add('command', 'label' => "Highlight On / Off", 'command' => proc { on_highlight} )
    menu.add_separator
    menu.add('command', 'label' => 'Open Terminal', 'command' => proc { on_terminal })
    menu.popup(event.x_root, event.y_root, 0)
  end
  
  def goto_line(line)
    line = line.to_s + ".0"
    self.see(line)
    self.mark_set('insert', line + " lineend")
    self.update_pos
    self.set_focus
  end
  
  def mark_modified
    if @modified
      notebook = @parent.parent # -> notebook
      id = notebook.index('current') # integer

      editorframe = notebook.tabs[id]
      tabtxt = File.basename(@filename) + '*'
      notebook.itemconfigure(id, :text => tabtxt)    # works !!
    else
      return
    end
  end
  
  def load_file(filename)
    # return document
    begin
      @document = File.read(filename)
    rescue
      message = Tk.messageBox(
          'type' => 'ok',
          'icon' => 'warning',
          'title' => 'Error',
          'message' => $!.to_s)  
    ensure
      @document
    end
  end
  
  def config_font(size)
    font = TkFont.new(family: "monospace", size: size, weight: "normal")
    @standard_font = font
    @font_size = size
    self.configure('font' => @standard_font)
  end

end # class Rubyeditor
