class String
  def read(n)
    self.slice!(0...n)
  end
  def readh(n) # for debugging
    self.slice!(0...n).bytes {|ss| print "%02x "%ss}
  end
end
class File
  def readh(n) # for debugging
    self.read(n).bytes {|ss| Kernel.print "%02x "%ss}
  end
end

# Based on file format analysis
# Refer from http://www.m2osw.com/swf_alexref
class Hsalf
  private
  @f
  public
  def initialize(filename, offset=0, size=0)
    @f = File.open(filename, "rb")
    @f.seek(offset, IO::SEEK_SET)
    size = @f.size if size == 0
    #@b = f.read(size-offset)
    #@f.close
  end
  
  def disas(len=@f.size)
    ori = @f.tell
    while @f.tell < ori+len
      puts decode()[0]
    end
  end
  
  def debug(argv)
    # finding how does the scope of these lists
    s = [] # stack
    v = {} # variable
    f = {} # function list
    dict = [] # dictionary
    loop do
      a,i,d = decode(dict)
      if i[0].to_i == 2
        o1 = s.pop
        o2 = s.pop
        case i[1]
        when '+' then s.push(o2+o1)
        when '-' then s.push(o2-o1)
        when '*' then s.push(o2*o1)
        when '&' then s.push(o2&o1)
        when '%' then s.push(o2%o1)
        when '=' then s.push((o2==o1)? true:false)
        when ']' then v[o2]=o1 # setvariable
        when 'c'
          ra = @f.tell
          @f.seek(f[o1], IO::SEEK_SET)
          argv = s.pop(o2).reverse
          puts "call"
          s.push(debug(argv))
          puts "return"
          @f.seek(ra, IO::SEEK_SET)
        end
      elsif i[0].to_i == 1
        o1 = s.pop
        case i[1]
        when '~' then s.push(not(o1))
        when '[' then s.push(v[o1]) # getvariable
        when 'r' then return o1
        end
      elsif i[0] == "e" # end
        break
      elsif i[0] == "d" # dictionary
        dict += d
      elsif i[0] == "b" # branch
        if (i[1]=="a")or(i[1]=="t" && s.pop==true)
          d = d-1 if d<0
          @f.seek(d, IO::SEEK_CUR)
        end
      elsif i[0] == "p" # push
        s+=d
      elsif i[0] == "f" # function declare
        f[d[0]] = d[1] 
      else
        puts "Unknown il #{a}->#{i}"
        exit
      end
      puts "#{a}:#{s}"
    end # loop end
  end
  
  def readstr(s) # read until null end
    i = s.index("\x00")
    puts "Warning: no null ended" if i.nil?
    s.read(i+1)[0..-2]
  end
  def readdata(d, dict) # for push
    data = []
    until d.length <=0 do
      type = d.read(1).ord
      case type
      when 0 # string
        data += [readstr(d)]
      when 1 # float
        data += d.read(8).unpack('F')
      when 2 # NULL
        puts "[warning] readdata NULL: Not implemented"
        data += [nil]
      when 3 # undefined
        puts "[warning] readdata undefined: Not implemented"
        data += [nil]
      when 4 # register
        puts "[warning] readdata register: Not implemented"
        data += d.read(1).unpack('C')
      when 5 # 1byte bool
        data += d.read(1).unpack('C')
        data.map! {|d| d/d}
      when 6 # double
        data += d.read(8).unpack('D')
      when 7 # integer
        data += d.read(4).unpack('L<')
      when 8 # dictionary
        ref = d.read(1).unpack('C')[0]
        data += [dict.nil?? "dict[#{ref}]" : dict[ref]]
      when 9 # large dictionary
        ref = d.read(2).unpack('S')[0]
        data += [dict.nil?? "dict[#{ref}]" : dict[ref]]
      else
        puts "Unknown Data Type #{type}(#{type.to_s(16)})"
      end
    end
    return data
  end
  
  def decode(dict=nil)
    #a:action i:il(intermidiate language) d:data
    #size:action length #chk:action structure
    print "[#{@f.tell.to_s(16)}] "
    id = @f.readh(1).ord
    case id # Action identifier
    when 0x0 then a="end";i="e"
    when 0x4
      puts "Not implemented #{id}(next frame)";exit
    when 0x5
      puts "Not implemented #{id}(previous frame)";exit
    when 0x6
      puts "Not implemented #{id}(play)";exit
    when 0x7
      puts "Not implemented #{id}(stop)";exit
    when 0x8
      puts "Not implemented #{id}(toggle quality)";exit
    when 0x9
      puts "Not implemented #{id}(stop sound)";exit
    when 0xa then a="add";i="2+" # pop + pop => push
    when 0xb then a="subtract";i="2-" # pop - pop => push
    when 0xc then a="multiply";i="2*" # pop * pop => push
    when 0xd then a="divide";i="2/" # pop / pop => push
    when 0xe then a="equal";i="2=" # pop == pop => push
    when 0xf
      puts "Not implemented #{id}(less than)";exit
    when 0x10
      puts "Not implemented #{id}(logical and)";exit
    when 0x11
      puts "Not implemented #{id}(logical or)";exit
    when 0x12 then a="logical not";i="1~" # ~pop => push
    when 0x13
      puts "Not implemented #{id}(string equal)";exit
    when 0x14
      puts "Not implemented #{id}(string length)";exit
    when 0x15
      puts "Not implemented #{id}(substring)";exit
    when 0x17
      puts "Not implemented #{id}(pop)";exit
    when 0x18
      puts "Not implemented #{id}(integral part)";exit
    when 0x1c then a="getvariable";i="1[" # *pop => push
    when 0x1d then a="setvariable";i="2]" # pop => *pop
    when 0x20
      puts "Not implemented #{id}(set target(dynamic))";exit
    when 0x21 then a="concatenate string";i="2+" # pop +(string) pop => push
    when 0x22
      puts "Not implemented #{id}(get property)";exit
    when 0x23
      puts "Not implemented #{id}(set property)";exit
    when 0x24
      puts "Not implemented #{id}(duplicate sprite)";exit
    when 0x25
      puts "Not implemented #{id}(remove sprite)";exit
    when 0x26
      puts "Not implemented #{id}(trace)";exit
    when 0x27
      puts "Not implemented #{id}(start drag)";exit
    when 0x28
      puts "Not implemented #{id}(stop drag)";exit
    when 0x29
      puts "Not implemented #{id}(string less than)";exit
    when 0x2a
      puts "Not implemented #{id}(throw)";exit
    when 0x2b
      puts "Not implemented #{id}(cast object)";exit
    when 0x2c
      puts "Not implemented #{id}(implements)";exit
    when 0x2d
      puts "Not implemented #{id}(FSCommand2)";exit
    when 0x30
      puts "Not implemented #{id}(random)";exit
    when 0x31
      puts "Not implemented #{id}(string length(multi-byte))";exit
    when 0x32
      puts "Not implemented #{id}(ord)";exit
    when 0x33
      puts "Not implemented #{id}(chr)";exit
    when 0x34
      puts "Not implemented #{id}(get timer)";exit
    when 0x35
      puts "Not implemented #{id}(substring(multi-byte))";exit
    when 0x36
      puts "Not implemented #{id}(ord(multi-byte))";exit
    when 0x37
      puts "Not implemented #{id}(chr)";exit
    when 0x3a
      puts "Not implemented #{id}(delete)";exit
    when 0x3b
      puts "Not implemented #{id}(delete all)";exit
    when 0x3c then a="setlocalvariable";i="2]" # pop => *pop
    when 0x3d then a="call function";i="2c" # pop(pop(argc): pops(argv)) => push
    when 0x3e then a="return";i="1r" # return pop | push(caller)
    when 0x3f then a="modulo";i="2%" # pop % pop => push
    when 0x40
      puts "Not implemented #{id}(new)";exit
    when 0x41
      puts "Not implemented #{id}(declare localvariable)";exit
    when 0x42
      puts "Not implemented #{id}(declare array)";exit
    when 0x43
      puts "Not implemented #{id}(declare object)";exit
    when 0x44
      puts "Not implemented #{id}(type of)";exit
    when 0x45
      puts "Not implemented #{id}(get target)";exit
    when 0x46
      puts "Not implemented #{id}(enumerate)";exit
    when 0x47 then a="add(typed)";i="2+" # pop + pop => push
    when 0x48
      puts "Not implemented #{id}(less than(typed))";exit
    when 0x49 then a="equal(typed)";i="2=" # pop == pop => push
    when 0x4a
      puts "Not implemented #{id}(number)";exit
    when 0x4b
      puts "Not implemented #{id}(strin)";exit
    when 0x4c
      puts "Not implemented #{id}(duplicate)";exit
    when 0x4d
      puts "Not implemented #{id}(swap)";exit
    when 0x4e
      puts "Not implemented #{id}(get member)";exit
    when 0x4f
      puts "Not implemented #{id}(set member)";exit
    when 0x50
      puts "Not implemented #{id}(increment)";exit
    when 0x51
      puts "Not implemented #{id}(decrement)";exit
    when 0x52
      puts "Not implemented #{id}(call method)";exit
    when 0x53
      puts "Not implemented #{id}(new method)";exit
    when 0x54
      puts "Not implemented #{id}(instance of)";exit
    when 0x55
      puts "Not implemented #{id}(enumerate object)";exit
    when 0x60 then a="and";i="2&" # pop + pop => push
    when 0x61
      puts "Not implemented #{id}(bit or)";exit
    when 0x62
      puts "Not implemented #{id}(xor)";exit
    when 0x63
      puts "Not implemented #{id}(shift left)";exit
    when 0x64
      puts "Not implemented #{id}(shift right)";exit
    when 0x65
      puts "Not implemented #{id}(shift right unsigned)";exit
    when 0x66
      puts "Not implemented #{id}(strict equal)";exit
    when 0x67
      puts "Not implemented #{id}(greater than)";exit
    when 0x68
      puts "Not implemented #{id}(string greater than)";exit
    when 0x69
      puts "Not implemented #{id}(extends)";exit
    when 0x81
      puts "Not implemented #{id}(goto frame)";exit
    when 0x83
      puts "Not implemented #{id}(get url)";exit
    when 0x87
      puts "Not implemented #{id}(store register)";exit
    when 0x88 # declare dictionary
      size = @f.readh(2).unpack('S<')[0]
      chk = @f.readh(size)
      cnt = chk.read(2).unpack('S<')[0]
      d = []
      cnt.times do
        d += [readstr(chk)]
      end
      a="dict #{d}";i="d"
    when 0x89
      puts "Not implemented #{id}(strict mode)";exit
    when 0x8a
      puts "Not implemented #{id}(wait for frame)";exit
    when 0x8b
      puts "Not implemented #{id}(set target)";exit
    when 0x8c
      puts "Not implemented #{id}(goto label)";exit
    when 0x8d
      puts "Not implemented #{id}(wait for frame(dynamic))";exit
    when 0x8e
      puts "Not implemented #{id}(declare function v7)";exit
    when 0x8f
      puts "Not implemented #{id}(try)";exit
    when 0x94
      puts "Not implemented #{id}(with)";exit
    when 0x96 # push data
      size = @f.readh(2).unpack('S<')[0]
      d = readdata(@f.readh(size), dict)
      a = "push #{d}"
      i = "p"
    when 0x99 # branch always
      size = @f.readh(2).unpack('S<')[0]
      d = @f.readh(2).unpack('s<')[0]
      a = "branch always:#{d}(#{d.to_s(16)})->#{(@f.tell+d).to_s(16)}"
      i = "ba"
    when 0x9a
      puts "Not implemented #{id}(get url2)";exit
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
      if isdebug==0 # on disassemble look into
        p "Func(#{fun_nm}), argc:#{argc}, fun_len:#{fun_len} <<"
        disas(fun_len)
      else # on debug skip
        @f.seek(fun_len, IO::SEEK_CUR)
      end
    when 0x9d # branch If True / if(pop)
      size = @f.readh(2).unpack('S<')[0]
      d = @f.readh(2).unpack('s<')[0]
      a = "branch if True off:#{d}(#{d.to_s(16)})->#{(@f.tell+d).to_s(16)}"
      i = "bt"
    when 0x9e
      puts "Not implemented #{id}(call frame)";exit
    when 0x9f
      puts "Not implemented #{id}(goto expr)";exit
    else
      puts "Unknown Action ID #{id}(#{id.to_s(16)})"
      exit
    end
    return a,i,d
  end #end method
end #end class

#f = Hsalf.new("flashenc.swf",392)
f = Hsalf.new("flashenc.swf",0x14b)
f.disas
#f.debug([])