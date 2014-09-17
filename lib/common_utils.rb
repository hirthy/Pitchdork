module CommonUtils
  def generate_album_image_name(artist, album_title)
    encoding_options = {
        :invalid           => :replace,  # Replace invalid byte sequences
        :undef             => :replace,  # Replace anything not defined in ASCII
        :replace           => '',        # Use a blank for those replacements
        :UNIVERSAL_NEWLINE_DECORATOR => true       # Always break lines with \n
    }

    name = "#{artist}_#{album_title}".gsub(/\s/, '_').gsub(/('|"|\/|\\)/, '').downcase
    name.encode(Encoding.find('ASCII'), encoding_options)
  end


end