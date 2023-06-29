require 'tk'
require 'tkextlib/tile'

class TerminalFrame < Tk::Tile::Frame
  
  def initialize(parent)
    @parent = parent
    super(parent)
    
    wid = parent.winfo_id
    p wid
    @str = "xterm -into #{wid} -geometry 80x20 -sb"
    x = system(@str)
  end
  
end

def center(root)
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
  root = TkRoot.new {title "Terminal - Test"}
  root.protocol "WM_DELETE_WINDOW", proc { root.destroy }
  
  terminal_frame = TerminalFrame.new(root) do
    pack('padx' => 5, 'pady' => 5, 'expand' => true, 'fill' => 'both')
  end
  
  center(root)
  Tk.mainloop
end


