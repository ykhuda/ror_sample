module Admin::ApplicationHelper

  def anonymous_admin_form_path( object )
    object.new_record? ? anonymous_admin_plural_path( object ) : anonymous_admin_path( object )
  end
  
  def anonymous_admin_path( object )
    args, method = case object.class.name
      when /^Versioned/
        [object.resource_proxy, "admin_" + object.class.name.underscore.gsub( /^versioned_/, '' ) + "_path"]
      when /BlogPost/
        [[object.blog, object], "admin_blog_blog_post_path"]        
      else
        [[object], "admin_" + object.class.name.underscore + "_path"]
    end
    
    begin 
      self.send(method.to_sym, *args)
    rescue NoMethodError
      self.send(method.gsub(/^admin_/, 'admin_press_'), *args)
    end
  end
  
  def anonymous_admin_plural_path( object )
    if object.class.name.match( /Versioned/ )
      self.send( ( "admin_" + object.class.name.underscore.pluralize.gsub( /^versioned_/, '' ) + "_path" ).to_sym )
    else
      self.send( ( "admin_" + object.class.name.underscore.pluralize + "_path" ).to_sym )
    end
  end
  
  # Works on any object that has a stamp.
  def format_stamp_for( object )
    stamp = object.last_stamp
    if stamp
      format_stamp( stamp )
    else
      "system import (" + object.created_at.strftime("%m/%d/%y - %I:%M %p") + ")"
    end
  end

  # Works on any stamp.
  def format_stamp( stamp )
    ( stamp.user.nil? ? 'anon' : stamp.user.login ) + " (" + stamp.created_at.strftime("%m/%d/%y - %I:%M %p") + ")"
  end

  def adjust_embedded_video_dims_and_insert( code, id )
    html = REXML::Document.new(code)
    if object = html.elements['//object']
      embed = object.elements['embed']
      #get width and height
      width = object.attribute('width').value.to_i
      height = object.attribute('height').value.to_i
      #add new attributes
      new_width = 367
      new_height = (new_width*height)/width
            
      object.add_attributes({'width' => "#{new_width}", 'height' => "#{new_height}"})
      embed.add_attributes({'width' => "#{new_width}", 'height' => "#{new_height}"}) if embed
      param = REXML::Element.new('param')
      param.add_attributes('value' => 'transparent', 'name' => 'wmode')
      object.add(param)
            
      <<-end
        <script type="text/javascript" charset="utf-8">
          //<![CDATA[
            insertHTML('#{id}',"#{object.to_s.gsub(/"/, '\\"').gsub(/\n/, "\\\n")}");
          //]]>
        </script>
      end
    else 
      '<!-- INVALID EMBEDDED VIDEO -->'
    end
  end
  
  def new_video_object(width, height, as, id)
    html = <<-end_html
      <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="#{width}" height="#{height}" id="Video16878177890">
        <param name="movie" value="http://premium_drop_v3.swf?b=1&widgetHost=community.com&mediaType=VIDEO&mediaId=#{id}&as=#{as}" type="application/x-shockwave-flash"/>
        <param name="quality" value="high" />
        <param name="allowScriptAccess" value="always" />
        <param name="allowFullScreen" value="true" />
        <param name="wmode" value="transparent" />
        <embed src="http://premium_drop_v3.swf?b=1&widgetHost=community.com&mediaType=VIDEO&mediaId=#{id}&as=#{as}" quality="best" width="#{width}" height="#{height}" allowfullscreen="true" allowScriptAccess="always">  
        </embed>
      </object>
    end_html
    
    REXML::Document.new(html)
  end
  
end

