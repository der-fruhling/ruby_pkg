require 'json'
require 'fileutils'

if ARGV[1].nil?
    puts "Usage: ./ruby_pkg <install|remove|--help> <package>"
    fail
end

@index = JSON.parse File.read('index.json')
psrv = @index['services']['primary']

func = ARGV[0]

if func == '--help'
    puts File.read('help.txt')
    exit 1
end

@usegz = false
@fromurl = false
@srv = psrv
@file = nil

ARGV[1..].each do |arg|
    if arg.start_with? '-'
        a = arg[1]
        case a
        when 'u'
            if func == 'install'
                @fromurl = true
            else
                puts 'Cannot use -u in mode other than install.'
                fail
            end
        when 's'
            unless @fromurl
                puts 'Put -u before -s.'
                fail
            else
                @srv = @index['services'][arg[2..]]
            end
        when 'g'
            @usegz = true
        else
            puts "Invalid option: #{arg}"
        end
    else
        @file = arg
    end
end

if @file.nil?
    puts "Specify package."
    fail
end

if func == 'install'
    FileUtils.rm_r 'tmp' if Dir.exist? 'tmp'
    Dir.mkdir 'tmp'
    if @fromurl
        require 'open-uri'
        puts "\e[32;1mDownloading...\e[0m"
        url = nil
        unless @usegz
            url = "#{@srv}/#{@file}.txz"
        else
            url = "#{@srv}/#{@file}.tgz"
        end
        puts "\e[34;1m- Getting #{url}"
        f = open url
        File.write 'tmp/.tmp', f.read
    else
        FileUtils.cp @file, 'tmp/.tmp'
    end

    puts "\e[32;1mExtracting...\e[0m"
    compress_char = 'J'
    compress_char = 'z' if @usegz
    Dir.chdir 'tmp'
    system "tar -#{compress_char}xf .tmp"
    puts "\e[33;1mThis program now requires sudo privledges.\e[0m"
    puts "\e[32;1mYou will be kept up to date on whats happening.\e[0m"
    pkgname = @file.split('/')
    pkgname = pkgname[pkgname.size - 1].split('.')[0]
    system "sudo tar -#{compress_char}tf .tmp > #{@index['pkg_dirs']['outside'] + "/#{pkgname}.pkg_listing"}"
    FileUtils.rm '.tmp'
    Dir.chdir '..'
    system 'sudo ./ruby_pkg place tmp'
    FileUtils.rm_r 'tmp'
    puts "\e[34;1mDone.\e[0m"
    system 'echo $PATH > .path'
    path = File.read '.path'
    File.delete '.path'
    puts "\e[33;1mYou may want to add '/var/ruby_pkg/packages/bin' to your PATH.\e[0m" unless path.include? '/var/ruby_pkg/packages/bin'
elsif func == 'remove'
    puts "\e[33;1mThis program now requires sudo privledges.\e[0m"
    puts "\e[32;1mYou will be kept up to date on whats happening.\e[0m"
    system "sudo ./ruby_pkg unplace #{@file}"
elsif func == 'place'
    puts "\e[32;1mPlacing...\e[0m"
    puts "\e[34;1m- Creating directories...\e[0m"
    @index['mkdirs_noexist'].each { |dir| Dir.mkdir dir unless Dir.exist? dir }
    Dir.mkdir @index['pkg_dirs']['outside'] unless Dir.exist? @index['pkg_dirs']['outside']
    puts "\e[34;1m- Copying files to directories \e[32;1m#{@index['pkg_dirs']['outside'] + "/*"}\e[0m"
    puts "\e[33;1m  * tmp/bin => #{@index['pkg_dirs']['outside'] + "/bin"}"
    FileUtils.cp_r 'tmp/bin', @index['pkg_dirs']['outside'] + "/bin"
    puts "\e[33;1m  * tmp/lib => #{@index['pkg_dirs']['outside'] + "/lib"}"
    FileUtils.cp_r 'tmp/lib', @index['pkg_dirs']['outside'] + "/lib"
elsif func == 'unplace'
    puts "\e[32;1mUnplacing (removing)...\e[0m"
    puts "\e[34;1m- Reading file list."
    filelist = File.read @index['pkg_dirs']['outside'] + "/#{@file}.pkg_listing"
    puts filelist
    filelist.each_line do |line|
        if line.include? '.'
            print "\e[31;1m  * Removing #{@file}:#{line.chomp} "
            a = line
            a = a.gsub 'bin/', @index['pkg_dirs']['outside'] + "/bin/"
            a = a.gsub 'lib/', @index['pkg_dirs']['outside'] + "/lib/"
            puts "(#{a.chomp})\e[0m"
            FileUtils.rm_r a.chomp
        end
    end
else
    puts "Invalid function: #{func}"
    fail
end