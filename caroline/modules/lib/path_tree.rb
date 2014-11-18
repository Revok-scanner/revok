class PathTree
  attr_reader :path_tree

  def initialize
    @path_tree = ["/"]
  end

  def add_path (a_path)
    path = a_path.to_s.strip
    path = path.split('/')
    path.delete_if {|item| item == ""}

    sub_path = @path_tree

    path.length.times {|i|
      if sub_path[1] != nil
        find = false
        sub_path[1].each{|item|
          if item[0] == path[i]
            sub_path = item
            find = true
            break
          end
        }
        if !find
          sub_path[1] << ["#{path[i]}"]
          sub_path = sub_path[1].last
        end
      else
        sub_path << []
        sub_path[1] << ["#{path[i]}"]
        sub_path = sub_path[1].last
      end
    }
  end

  def each(&block)
    sub_node = @path_tree
    path = ""
    if block == nil
      raise LocalJumpError, "no block given"
      return
    end
    traveral(sub_node, path, block)
  end

  private
  def traveral(a_node, path, block)
    path += a_node[0]
    path += "/" if !a_node[0].include?(".")
    block.call path.gsub("//", "/")
    if (a_node[1] != nil)
      a_node[1].each {|item|
      traveral(item, path, block)
    }
    else
      return path
    end
  end
end
