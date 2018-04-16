#!/usr/bin/perl
use VTP::Common::Exception;
use VTP::Common::Log;
use Frontier::Client;
use Cwd;
use File::Basename;
use plog;
use Time::HiRes;

#open STDIN,  '</dev/null' || die "can't read /dev/null  [$!]";
#open STDOUT, '>/dev/null' || die "can't write /dev/null [$!]";
#open STDERR, '>&STDOUT'   || die "can't open STDERR to STDOUT [$!]";

sub proxy {
    my ($filename, $basename, $cwd) = @_;

    log_debug(action => "proxy", result => 'start', err_msg => $filename);

    my $client = Frontier::Client->new('url' => "http://127.0.0.1:10002/RPC2");
    my $ret = $client->call('exec_start', $filename, $basename, $cwd, \@ARGV);
    die "$ret\n" if $ret;
}

sub main {
    my ($linkname) = @_;
    my $basename = basename($linkname);
    my $filename = Cwd::realpath("$linkname.vtpperl");
    my $cwd = Cwd::getcwd();

    #设置日志输出到实际要启动的脚本，通过perlproxy启动失败时，会在本进程启动
    #这里设置保障了日志正常输出到对应的脚本日志中
    plog::CL_SetAppName($basename);
    plog::CL_LogUnInit();
    my $use_proxy = $ENV{VTPPERLPROXY_DISABLE};

    my $time = Time::HiRes::time();
    eval {
        proxy($filename, $basename, $cwd) if !$use_proxy;
    };
    if ($use_proxy || (my $err = vtp_catch($@))) {
        log_error(action => "proxy", result => "failed", err_msg => $err->get_info()) if $err;
        #如果代理执行失败，则直接启动perl程序
        require "$filename";
    }
    $time = (Time::HiRes::time() - $time) * 1000;
    log_debug(action => "proxytime", result => "$time(ms)");
}

main($0);
