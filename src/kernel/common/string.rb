class String
  primitive '__splice', 'copyReplaceFrom:to:with:'

  # This is a rubinius helper function
  def splice!(start, count, replacement)
    replace __splice(start+1, start+count, replacement)
  end


  def upto(stop)
    #stop = StringValue(stop)
    unless stop._isString
      if stop._isSymbol 
        raise TypeError , 'upto does not support Symbol arg'
      end
      stop = Type.coerce_to(stop, String, :to_str)
    end
    return self if self > stop

    after_stop = stop.succ
    current = self

    until current == after_stop
      yield current
      #current = StringValue(current.succ)
      current = Type.coerce_to(current.succ, String, :to_str)
      break if current.size > stop.size || current.size == 0
    end

    self
  end

  def self.isalnum(int)
    (48..57).include?(int) ||
      (65..90).include?(int) ||
      (97..122).include?(int)
  end
  # Both forms iterate through <i>self</i>, matching the pattern (which may be a
  # <code>Regexp</code> or a <code>String</code>). For each match, a result is
  # generated and either added to the result array or passed to the block. If
  # the pattern contains no groups, each individual result consists of the
  # matched string, <code>$&</code>.  If the pattern contains groups, each
  # individual result is itself an array containing one entry per group.
  #
  #   a = "cruel world"
  #   a.scan(/\w+/)        #=> ["cruel", "world"]
  #   a.scan(/.../)        #=> ["cru", "el ", "wor"]
  #   a.scan(/(...)/)      #=> [["cru"], ["el "], ["wor"]]
  #   a.scan(/(..)(..)/)   #=> [["cr", "ue"], ["l ", "wo"]]
  #
  # And the block form:
  #
  #   a.scan(/\w+/) {|w| print "<<#{w}>> " }
  #   print "\n"
  #   a.scan(/(.)(.)/) {|x,y| print y, x }
  #   print "\n"
  #
  # <em>produces:</em>
  #
  #   <<cruel>> <<world>>
  #   rceu lowlr

  def scan(pattern)
    self._scan(pattern)
  end

  def scan(pattern, &block)
    self._scan(pattern, &block)
  end
  
  def _scan(pattern)
    # taint = self.tainted? || pattern.tainted? # Maglev, no taint propagation
    pattern = self.__get_pattern(pattern, true)
    index = 0
    last_match = nil
    ret = []

    while match = pattern.match_from(self, index)
      index = match.collapsing? ? match.end(0) + 1 : match.end(0)
      last_match = match
      val = (match.length._equal?(1) ? match[0] : match.captures)
      # val.taint if taint # Maglev, no taint propagation
      ret << val
    end

    last_match.__storeRubyVcGlobal(0x30) # store into caller's $~
    return ret
  end

  def _scan(pattern, &block)
    # second variant gets no bridge methods. can't rely on single
    # implementation with bridge methods when using __storeRubyVcGlobal
    # because number of frames up to caller's frame would vary .
    # taint = self.tainted? || pattern.tainted? # Maglev, no taint propagation
    pattern = self.__get_pattern(pattern, true)
    index = 0
    last_match = nil
    if block_given?
      ret = self
      while match = pattern.match_from(self, index)
        index = match.collapsing? ? match.end(0) + 1 : match.end(0)
        last_match = match
        val = (match.length._equal?(1) ? match[0] : match.captures)
        # val.taint if taint # Maglev, no taint propagation

        last_match.__storeRubyVcGlobal(0x30) # store into caller's $~
        yield(val)
      end
    else
      ret = []
      while match = pattern.match_from(self, index)
        index = match.collapsing? ? match.end(0) + 1 : match.end(0)
        last_match = match
        val = (match.length._equal?(1) ? match[0] : match.captures)
        # val.taint if taint # Maglev, no taint propagation

        ret << val
      end
    end

    last_match.__storeRubyVcGlobal(0x30) # store into caller's $~
    return ret
  end

end
