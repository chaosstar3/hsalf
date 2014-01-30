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
  @f # file object
  @g # global information
  
public
  def initialize(filename, offset=0, size=0)
    @f = File.open(filename, "rb")
    @f.seek(offset, IO::SEEK_SET)
    size = @f.size if size == 0
    @g = Struct.new(:v,:f).new({},{}) #variable, function
    #@b = f.read(size-offset)
    #@f.close    
  end
  
  def position(num)
    @f.seek(num, IO::SEEK_SET)
  end
  
  def disas(len=@f.size)
    ori = @f.tell
    while @f.tell < ori+len
      puts decode[0]
    end
  end

  def debug(argv=[])
    frame = Struct.new(:s,:v,:d).new([],{},[]) #stack, variables, dictionary
    loop do
      text,action = decode
      p text
      if action=="return"
        return frame.s.pop
      elsif action=="end"
        return nil
      end
      action.call(frame)
      p frame
      p @g
    end # loop end
  end
  
  # used for decode()
  def readstr(s) # read until null end
    i = s.index("\x00")
    puts "Warning: no null ended" if i.nil?
    s.read(i+1)[0..-2]
  end
  def readdata(d) # for push
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
        data += [[ref]]
      when 9 # large dictionary
        ref = d.read(2).unpack('S')[0]
        data += [[ref]]
      else
        puts "Unknown Data Type #{type}(#{type.to_s(16)})"
      end
    end
    return data
  end
  def isnum(num)
    num.class==Fixnum || num.class==Float #|| num.class==Bignum
  end
  
  def decode()
    #t:action.to_s a:action
    #size:action length #data:action structure
    print "[#{@f.tell.to_s(16)}] "
    id = @f.readh(1).ord
    case id # Action identifier
    when 0x0 then t="end";a="end"
    when 0x4 then puts "Not implemented #{id}(next frame)";exit
    when 0x5 then puts "Not implemented #{id}(previous frame)";exit
    when 0x6 then puts "Not implemented #{id}(play)";exit
    when 0x7 then puts "Not implemented #{id}(stop)";exit
    when 0x8 then puts "Not implemented #{id}(toggle quality)";exit
    when 0x9 then puts "Not implemented #{id}(stop sound)";exit
    when 0xa then t="add";      a=Proc.new{|f| o=f.s.pop;f.s.push(f.s.pop+o)}
    when 0xb then t="subtract"; a=Proc.new{|f| o=f.s.pop;f.s.push(f.s.pop-o)}
    when 0xc then t="multiply"; a=Proc.new{|f| o=f.s.pop;f.s.push(f.s.pop*o)}
    when 0xd then t="divide";   a=Proc.new{|f| o=f.s.pop;f.s.push(f.s.pop/o)}
    when 0xe then t="equal";    a=Proc.new{|f| f.s.push((f.s.pop==f.s.pop)?1:0)}
    when 0xf then puts "Not implemented #{id}(less than)";exit
    when 0x10 then puts "Not implemented #{id}(logical and)";exit
    when 0x11 then puts "Not implemented #{id}(logical or)";exit
    when 0x12 then t="logical not";a=Proc.new{|f| f.s.push(not(f.s.pop!=0)?1:0)}
    when 0x13 then puts "Not implemented #{id}(string equal)";exit
    when 0x14 then puts "Not implemented #{id}(string length)";exit
    when 0x15 then puts "Not implemented #{id}(substring)";exit
    when 0x17 then puts "Not implemented #{id}(pop)";exit
    when 0x18 then puts "Not implemented #{id}(integral part)";exit
    when 0x1c then t="getvariable"
      a=Proc.new do |f|      
        var_nm = f.s.pop
        if !f.v[var_nm].nil? then f.s.push(f.v[var_nm])
        elsif !@g.v[var_nm].nil? then f.s.push(@g.v[var_nm]) 
        else
          p "[debug] fail to get variable #{var_nm}"
          var = STDIN.gets
          f.s.push(var.chomp)
        end
      end
    when 0x1d then t="setvariable"
      a=Proc.new do |f|
        var_nm,o = f.s.pop(2)
        if !f.v[var_nm].nil? then f.v[var_nm]=o
        else @g.v[var_nm]=o end
      end
    when 0x20 then puts "Not implemented #{id}(set target(dynamic))";exit
    when 0x21 then puts "Not implemented #{id}(concatenate string)";exit # pop +(string) pop => push
    when 0x22 then puts "Not implemented #{id}(get property)";exit
    when 0x23 then puts "Not implemented #{id}(set property)";exit
    when 0x24 then puts "Not implemented #{id}(duplicate sprite)";exit
    when 0x25 then puts "Not implemented #{id}(remove sprite)";exit
    when 0x26 then puts "Not implemented #{id}(trace)";exit
    when 0x27 then puts "Not implemented #{id}(start drag)";exit
    when 0x28 then puts "Not implemented #{id}(stop drag)";exit
    when 0x29 then puts "Not implemented #{id}(string less than)";exit
    when 0x2a then puts "Not implemented #{id}(throw)";exit
    when 0x2b then puts "Not implemented #{id}(cast object)";exit
    when 0x2c then puts "Not implemented #{id}(implements)";exit
    when 0x2d then puts "Not implemented #{id}(FSCommand2)";exit
    when 0x30 then puts "Not implemented #{id}(random)";exit
    when 0x31 then puts "Not implemented #{id}(string length(multi-byte))";exit
    when 0x32 then puts "Not implemented #{id}(ord)";exit
    when 0x33 then puts "Not implemented #{id}(chr)";exit
    when 0x34 then puts "Not implemented #{id}(get timer)";exit
    when 0x35 then puts "Not implemented #{id}(substring(multi-byte))";exit
    when 0x36 then puts "Not implemented #{id}(ord(multi-byte))";exit
    when 0x37 then puts "Not implemented #{id}(chr)";exit
    when 0x3a then puts "Not implemented #{id}(delete)";exit
    when 0x3b then puts "Not implemented #{id}(delete all)";exit
