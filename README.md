# rubypad
- > Ruby Code Editor
- > Ruby IDE 
- > RubyTk Codeeditor

![alt text](https://github.com/morten1982/rubypad/blob/main/images/rubypad-run.png)

# Description
- > Codeeditor
- > light IDE made with ruby for ruby development :) 
- > using RubyTk

- > RubyPad is using the "forest ttk theme" which you can find on github :)

https://github.com/rdbende/Forest-ttk-theme

# Features
- > Using RubyTk as GUI
- > Autocomplete, indent, syntax highlighting
- > Sourcecode analyzing
- > Run ruby scripts in console or show html in your favorite browser 
- > Open terminal and irb separated
- > Advanced search dialog 
- > Filebrowser included (delete, rename ... files and folders)

- > should be cross platform  -> but you need to implement path activities
    to gsub '\\' with '/' ... so actually it is Linux (Mac?) only

# Requirements
tk

# setup on debian
sudo apt install tk-dev

sudo gem install tk -- --with-tcltkversion=8.6 \
--with-tcl-lib=/usr/lib/x86_64-linux-gnu \
--with-tk-lib=/usr/lib/x86_64-linux-gnu \
--with-tcl-include=/usr/include/tcl8.6 \
--with-tk-include=/usr/include/tcl8.6 \
--enable-pthread


# Install
RubyPad is using Tcl/Tk 

- 1.) Install Tcl/Tk on your OS
 
- 2.) gem install tk

or

      bundle install (via Gemfile)
 
# Run
'ruby rubypad.rb'

# License
MIT -> feel free to fork it => make it better if you want to do this :)

# to DO
-> improve the comments highlighting / syntax highlighting in general
-> visualize brace matching
