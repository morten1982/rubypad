class FilesAndFolders
  attr_accessor :directory, :hidden
  
  def initialize(directory = nil, hidden = false)
    if directory
      @directory = directory
    else
      @directory = Dir.pwd + "/"
    end
    @hidden = hidden
  end
  
  def get_all_folders
    folders = []
    e = Dir.entries(@directory)
    e.each do |entry|
      if @hidden
        if File.directory?(@directory + entry)
          folders << entry unless entry == "." 
        end
      else
        if entry.start_with? "." 
          if entry == ".."
            folders << entry
          else
            next
          end
        else
          if File.directory?(@directory + entry)
            folders << entry
          end
        end
      end
    end
    folders.sort      # return list
  end
  
  def get_all_files
    files = []
    e = Dir.entries(@directory)
    e.each do |entry|
      if @hidden
        if File.file?(@directory + entry)
          files << entry
        end
      else
        if entry.start_with? "."
          next
        else
          if File.file?(@directory + entry)
            files << entry
          end
        end
      end
    end
    files.sort
  end
  
  def hidden?
    @hidden
  end

end

if __FILE__ == $0
  faf = FilesAndFolders.new('/home/', false)
  folders = faf.get_all_folders
  files = faf.get_all_files
  puts "hidden = false:"
  p folders
  puts "\n"
  p files
  puts "\n\nhidden = true:"
  hidden_faf = FilesAndFolders.new("/home/", true)
  folders = hidden_faf.get_all_folders
  files = hidden_faf.get_all_files
  p folders
  puts "\n"
  p files
end
