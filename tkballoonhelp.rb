# frozen_string_literal: false
#
# tkballoonhelp.rb : simple balloon help widget
#                       by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# Add a balloon help to a widget.
# This widget has only poor features. If you need more useful features,
# please try to use the Tix extension of Tcl/Tk under Ruby/Tk.
#
# The interval time to display a balloon help is defined 'interval' option
# (default is 750ms).
#
require 'tk'

module Tk
  module RbWidget
    class BalloonHelp<TkLabel
    end
  end
end
class Tk::RbWidget::BalloonHelp<TkLabel
  DEFAULT_FOREGROUND = 'black'
  DEFAULT_BACKGROUND = 'bisque' #'white'
  DEFAULT_INTERVAL   = 750

  def _balloon_binding(interval)
    @timer = TkAfter.new(interval, 1, proc{show})
    def @timer.interval(val)
      @sleep_time = val
    end
    @bindtag = TkBindTag.new
    @bindtag.bind('Enter',  proc{@timer.start})
    @bindtag.bind('Motion', proc{@timer.restart; erase})
    @bindtag.bind('Any-ButtonPress', proc{@timer.restart; erase})
    @bindtag.bind('Leave',  proc{@timer.stop; erase})
    tags = @parent.bindtags
    idx = tags.index(@parent)
    unless idx
      ppath = TkComm.window(@parent.path)
      idx = tags.index(ppath) || 0
    end
    tags[idx,0] = @bindtag
    @parent.bindtags(tags)
  end
  private :_balloon_binding

  def initialize(parent=nil, keys={})
    @parent = parent || Tk.root

    @frame = TkToplevel.new(@parent)
    @frame.withdraw
    @frame.overrideredirect(true)
    @frame.transient(TkWinfo.toplevel(@parent))
    @epath = @frame.path

    if keys
      keys = _symbolkey2str(keys)
    else
      keys = {}
    end

    @command = keys.delete('command')

    @interval = keys.delete('interval'){DEFAULT_INTERVAL}
    _balloon_binding(@interval)

    @label = TkLabel.new(@frame,
                         'foreground'=>DEFAULT_FOREGROUND,
                         'background'=>DEFAULT_BACKGROUND).pack
    @label.configure(_symbolkey2str(keys)) unless keys.empty?
    @path = @label
  end

  def epath
    @epath
  end

  def interval(val)
    if val
      @timer.interval(val)
    else
      @interval
    end
  end

  def command(cmd = nil, &block)
    @command = cmd || block
    self
  end

  def show
    x = TkWinfo.pointerx(@parent)
    y = TkWinfo.pointery(@parent)
    @frame.geometry("+#{x+1}+#{y+1}")

    if @command
      case @command.arity
      when 0
        @command.call
      when 2
        @command.call(x - TkWinfo.rootx(@parent), y - TkWinfo.rooty(@parent))
      when 3
        @command.call(x - TkWinfo.rootx(@parent), y - TkWinfo.rooty(@parent),
                      self)
      else
        @command.call(x - TkWinfo.rootx(@parent), y - TkWinfo.rooty(@parent),
                      self, @parent)
      end
    end

    @frame.deiconify
    @frame.raise

    begin
      @org_cursor = @parent.cget('cursor')
    rescue
      @org_cursor = @parent['cursor']
    end
    begin
      @parent.configure('cursor', 'crosshair')
    rescue
      @parent.cursor('crosshair')
    end
  end

  def erase
    begin
      @parent.configure('cursor', @org_cursor)
    rescue
      @parent.cursor(@org_cursor)
    end
    @frame.withdraw
  end

  def destroy
    @frame.destroy
  end
end
