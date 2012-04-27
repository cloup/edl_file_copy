require 'find'
require 'fileutils'
require 'readline'
CONFIGFILE = 'config.txt'

puts 'edl file copy utility'
puts ''

if(!File.exists?(CONFIGFILE))
  puts 'cannot find ' + CONFIGFILE
  Readline.readline('press return to quit', true)
  exit 1
end

load 'config.txt'
sourcedir = SOURCEDIR.gsub(/\\/, '/')
destdir = DESTDIR.gsub(/\\/, '/')
edl = EDL.gsub(/\\/, '/')

if(!File.exists?(sourcedir))
  puts 'cannot find SOURCEDIR ' + SOURCEDIR
  Readline.readline('press return to quit', true)
  exit 1
end

if(!File.exists?(destdir))
  puts 'cannot find DESTDIR ' + DESTDIR
  Readline.readline('press return to quit', true)
  exit 1
end

if(!File.exists?(edl))
  puts 'cannot find EDL ' + EDL
  Readline.readline('press return to quit', true)
  exit 1
end

puts 'Source directory : ' + SOURCEDIR
puts 'Destination directory : ' + DESTDIR
puts 'Edit list : ' + EDL
puts ''

records = Hash.new

# parsing edit list, looking for ' FROM nnnn : xxxxxxxx.zzz' pattern where xxxxxxxx is the filename
# the filename in lowercase is stored in a hash
edl = File.new(edl, "r")
while (line = edl.gets)
   regex = /(?:\s+FROM\s+.+\:\s*)([a-z0-9_\-]{4,})(?:\.[a-z]{1,4})/i
   m = regex.match(line)
   if ( m && m[1])
     # taking care of exception where filename ends in '_001' when it should not
     record_key = m[1].sub(/_001$/, '.RDC')
     records.store(record_key.downcase, '')
   end
end
edl.close

puts '' + records.length.to_s() + ' records found in edit list'
puts ''
Readline.readline('press return to start', true)

now = Time.new
puts ''
puts now.strftime("Started on %d.%m.%Y at %H:%M:%S")
puts ''

# starts scanning SOURCEDIR recursively
record_count_ok = 0
record_count_ignored = 0
record_count_total = 0
Find.find(sourcedir) do |f| 
  if(File.directory?(f))
    dest = destdir + '/' + File.basename(f)
    keyfilename = File.basename(f).downcase
    if(records[keyfilename])
      record_count_total += 1
      if(File.exists?(dest))
        record_count_ignored += 1
        records.store(keyfilename, 'IGNORED')
        puts '[' + record_count_total.to_s() + ' of ' + records.length.to_s() + '] ' + keyfilename + ' ignored, already exists in destination folder.'
      else
        record_count_ok += 1
        records.store(keyfilename, 'OK')
        puts '[' + record_count_total.to_s() + ' of ' + records.length.to_s() + '] copying ' + f + ' ...'
        FileUtils.cp_r(f, dest)
      end
    end
  end
end

puts ''
puts 'finished, ' + record_count_ok.to_s() + ' of ' + records.length.to_s() + ' records successfully processed.'
if(record_count_ignored > 0)
  puts record_count_ignored.to_s() + ' records ignored.'
end  
not_found_count = 0
records.keys.sort.each{|key, value| 
  if(records[key] != 'OK' && records[key] != 'IGNORED')
    not_found_count += 1
    puts key + ' not found'
  end
}
if(not_found_count > 0)
  puts not_found_count.to_s + ' records not found.'
end

Readline.readline('press return to quit', true)
