# Copy of some of rubinius file.rb
class File
  DOSISH = false # Gemstone

  #--
  # File.fnmatch and helpers. This is a port of JRuby's code
  #++

  def self.dirsep?(char)
    if DOSISH then
      char == ?\\ || char == ?/
    else
      char == ?/
    end
  end

  def self.next_path(str, start, strend)
    start += 1 while start < strend and !dirsep? str[start]
    start
  end

  def self.range(pattern, pstart, pend, test, flags)
    ok = false
    escape = (flags & FNM_NOESCAPE)._equal?(0)
    case_sensitive = (flags & FNM_CASEFOLD)._equal?(0)
    neg = pattern[pstart] == ?! || pattern[pstart] == ?^

    pstart += 1 if neg

    while pattern[pstart] != ?] do
      pstart += 1 if escape && pattern[pstart] == ?\\
      return -1 if pstart >= pend
      cstart = cend = pattern[pstart]
      pstart += 1

      if pattern[pstart] == ?- && pattern[pstart+1] != ?]
        pstart += 1
        pstart += 1 if escape && pattern[pstart] == ?\\
        return -1 if pstart >= pend
        cend = pattern[pstart]
        pstart += 1
      end

      if case_sensitive
        ok = true if cstart <= test && test <= cend
      else
        ok = true if cstart.tolower <= test.tolower &&
          test.tolower <= cend.tolower
      end
    end

    ok == neg ? -1 : pstart + 1
  end

  def self.name_match(pattern, str, flags, patstart, patend, strstart, strend)
    index = strstart
    pstart = patstart
    escape   = (flags & FNM_NOESCAPE)._equal?(0)
    pathname = !( (flags & FNM_PATHNAME)._equal?(0))
    period   = (flags & FNM_DOTMATCH)._equal?(0)
    nocase   = !( (flags & FNM_CASEFOLD)._equal?(0))

    while pstart < patend do
      char = pattern[pstart]
      pstart += 1
      case char
      when ??
        if index >= strend || (pathname && dirsep?(str[index])) ||
           (period && str[index] == ?. &&
            (index == 0 || (pathname && dirsep?(str[index-1]))))
          return false
        end

        index += 1

      when ?*
        while pstart < patend
          char = pattern[pstart]
          pstart += 1
          break unless char == ?*
        end

        if index < strend &&
           (period && str[index] == ?. &&
            (index == 0 || (pathname && dirsep?(str[index-1]))))
          return false
        end

        if pstart > patend || (pstart == patend && char == ?*)
          return !(pathname && next_path(str, index, strend) < strend)
        elsif pathname && dirsep?(char)
          index = next_path(str, index, strend)
          return false unless index < strend
          index += 1
        else
          test = if escape && char == ?\\ && pstart < patend then
                   pattern[pstart]
                 else
                   char
                 end.tolower

          pstart -= 1

          while index < strend do
            if (char == ?? || char == ?[ || str[index].tolower == test) &&
               name_match(pattern, str, flags | FNM_DOTMATCH, pstart, patend,
                          index, strend)
              return true
            elsif pathname && dirsep?(str[index])
              break
            end

            index += 1
          end

          return false
        end

      when ?[
        if index >= strend ||
           (pathname && dirsep?(str[index]) ||
            (period && str[index] == ?. &&
             (index == 0 ||
              (pathname && dirsep?(str[index-1])))))
          return false
        end

        pstart = range pattern, pstart, patend, str[index], flags

        return false if pstart == -1

        index += 1
      else
        if char == ?\\
          if escape &&
             (!DOSISH || (pstart < patend && "*?[]\\".index(pattern[pstart])))
            char = pstart >= patend ? ?\\ : pattern[pstart]
            pstart += 1
          end
        end

        return false if index >= strend

        if DOSISH && (pathname && isdirsep?(char) && dirsep?(str[index]))
          # TODO: invert this boolean expression
        else
          if nocase
            return false if char.tolower != str[index].tolower
          else
            return false if char != str[index]
          end
        end

        index += 1
      end
    end

    index >= strend ? true : false
  end

  ##
  # Returns true if path matches against pattern The pattern
  # is not a regular expression; instead it follows rules
  # similar to shell filename globbing. It may contain the
  # following metacharacters:
  #
  # *:  Matches any file. Can be restricted by other values in the glob. * will match all files; c* will match all files beginning with c; *c will match all files ending with c; and c will match all files that have c in them (including at the beginning or end). Equivalent to / .* /x in regexp.
  # **: Matches directories recursively or files expansively.
  # ?:  Matches any one character. Equivalent to /.{1}/ in regexp.
  # [set]:  Matches any one character in set. Behaves exactly like character sets in Regexp, including set negation ([^a-z]).
  # <code></code>:  Escapes the next metacharacter.
  # flags is a bitwise OR of the FNM_xxx parameters. The same glob pattern and flags are used by Dir::glob.
  #
  #  File.fnmatch('cat',       'cat')        #=> true  : match entire string
  #  File.fnmatch('cat',       'category')   #=> false : only match partial string
  #  File.fnmatch('c{at,ub}s', 'cats')       #=> false : { } isn't supported
  #
  #  File.fnmatch('c?t',     'cat')          #=> true  : '?' match only 1 character
  #  File.fnmatch('c??t',    'cat')          #=> false : ditto
  #  File.fnmatch('c*',      'cats')         #=> true  : '*' match 0 or more characters
  #  File.fnmatch('c*t',     'c/a/b/t')      #=> true  : ditto
  #  File.fnmatch('ca[a-z]', 'cat')          #=> true  : inclusive bracket expression
  #  File.fnmatch('ca[^t]',  'cat')          #=> false : exclusive bracket expression ('^' or '!')
  #
  #  File.fnmatch('cat', 'CAT')                     #=> false : case sensitive
  #  File.fnmatch('cat', 'CAT', File::FNM_CASEFOLD) #=> true  : case insensitive
  #
  #  File.fnmatch('?',   '/', File::FNM_PATHNAME)  #=> false : wildcard doesn't match '/' on FNM_PATHNAME
  #  File.fnmatch('*',   '/', File::FNM_PATHNAME)  #=> false : ditto
  #  File.fnmatch('[/]', '/', File::FNM_PATHNAME)  #=> false : ditto
  #
  #  File.fnmatch('\?',   '?')                       #=> true  : escaped wildcard becomes ordinary
  #  File.fnmatch('\a',   'a')                       #=> true  : escaped ordinary remains ordinary
  #  File.fnmatch('\a',   '\a', File::FNM_NOESCAPE)  #=> true  : FNM_NOESACPE makes '\' ordinary
  #  File.fnmatch('[\?]', '?')                       #=> true  : can escape inside bracket expression
  #
  #  File.fnmatch('*',   '.profile')                      #=> false : wildcard doesn't match leading
  #  File.fnmatch('*',   '.profile', File::FNM_DOTMATCH)  #=> true    period by default.
  #  File.fnmatch('.*',  '.profile')                      #=> true
  #
  #  rbfiles = '**' '/' '*.rb' # you don't have to do like this. just write in single string.
  #  File.fnmatch(rbfiles, 'main.rb')                    #=> false
  #  File.fnmatch(rbfiles, './main.rb')                  #=> false
  #  File.fnmatch(rbfiles, 'lib/song.rb')                #=> true
  #  File.fnmatch('**.rb', 'main.rb')                    #=> true
  #  File.fnmatch('**.rb', './main.rb')                  #=> false
  #  File.fnmatch('**.rb', 'lib/song.rb')                #=> true
  #  File.fnmatch('*',           'dave/.profile')                      #=> true
  #
  #  pattern = '*' '/' '*'
  #  File.fnmatch(pattern, 'dave/.profile', File::FNM_PATHNAME)  #=> false
  #  File.fnmatch(pattern, 'dave/.profile', File::FNM_PATHNAME | File::FNM_DOTMATCH) #=> true
  #
  #  pattern = '**' '/' 'foo'
  #  File.fnmatch(pattern, 'a/b/c/foo', File::FNM_PATHNAME)     #=> true
  #  File.fnmatch(pattern, '/a/b/c/foo', File::FNM_PATHNAME)    #=> true
  #  File.fnmatch(pattern, 'c:/a/b/c/foo', File::FNM_PATHNAME)  #=> true
  #  File.fnmatch(pattern, 'a/.b/c/foo', File::FNM_PATHNAME)    #=> false
  #  File.fnmatch(pattern, 'a/.b/c/foo', File::FNM_PATHNAME | File::FNM_DOTMATCH) #=> true
  def self.fnmatch(pattern, path, flags=0)
    pattern = Type.coerce_to(pattern, String, :to_str).dup
    path    = Type.coerce_to(path, String, :to_str).dup
    flags   = Type.coerce_to(flags, Fixnum, :to_int) unless Fixnum === flags

    name_match(pattern, path, flags, 0, pattern.size, 0, path.size)
  end

  ##
  # Returns a new string formed by joining the strings using File::SEPARATOR.
  #
  #  File.join("usr", "mail", "gumby")   #=> "usr/mail/gumby"
  def self.join(*args)
    args.map! { |o|
      unless o._isString || o._isArray 
        o = o.to_str 
      end
      o
    } rescue raise TypeError

    # let join/split deal with all the recursive array complexities
    # one small hack is to replace URI header with \0 and swap back later
    result = args.join(SEPARATOR).gsub(/\:\//, "\0").split(/#{SEPARATOR}+/o)   
 						     # ^ broken here for args of ['','']
    result << '' if args.empty? || args.last.empty? || args.last[-1] == SEPARATOR[0]
    result.join(SEPARATOR).gsub(/\0/, ':/')
  end

end
