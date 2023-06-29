require "tk"
require "tkextlib/tile"
require_relative 'codeeditor'
require_relative 'dialogs'

class EditorFrame < Tk::Tile::Frame
  attr_accessor :codecompletion, :editor, :current_pos, :parent, :theme
  attr_reader :overlord
  
  def initialize(parent, theme, overlord)
    @parent = parent
    @theme = theme
    @overlord = overlord
    super(parent)
    
    build_gui
  end
  
  def build_gui
    ##
    # XScrollbar / YScrollbar / editor / Codecompletion-Label
    # on: EditorFrame
    ##
    @font_size = 12
    edit_y_scrollbar = Tk::Tile::Scrollbar.new(self) {orient 'vertical'}
    edit_x_scrollbar = Tk::Tile::Scrollbar.new(self) {orient 'horizontal'}
    
    edit_y_scrollbar.pack('side' => 'right', 'fill' => 'y')
    edit_x_scrollbar.pack('side' => 'bottom', 'fill' => 'x')
    
    @font = TkFont.new(family: "Mono", size: @font_size, weight: "normal")
    
    @codecompletion = Tk::Tile::Label.new(self)   # -> syntaxhighlighting
    @current_pos = Tk::Tile::Label.new(self) # -> line / col 
    
    @editor = Codeeditor.new(self, theme) do
      undo "true"
      autoseparators "true"
      wrap "none"
    end
    
    @editor.pack('side' => 'top', 'fill' => 'both', 'expand' => true)
    
    @codecompletion.text = "---"
    @codecompletion['anchor'] = 'e'
    
    @current_pos.text = @editor.update_pos
    @current_pos['justify'] = 'right'
    

    @current_pos.pack('side' => 'bottom')
    @codecompletion.pack('side' => 'bottom')
    
    @codecompletion.font = @font
    @editor.font = @font
    
    edit_y_scrollbar['command'] = proc { |*args| @editor.yview(*args) }
    edit_x_scrollbar['command'] = proc { |*args| @editor.xview(*args) }
    @editor['yscrollcommand'] = proc{ |*args| edit_y_scrollbar.set(*args) }
    @editor['xscrollcommand'] = proc{ |*args| edit_x_scrollbar.set(*args) }
    
    @current_pos.bind("Double-1", proc { on_double_click_pos(@editor) } )
  
  end
  
  def on_double_click_pos(editor)
    dialog = GotoLineDialog.new(editor, editor)
  end
  
  
  def delete
    begin
      @editor.delete("sel.first", "sel.last")
    rescue
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
  root = TkRoot.new {title "Codeeditor - Test"}
  
  editorFrame = EditorFrame.new(root) do
    pack('padx' => 5, 'pady' => 5, 'expand' => true, 'fill' => 'both')
  end
  
  root.tk_call("source", "forest-dark.tcl")
  ::Tk::Tile::Style.theme_use 'forest-dark'
  
  editorFrame.editor.make_completion_list  # test
  editorFrame.editor.focus
  
  center(root)
  Tk.mainloop
end
