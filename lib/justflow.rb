require 'open-uri'
require 'nokogiri'
require 'net/http'
require 'colorize'

module JustFlow
  module_function

  def convert(url)
    puts "Converting".yellow + " #{url}..."
    @url = url
    url_parsed = URI.parse(url)
    url_parsed2 = url_parsed.host.to_s + url_parsed.path.to_s + url_parsed.query.to_s
    target_dir = url_parsed2.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')
    ensure_mkdir(target_dir)
    Dir.chdir(target_dir)
    @doc = Nokogiri::HTML(open(url))

    get_scripts()
    get_css()
    get_images()

    File.open('index.html', 'wb') { |file|
      file.write(@doc)
    }
    puts "We done.".green
  end

  def is_img?(extension)
    img_exts = ['.png', '.jpg', '.jpeg', '.gif', '.svg', '.tif', '.tiff']
    img_exts.include?(extension.downcase)
  end

  def is_font?(extension)
    return !is_img?(extension)
  end

  def fix_uri(url, uri)
    uri = uri.strip
    if uri.start_with?('//')
      uri = 'http:' + uri
    else # relative or absolute
      begin
        uri = URI.join(url, uri).to_s
      rescue Exception => ex
        puts "x".red + " Will try to download anyway. #{ex}"
      end
    end
    return uri
  end

  def valid_uri_scheme?(uri)
    uri.start_with?('http') || uri.start_with?('https')
  end

  def get_contents(uri)
    uri_parsed = URI.parse(uri)
    Net::HTTP.get_response(uri_parsed)
  end

  def ensure_mkdir(dirname)
    if !File.directory?(dirname)
      Dir.mkdir dirname
    end
  end

  def save_contents(resp, save_path)
    if File.file? save_path
      extension = File.extname(save_path)
      basename = File.basename(save_path)
      filename = File.basename(save_path, extension)
      if (!is_img?(extension))
        save_path = save_path.gsub(filename, filename + "_" + Time.now.to_i.to_s)
      end
    end
    File.open(save_path, 'wb') { |file|
      file.write(resp.body)
    }
    return save_path
  end

  def remove_args(url)
    url[/[^\?]+/]
  end

  def download_resource(selector, source_attr, out_path)
    resources = @doc.search(selector)
    resources.each { |resource|
      resource_uri = resource[source_attr]

      begin
        resource_uri = fix_uri(@url, resource_uri)
      rescue
        puts "URI is funky. Going for it anyway... #{resource_uri}".red
      end

      save_path = File.join(out_path, File.basename(resource_uri))
      save_path = remove_args(save_path)

      begin
        puts "✓".green + " Downloading ... " + resource_uri
        resp = get_contents(resource_uri)
        ensure_mkdir(out_path)
        save_path = save_contents(resp, save_path)
        resource[source_attr] = save_path
      rescue Exception => ex
        puts "✗".red + " FAIL. Couldn't do it: #{ex}"
      end

    }
  end

  def process_css_urls(css_source, original_css_url)
    url_regex = /url\(['"]?(.*?)['"]?\)/i

    if original_css_url.start_with?('//')
      original_css_url = 'http:' + original_css_url
    elsif original_css_url.start_with?('.') || original_css_url.start_with?('/')
      original_css_url = fix_uri(@url, original_css_url)
    end

    puts ">".yellow + " Parsing css ... #{original_css_url}"

    css_source = css_source.gsub(url_regex) {
      original_item_url = $1
      absolute_item_url = fix_uri(original_css_url, original_item_url)
      original_item_url = remove_args(original_item_url)

      extension = File.extname(original_item_url)
      basename  = File.basename(original_item_url)

      out_dir = is_img?(extension) ? 'img' : 'fonts'
      ensure_mkdir(out_dir)
      out_path = File.join(out_dir, basename)

      begin
        resp = get_contents(absolute_item_url)
        ensure_mkdir(out_dir)
        save_contents(resp, out_path)
      rescue Exception => ex
        puts "Failed. Couldnt download from CSS: #{ex}".red
      end

      "url('#{File.join('..', out_path)}')"
    }

    return css_source
  end

  def get_images()
    download_resource('img[src]', 'src', 'img')
  end

  def get_scripts()
    download_resource('script[src]', 'src', 'js')
  end

  def get_css()
    cloned_doc = @doc.clone
    orig_link_tags = cloned_doc.search('link[rel=stylesheet]')
    download_resource('link[rel=stylesheet]', 'href', 'css')
    link_tags = @doc.search('link[rel=stylesheet]')
    link_tags.each_with_index { |link, idx|

      original_css_path = orig_link_tags[idx]['href']
      local_css_path = link['href']

      if File.exists?(local_css_path)
        src = ""
        File.open(local_css_path, 'r') { |file|
          src = process_css_urls(file.read(), original_css_path)
        }
        File.open(local_css_path, 'w') { |file|
          file.write(src)
        }
      end
    }
  end
end