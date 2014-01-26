class String
  def read(n)
    self.slice!(0...n)
  end
  def readh(n)
    self.slice!(0...n).bytes {|ss| print "%02x "%ss}
  end
end
class File
  def readh(n)
    self.read(n).bytes {|ss| Kernel.print "%02x "%ss}
  end
end

# Based on file format analysis
# Refer from http://www.m2osw.com/swf_alexref
class Hsalf
  @f
  def initialize(filename, offset=0, size=0)
    @f = File.open(filename, "rb")
    @f.seek(offset, IO::SEEK_SET)
    size = @f.size if size == 0
    #@b = f.read(size-offset)
    #@f.close
  end
  
  def readstr(s)
    i = s.index("\x00")
    puts "Warning: no null ended" if i.nil?
    s.read(i+1)[0..-2]
  end

  def readdata(d)
    data = []
    until d.length <=0 do
      type = d.read(1).ord
      case type
      when 0 # string
        data += [readstr(d)]
      when 5 # 1byte
        data += d.read(1).unpack('C')
      when 6 # float
        data += d.read(8).unpack('D')
      when 7 # 4byte
        data += d.read(4).unpack('L<')
      else
        puts "Unknown Data Type #{type}(#{type.to_s(16)})"
      end
    end
    return data
  end
  
  def disas(len)
    ori = @f.tell
    while @f.tell < ori+len
      p decode(1)[0]
    end
  end
  
  def debug(argv)
    s = [] # stack
    v = {} # variable
    f = {} # function list
    dict = [] # dictionary
    loop do
      a,i,d = decode(0)
      if i[0].to_i == 2
        o1 = s.pop
        o2 = s.pop
        case i[1]
        when '+' then s.push(o1+o2)
        when '-' then s.push(o1-o2)
        when '*' then s.push(o1*o2)
        when '%' then s.push(o1%o2)
        when '=' then s.push((o1==o2)?1:0)
        when ']' then v[o2]=o1
        when 'c'
          ra = @f.tell
          @f.seek(f[o1], IO::SEEK_SET)
          argv = s.pop(o2).reverse
          puts "call"
          s.push(debug(argv))
          @f.seek(ra, IO::SEEK_SET)
        end
      elsif i[0].to_i == 1
        o1 = s.pop
        case i[1]
        when '~' then s.push(~o1)
        when '[' then s.push(v[o1])
        when 'r' then return o1
        end
      elsif i[0] == "e" # end
        break
      elsif i[0] == "d" # dictionary
        dict += d
      elsif i[0] == "b" # branch
        if (i[1]=="a")or(i[1]=="t" && s.pop!=0)
          d = d-1 if d<0
          @f.seek(d, IO::SEEK_CUR)
        end
      elsif i[0] == "p" # push
        s+=d
      elsif i[0] == "f" # function declare
        f[d[0]] = d[1] 
      else
        p a
        exit
      end
      p "#{a}:#{s}"
    end # loop end
  end
  
  def decode(r)
    #a:action i:intermidiate_language d:data
    id = @f.readh(1).ord
    case id # Action identifier
    when 0x0 then a="end";i="e"
    when 0xa then a="add";i="2+" # pop + pop => push
    when 0xb then a="subtract";i="2-" # pop - pop -> push
    when 0xc then a="multiply";i="2*" # pop * pop => push
    when 0xe then a="equal";i="2=" # pop == pop => push
    when 0x12 then a="not";i="1~" # ~pop => push
    when 0x1c then a="getvariable";i="1[" # *pop => push
    when 0x1d then a="setvariable";i="2]" # pop => *pop
    when 0x3c then a="setlocalvariable";i="2]" # pop => *pop
    when 0x3d then a="call function";i="2c" # pop(pop(argc): pops(argv)) => push
    when 0x3e then a="return";i="1r" # return pop | push(caller)
    when 0x3f then a="modulo";i="2%" # pop % pop => push
    when 0x47 then a="add(type)";i="2+" # pop + pop => push
    when 0x88 # declare dictionary
      size = @f.readh(2).unpack('S<')[0]
      chk = @f.readh(size)
      d = []
      until chk.length <= 0 do
        d += [readstr(chk)]
      end
      a="dict #{d}";i="d"
    when 0x96 # push data
      size = @f.readh(2).unpack('S<')[0]
      d = readdata(@f.readh(size))
      a = "push #{d}"
      i = "p"
    when 0x99 # branch always
      size = @f.readh(2).unpack('S<')[0]
      puts "warning: branch data size != 2" if size != 2
      d = @f.readh(2).unpack('s<')[0]
      a = "branch always:#{d}(#{d.to_s(16)})"
      i = "ba"
    when 0x9b  # declare function
      size = @f.readh(2).unpack('S<')[0]
      chk = @f.readh(size)
      fun_nm = readstr(chk)
      argc = chk.read(2).unpack('S<')[0]
      argv = []
      argc.times{argv+=[readstr(chk)]}
      fun_len = chk.read(2).unpack('S<')[0]
      a = "Func(#{fun_nm}), argc:#{argc}, fun_len:#{fun_len}"
      i = "f"
      d = [fun_nm,@f.tell]
      if r!=0
        p "Func(#{fun_nm}), argc:#{argc}, fun_len:#{fun_len} <<"
        disas(fun_len)
      else
        @f.seek(fun_len, IO::SEEK_CUR)
      end
    when 0x9d # branch If True / if(pop)
      size = @f.readh(2).unpack('S<')[0]
      puts "warning: branch data size != 2" if size != 2
      d = @f.readh(2).unpack('s<')[0]
      a = "branch if True off:#{d}(#{d.to_s(16)})"
      i = "bt"
    else
      puts "Unknown Action ID #{id}(#{id.to_s(16)})"
    end
    return a,i,d
  end #end method
end #end class