#TODO setlocalvariable vs declarelocalvariable
    when 0x3c then t="setlocalvariable";a=Proc.new{|f| o=f.s.pop;f.v[f.s.pop]=o}
    when 0x3d then t = "call" # call function 
      a = Proc.new do |f|
        argc, fun_nm = f.s.pop(2)
        fun_pos = @g.f[fun_nm][0]
        retaddr = @f.tell
        @f.seek(fun_pos, IO::SEEK_SET)
# TODO handle argv
# pop(pop(argc): pops(argv)) => push        
        ret=debug([])
        f.s.push(ret) if !ret.nil?
        @f.seek(retaddr, IO::SEEK_SET)
      end
    when 0x3e then t="return";a="return" # return pop | push(caller)
    when 0x3f then t="modulo";a=Proc.new{|f| o=f.s.pop;f.s.push(f.s.pop%o)} 
    when 0x40 then puts "Not implemented #{id}(new)";exit
    when 0x41 then puts "Not implemented #{id}(declare localvariable)";exit
    when 0x42 then puts "Not implemented #{id}(declare array)";exit
    when 0x43 then puts "Not implemented #{id}(declare object)";exit
    when 0x44 then puts "Not implemented #{id}(type of)";exit
    when 0x45 then puts "Not implemented #{id}(get target)";exit
    when 0x46 then puts "Not implemented #{id}(enumerate)";exit
    when 0x47 then t="add(typed)"
      a=Proc.new do |f| 
        o2,o1 = f.s.pop(2)
        if isnum(o1) and isnum(o2)
          f.s.push(o1+o2)
        else
          f.s.push(o1.to_s+o2.to_s)
        end
      end
    when 0x48 then puts "Not implemented #{id}(less than(typed))";exit
    when 0x49 then t="equal";a=Proc.new{|f| f.s.push((f.s.pop==f.s.pop)?1:0)}
    when 0x4a then puts "Not implemented #{id}(number)";exit
    when 0x4b then puts "Not implemented #{id}(strin)";exit
    when 0x4c then puts "Not implemented #{id}(duplicate)";exit
    when 0x4d then puts "Not implemented #{id}(swap)";exit
    when 0x4e then puts "Not implemented #{id}(get member)";exit
    when 0x4f then puts "Not implemented #{id}(set member)";exit
    when 0x50 then puts "Not implemented #{id}(increment)";exit
    when 0x51 then puts "Not implemented #{id}(decrement)";exit
    when 0x52 then puts "Not implemented #{id}(call method)";exit
    when 0x53 then puts "Not implemented #{id}(new method)";exit
    when 0x54 then puts "Not implemented #{id}(instance of)";exit
    when 0x55 then puts "Not implemented #{id}(enumerate object)";exit
    when 0x60 then puts "Not implemented #{id}(and)";exit # pop + pop => push
    when 0x61 then puts "Not implemented #{id}(bit or)";exit
    when 0x62 then puts "Not implemented #{id}(xor)";exit
    when 0x63 then puts "Not implemented #{id}(shift left)";exit
    when 0x64 then puts "Not implemented #{id}(shift right)";exit
    when 0x65 then puts "Not implemented #{id}(shift right unsigned)";exit
    when 0x66 then puts "Not implemented #{id}(strict equal)";exit
    when 0x67 then puts "Not implemented #{id}(greater than)";exit
    when 0x68 then puts "Not implemented #{id}(string greater than)";exit
    when 0x69 then puts "Not implemented #{id}(extends)";exit
    when 0x81 then puts "Not implemented #{id}(goto frame)";exit
    when 0x83 then puts "Not implemented #{id}(get url)";exit
    when 0x87 then puts "Not implemented #{id}(store register)";exit
    when 0x88 # declare dictionary
      size = @f.readh(2).unpack('S<')[0]
      data = @f.readh(size)
      cnt = data.read(2).unpack('S<')[0]
      dict = []
      cnt.times do
        dict += [readstr(data)]
      end
      t = "dict ["+dict.join(',')+"]"
      a = Proc.new do |f|
        f.d += dict
      end
    when 0x89 then puts "Not implemented #{id}(strict mode)";exit
    when 0x8a then puts "Not implemented #{id}(wait for frame)";exit
    when 0x8b then puts "Not implemented #{id}(set target)";exit
    when 0x8c then puts "Not implemented #{id}(goto label)";exit
    when 0x8d then puts "Not implemented #{id}(wait for frame(dynamic))";exit
    when 0x8e then puts "Not implemented #{id}(declare function v7)";exit
    when 0x8f then puts "Not implemented #{id}(try)";exit
    when 0x94 then puts "Not implemented #{id}(with)";exit
    when 0x96 # push data
      size = @f.readh(2).unpack('S<')[0]
      data = readdata(@f.readh(size))
      t = "push ["+data.join(',')+"]"
      a = Proc.new do |f|
        data.map! {|dd| (dd.class==Array) ? f.d[dd[0]] : dd} #dictionary check
        f.s += data
      end
    when 0x99 # branch always
      size = @f.readh(2).unpack('S<')[0]
      data = @f.readh(2).unpack('s<')[0]
      t = "branch always ->#{(@f.tell+data).to_s(16)}"
      a = Proc.new {@f.seek(data, IO::SEEK_CUR)}
    when 0x9a then puts "Not implemented #{id}(get url2)";exit
    when 0x9b  # declare function
      size = @f.readh(2).unpack('S<')[0]
      data = @f.readh(size)
      fun_nm = readstr(data)
#TODO handle argv
      argc = data.read(2).unpack('S<')[0]
      argv = []
      argc.times{argv+=[readstr(data)]}
      
      fun_len = data.read(2).unpack('S<')[0]
      fun_pos = @f.tell
      t = "func(#{fun_nm}), argc:#{argc}, fun_pos:#{fun_pos.to_s(16)} fun_len:#{fun_len}"
      a = Proc.new do |f|
        @g.f[fun_nm]=[fun_pos,argc,argv]
        @f.seek(fun_len, IO::SEEK_CUR)
      end
    when 0x9d # branch If True / if(pop)
      size = @f.readh(2).unpack('S<')[0]
      data = @f.readh(2).unpack('s<')[0]
      t = "branch if True ->#{(@f.tell+data).to_s(16)}"
      a = Proc.new {|f| @f.seek(data, IO::SEEK_CUR) if f.s.pop!=0}
    when 0x9e then puts "Not implemented #{id}(call frame)";exit
    when 0x9f then puts "Not implemented #{id}(goto expr)";exit
    else
      puts "Unknown Action ID #{id}(#{id.to_s(16)})"
      exit
    end
    return t,a
  end #end method
end #end class
