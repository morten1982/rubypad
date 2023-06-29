require "tk"
require "tkextlib/tile"

class CodeanalyzerFrame < Tk::Tile::TFrame
  attr_accessor :requires, :classes, :functions, :codeanalyzer, :editor,
                :sorted
  attr_reader :refresh, :analyze
  
  def initialize(parent, editor)
    @parent = parent
    @requires = []
    @classes = []
    @functions = []
    @all = []
    @editor = editor
    @sorted = false
    
    super(parent)
    
    build_gui
  end
  
  def build_gui
    y_scrollbar = Tk::Tile::Scrollbar.new(self) {orient 'vertical'}
    x_scrollbar = Tk::Tile::Scrollbar.new(self) {orient 'horizontal'}
    @codeanalyzer = Tk::Tile::Treeview.new(self)
    
    
    y_scrollbar.pack('side' => 'right', 'fill' => 'y')
    @codeanalyzer.pack('side' => 'top', 'fill' => 'both', 'expand' => true)
    
    y_scrollbar['command'] = proc { |*args| @codeanalyzer.yview(*args) }
    @codeanalyzer['yscrollcommand'] = proc{ |*args| y_scrollbar.set(*args) }
    
    @codeanalyzer['show'] = 'tree'     # show just the tree
    
    @codeanalyzer.bind("Double-1", proc {|event| on_double_click(event) } )
    @codeanalyzer.bind("Button-1", proc {|event| on_click(event) } ) 
    @codeanalyzer.bind("Return", proc {|event| on_return(event) } )
    @codeanalyzer.bind("ButtonRelease-3", proc {|event| on_popup(event) } )
  end
  
  def fill_sorted(requires, classes, functions)
    refresh
    @codeanalyzer.tag_configure('r', :foreground => 'gray')
    @codeanalyzer.tag_configure('c', :foreground => 'dodgerblue')
    @codeanalyzer.tag_configure('f', :foreground => 'royalblue')
    
    requires.each do |r|
      text = r.first
      line = r.last
      @codeanalyzer.insert('', 'end', :text => text, :tags => ['r'])
    end
      @codeanalyzer.insert('', 'end', :text => "---", :tags => ['']) if requires.size > 0
    
    classes.each do |c|
      text = c.first
      line = c.last
      @codeanalyzer.insert('', 'end', :text => text, :tags => ['c'])      
    end
      @codeanalyzer.insert('', 'end', :text => "---", :tags => ['']) if classes.size > 0
      
    functions.each do |f|
      text = f.first
      line = f.last
      @codeanalyzer.insert('', 'end', :text => text, :tags => ['f'])
    end
  end
  
  def fill_unsorted(all)
    refresh
    @codeanalyzer.tag_configure('r', :foreground => 'gray')
    @codeanalyzer.tag_configure('c', :foreground => 'dodgerblue')
    @codeanalyzer.tag_configure('f', :foreground => 'royalblue')
    
    @all.each do |a|
      text = a.first
      line = a.last
      
      if text.start_with? "require"
        t = 'r'
      elsif text.start_with? "class"
        t = 'c'
      elsif text.start_with? "def"
        t = 'f'
      end
      @codeanalyzer.insert('', 'end', :text => "---", :tags => ['']) if text.start_with? "class"
      @codeanalyzer.insert('', 'end', :text => text, :tags => [t]) 
      @codeanalyzer.insert('', 'end', :text => "---", :tags => ['']) if text.start_with? "class"
    end
  end
  
  def refresh
    @codeanalyzer.delete(@codeanalyzer.children('')) # delete all
  end
  
  def on_click(event)

  end
  
  def on_double_click(event)
    item = @codeanalyzer.identify(event.x, event.y)
    return unless item
    txt = item.text
    case txt
    when /^require.*/
      @requires.each do |r|
        if r.first == txt
          #p "#{r.first} : #{r.last}"
          @editor.goto_line(r.last.to_i)
        end
      end
    when /^class+\s.*/
      @classes.each do |c|
        if c.first == txt
          @editor.goto_line(c.last.to_i)
        end
      end
    when /^def+\s.*/
      @functions.each do |f|
        if f.first == txt
          @editor.goto_line(f.last.to_i)
        end
      end
    end
  end
  
  def on_return(event)
  end
  
  def on_popup(event)
    menu = TkMenu.new(@parent, :tearoff => false)
    menu.add('command', 'label' => "Show: Sorted / Unsorted", 'command' => proc {|event| on_popup_show(event) })
    menu.popup(event.x_root, event.y_root, 0)
  end
  
  def on_popup_show(event)
    if @sorted
      @sorted = false 
      fill_unsorted(@all)
    else
      @sorted = true
      fill_sorted(@requires, @classes, @functions)
    end
  end
  
  def analyze(codeblock)
    @requires = []
    @classes = []
    @functions = []
    @all = []
    i = 1

    codeblock.each_line do |line|
      x = 1
      if line.lstrip.start_with? "require ", "require_"
        @requires << [line.lstrip.chomp, i]
        @all << [line.lstrip.chomp, i]
      elsif line.lstrip.start_with? "class "
        @classes << [line.lstrip.chomp, i]
        @all << [line.lstrip.chomp, i]
      elsif line.lstrip.start_with? "def "
        add = line.lstrip.chomp
        @functions.each do |a|
          if a.first == add
            add = "#{line.lstrip.chomp}  [#{x+1}]" 
            x += 1
            next
          end
        end
        @functions << [add, i]
        @all << [add, i]
      end
      i += 1
    end
    fill_sorted(@requires, @classes, @functions) if @sorted
    fill_unsorted(@all) unless @sorted
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
  root = TkRoot.new {title "Codeanalyzer - Test"}
  
  codeanalyzer_frame = CodeanalyzerFrame.new(root, nil) do
    pack('padx' => 5, 'pady' => 5, 'expand' => true, 'fill' => 'both')
  end
  code = """require 'tk'
  require 'tkextlib/tile'
  
  class Morten
    attr_accessor :text
    def initialize(parent, x , y)
      @x, @text = = x
      puts 'Hello World'
    end
    
    def to_str
      puts self.to_s
    end
  end
  
  def build
  end
  
  def hello_world(text=@text)
    puts 'Hello World'
  end
  
  def build
  end
  
  class SecondClass < Morten
    def world
    end
  end
  """
  codeanalyzer_frame.analyze(code)
  
  root.tk_call("source", "forest-dark.tcl")
  ::Tk::Tile::Style.theme_use 'forest-dark'
  
  center(root)
  Tk.mainloop
end
