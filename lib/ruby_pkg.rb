require 'json'
require 'fileutils'

DEFAULT_CONFIG = {
    "services" => {
        "primary" => "https://raw.githubusercontent.com/LiamCoal/ruby_pkg/master/pkgrepo"
    },
    "pkg_dirs" => {
        "inside" => ".",
        "outside" => "/var/ruby_pkg/packages"
    },
    "mkdirs_noexist" => ["/var/ruby_pkg"],
    "local_pkg_repo" => "/var/ruby_pkg/pkgrepo"
}.freeze

def work(argv)
    if argv[0].nil?
        puts "Usage: ruby_pkg <install|remove|reset|--help> <package>"
        fail
    end

    if argv[0] == 'reset'
        require 'fileutils'
        FileUtils.rm_r '/var/ruby_pkg'
        exit 0
    end

    Dir.mkdir '/var/ruby_pkg' unless Dir.exist? '/var/ruby_pkg'
    Dir.mkdir '/var/ruby_pkg/packages' unless Dir.exist? '/var/ruby_pkg/packages'
    File.write '/var/ruby_pkg/index.json', JSON.pretty_generate(DEFAULT_CONFIG) unless File.exist? '/var/ruby_pkg/index.json'
    @index = JSON.parse File.read('/var/ruby_pkg/index.json')
    psrv = @index['services']['primary']

    func = argv[0]

    if func == '--help'
        puts %q{
----------------- ruby_pkg ----------------
This file is merely a stub.
For the real help, see:

http://liamcoal.github.io/ruby_pkg/easyhelp
-------------------------------------------
}
        exit 1
    end

    if argv[1].nil?
        puts "Usage: ruby_pkg <install|remove|--help> <package>"
        fail
    end

    @usegz = false
    @fromurl = false
    @srv = psrv
    @file = nil
    @fromrepo = false
    @from_dedicated_server = false

    argv[1..(argv.size-1)].each do |arg|
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
                unless @fromurl || @from_dedicated_server
                    puts 'Put -u before -s.'
                    fail
                else
                    @srv = @index['services'][arg[2..(arg.size-1)]]
                end
            when 'g'
                @usegz = true
            when 'r'
                @fromrepo = true
            when 'S'
                @from_dedicated_server = true
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
        elsif @from_dedicated_server
            require 'socket'
            require 'base64'
            puts "\e[33;1mUsing experimental server!\e[0m"
            puts "\e[32mConnecting on #{@srv}:4876"
            socket = TCPSocket.new @srv, 4876
            puts "\e[33;1mSeeing if package exists on server...\e[0m"
            socket.puts "exists #{@file}#{@usegz ? ' gz' : ''}"
            filenum = 0
            exists = socket.gets
            if exists == 'no'
                fail 'Package does not exist. (PKG_NO_EXIST)'
            else
                filenum = exists.to_i
            end
            puts "\e[32mGetting file #{filenum}\e[0m"
            socket.puts "get #{filenum}"
            data = socket.gets.chomp
            socket.puts 'close'
            puts "\e[32mDecoding file #{filenum}\e[0m"
            File.write 'tmp/.tmp', Base64.decode64(data)
        else
            if @fromrepo
                FileUtils.cp "#{@index['local_pkg_repo']}/#{@file}", 'tmp/.tmp'
            else
                FileUtils.cp @file, 'tmp/.tmp'
            end
        end
        puts "\e[32;1mExtracting...\e[0m"
        compress_char = 'J'
        compress_char = 'z' if @usegz
        Dir.chdir 'tmp'
        system "tar -#{compress_char}xf .tmp"
        if File.exist? 'Makefile'
            puts "\e[32;1mRunning make...\e[0m"
            system "make"
        end
        if File.exist? 'Rakefile'
            puts "\e[32;1mRunning rake...\e[0m"
            system "rake"
        end
        puts "\e[33;1mThis program now requires sudo privledges.\e[0m"
        puts "\e[32;1mYou will be kept up to date on whats happening.\e[0m"
        pkgname = @file.split('/')
        pkgname = pkgname[pkgname.size - 1].split('.')[0]
        system "sudo tar -#{compress_char}tf .tmp > #{@index['pkg_dirs']['outside'] + "/#{pkgname}.pkg_listing"}"
        unless File.exist? "#{@index['pkg_dirs']['outside'] + "/#{pkgname}.pkg_listing"}"
            puts "\e[31;1mListing was not created!\nRerun with sudo.\e[0m"
            fail
        end
        FileUtils.rm '.tmp'
        Dir.chdir '..'
        system 'sudo ruby_pkg place tmp'
        FileUtils.rm_r 'tmp'
        puts "\e[34;1mDone.\e[0m"
    elsif func == 'remove'
        puts "\e[33;1mThis program now requires sudo privledges.\e[0m"
        puts "\e[32;1mYou will be kept up to date on whats happening.\e[0m"
        system "sudo ruby_pkg unplace #{@file}"
    elsif func == 'place'
        puts "\e[32;1mPlacing...\e[0m"
        puts "\e[34;1m- Creating directories...\e[0m"
        @index['mkdirs_noexist'].each { |dir| Dir.mkdir dir unless Dir.exist? dir }
        Dir.mkdir @index['pkg_dirs']['outside'] unless Dir.exist? @index['pkg_dirs']['outside']
        puts "\e[34;1m- Copying files to directories \e[32;1m#{@index['pkg_dirs']['outside'] + "/*"}\e[0m"
        puts "\e[33;1m  * tmp/bin => #{@index['pkg_dirs']['outside'] + "/bin"}"
        FileUtils.cp_r 'tmp/bin', @index['pkg_dirs']['outside']
        puts "\e[33;1m  * tmp/lib => #{@index['pkg_dirs']['outside'] + "/lib"}"
        FileUtils.cp_r 'tmp/lib', @index['pkg_dirs']['outside']
    elsif func == 'unplace'
        puts "\e[32;1mUnplacing (removing)...\e[0m"
        puts "\e[34;1m- Reading file list."
        filelist = File.read @index['pkg_dirs']['outside'] + "/#{@file}.pkg_listing"
        puts filelist
        @problem = nil
        filelist.each_line do |line|
            if line.include? '.'
                print "\e[31;1m  * Removing #{@file}:#{line.chomp} "
                a = line
                a = a.gsub 'bin/', @index['pkg_dirs']['outside'] + "/bin/"
                a = a.gsub 'lib/', @index['pkg_dirs']['outside'] + "/lib/"
                print "(#{a.chomp})"
                unless File.exist? a.chomp
                    print ' already deleted or never existed.'
                    @problem = 'A file never existed or was already deleted.'
                else
                    FileUtils.rm_r a.chomp
                end
                puts "\e[0m"
            end
        end
    elsif func == 'run'
        system "ruby /var/ruby_pkg/packages/bin/#{@file}.rb"
    else
        puts "Invalid function: #{func}"
        fail
    end

    unless @problem.nil?
        puts "\e[33;1mThere may be a problem:\n\n#{@problem}\e[0m"
    end
end
