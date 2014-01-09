class String
  def read(c)
    self.slice!(0...c)
  end
  def readh(c)
    self.slice!(0...c).bytes {|ss| print "%02x "%ss}
  end
end

# Based on file format analysis
# Refer from http://www.m2osw.com/swf_alexref
class Hsalf
  @b
  @indent
  
  def initialize(filename, offset=0, size=0)
    f = File.open(filename, "rb")
    f.read(offset)
    size = f.size if size == 0
    @b = f.read(size)
    @indent = -1
    f.close
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
  
  def np(s)
    #puts ""
    @indent.times {print "\t"}
    p s
  end
  def disas(b = @b)
    @indent += 1
    while b.length>0 do
      @indent.times {print "\t"}
      id = b.readh(1).ord
      case id # Action identifier
      when 0x0 then np "end"
      when 0xa then np "add" # pop + pop => push
      when 0xb then np "subtract" # pop - pop -> push
      when 0xc then np "multiply" # pop * pop => push
      when 0xe then np "equal" # pop == pop => push
      when 0x12 then np "not" # ~pop => push
      when 0x1c then np "getvariable" # *pop => push
      when 0x1d then np "setvariable" # pop => *pop
      when 0x3c then np "setlocalvariable" # pop => *pop
      when 0x3d then np "call function" # pop(pop(argc): pops(argv)) => push
      when 0x3e then np "return" # return pop | push(caller)
      when 0x3f then np "modulo" # pop % pop => push
      when 0x47 then np "add(type)" # pop + pop => push
      when 0x88 # declare dictionary
        dsize = b.readh(2).unpack('S<')[0]
        data = b.readh(dsize)
        dict = []
        until data.length <= 0 do
          dict += [readstr(data)]
        end
        np "dict #{dict}"
      when 0x96 # push data
        dsize = b.readh(2).unpack('S<')[0]
        data = readdata(b.readh(dsize))
        np "push #{data}"
      when 0x99 # branch always
        dsize = b.readh(2).unpack('S<')[0]
        puts "warning branch data size != 2" if dsize != 2
        offset = b.readh(2).unpack('s<')[0]
        np "branch off:#{offset}(#{offset.to_s(16)})"
      when 0x9b  # declare function
        dsize = b.readh(2).unpack('S<')[0]
        d = b.readh(dsize)
        fun_nm = readstr(d)
        argc = d.read(2).unpack('S<')[0]
        argv = []
        argc.times{argv+=[readstr(d)]}
        fun_len = d.read(2).unpack('S<')[0]
        np "Func(#{fun_nm}), argc:#{argc}, fun_len:#{fun_len}"
        disas(b.read(fun_len))
      when 0x9d # branch If True / ip += pop
        dsize = b.readh(2).unpack('S<')[0]
        puts "warning branch data size != 2" if dsize != 2
        offset = b.readh(2).unpack('s<')[0]
        np "branch if True off:#{offset}(#{offset.to_s(16)})"
      else
        puts "Unknown Action ID #{id}(#{id.to_s(16)})"
        p b
        exit
      end
    end
  @indent -= 1
  end
end

f = Hsalf.new("")
f.disas
