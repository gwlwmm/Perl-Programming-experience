#!/usr/bin/perl
use VTP::Common::Exception;
use VTP::Common::Log;
use VTP::Common::RPC::HTTPServer;

$0 = "vtpperlproxy";

my $pidfile = "/var/run/vtpperlproxy.pid";
my $cpid;

$SIG{ '__WARN__' } = sub {
    my $err = $@;
    my $t   = $_[0];
    chomp $t;
    $@ = $err;
};

if ( !( $cpid = fork() ) ) {
    $SIG{ PIPE } = 'IGNORE';
    $SIG{ TERM } = $SIG{ QUIT } = sub {
        $SIG{ INT } = 'DEFAULT';
        unlink "$pidfile";
        exit(0);
    };

    log_debug(action => "vtpperlproxy", result => "starting");

    open STDIN,  '</dev/null' || die "can't read /dev/null  [$!]";
    open STDOUT, '>/dev/null' || die "can't write /dev/null [$!]";
    open STDERR, '>&STDOUT'   || die "can't open STDERR to STDOUT [$!]";

    POSIX::setsid();
    eval { 
        server_start(); 
    };
    if (my $err = $@) {
        log_error(action => "vtpperlproxy", result => "error", err_msg => $err);
        exit(-1);
    }
} else {
    open( PIDFILE, ">$pidfile" )
      || die "cant write '$pidfile' - $! :ERROR";
    print PIDFILE "$cpid\n";
    close(PIDFILE)
      || die "cant write '$pidfile' - $! :ERROR";
}
exit(0);

#加载所有模块
use warnings;
no warnings qw(redefine);
use strict;

use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Status;
use HTML::Entities;
use JSON;
use URI::Escape;
use File::Basename;
use Storable;
use Time::HiRes;
use POSIX;
use Cwd;

#begin
use VTP::APIDaemon;
use VTP::HostProxy;
use VTP::Vm::Vm;
use VTP::Vm::Checker;
use VTP::Vm::Backup::BackupReport;
use VTP::Vm::Backup::RecycleScanner;
use VTP::Vm::Backup::BackupRecycle;
use VTP::Vm::Backup::Backup;
use VTP::Vm::Backup::BackupClean;
use VTP::Vm::Backup::BackupViewer;
use VTP::Vm::Backup::BackupCommon;
use VTP::Vm::Backup::BackupScanner;
use VTP::Vm::Backup::OldBackupConvertor;
use VTP::Vm::Backup::BackupPolicy;
use VTP::REST;
use VTP::NodeCommon;
use VTP::VMA_Operate;
use VTP::CollectVMPInfo;
use VTP::IPCC_SDN_CONN;
use VTP::SharedLuns;
use VTP::OpLog;
use VTP::QemuDerive;
use VTP::Storage;
use VTP::QemuCreate;
use VTP::MProcess;
#use VTP::Connect_datareport;
use VTP::HotplugEdit;
use VTP::StartOrder;
use VTP::VAPI::VMOperate;
use VTP::VAPI::Nodes;
use VTP::VAPI::Backup;
use VTP::VAPI::Pool;
use VTP::VAPI::Tasks;
use VTP::VAPI::VDCInterface;
use VTP::VAPI::VAPIMain;
use VTP::VAPI::HAConfig;
use VTP::VAPI::Group;
use VTP::VAPI::RemoteSupport;
use VTP::VAPI::User;
use VTP::VAPI::Update;
use VTP::VAPI::VNetDev;
use VTP::VAPI::TaskCancel;
use VTP::VAPI::ACL;
use VTP::VAPI::Network::Route;
use VTP::VAPI::Network::Topo;
use VTP::VAPI::Network::Ippool;
use VTP::VAPI::Network::Switch;
use VTP::VAPI::Network::Interface;
use VTP::VAPI::Network::Dfwall;
use VTP::VAPI::Network::BorderSwitch;
use VTP::VAPI::Restore;
use VTP::VAPI::SambaShare;
use VTP::VAPI::Subscription;
use VTP::VAPI::Services;
use VTP::VAPI::Log;
use VTP::VAPI::Qemu;
use VTP::VAPI::Test;
use VTP::VAPI::RecycleBin;
use VTP::VAPI::VMStatus;
use VTP::VAPI::Network;
use VTP::VAPI::Storage::Sharedisk;
use VTP::VAPI::Storage::Vtpconfig;
use VTP::VAPI::Storage::Status;
use VTP::VAPI::Storage::Vtpiscsicfg;
use VTP::VAPI::Hosts;
use VTP::VAPI::Cluster;
use VTP::VAPI::Domains;
use VTP::VAPI::AccessControl;
use VTP::VAPI::Index;
use VTP::VAPI::Clustervm;
use VTP::VAPI::DRS;
use VTP::VAPI::Role;
use VTP::Exception;
use VTP::VMGroup;
use VTP::vtpcfg;
use VTP::ShareDiskACL;
use VTP::Numa::NumaHugePageVm;
use VTP::Numa::NumaConf;
use VTP::Numa::NumaOperate;
use VTP::Numa::NumaVmInfo;
use VTP::Numa::NumaClient;
use VTP::SafeSyslog;
use VTP::VMImpExpTools;
use VTP::QemuMigrate;
use VTP::RPCEnvironment;
use VTP::FakeRaid;
use VTP::CmdUtil;
use VTP::Tools;
use VTP::RemoteSupport;
use VTP::ProcFSTools;
use VTP::DRX;
use VTP::AbstractMigrate;
use VTP::IPCC;
use VTP::VMPSN;
use VTP::QemuServer;
use VTP::QMPClient;
use VTP::Plibch;
use VTP::Network::DfwBypass;
use VTP::Network::Route;
use VTP::Network::Topo;
use VTP::Network::Pcap;
use VTP::Network::Plugin;
use VTP::Network::Ippool;
use VTP::Network::Switch;
use VTP::Network::Vlink;
use VTP::Network::Interface;
use VTP::Network::Dfwall;
use VTP::Network::NetCommon;
use VTP::Network::BorderSwitch;
use VTP::Network::Topo::Edge;
use VTP::Network::Topo::Editor;
use VTP::Network::Topo::Node;
use VTP::Ssoproxy;
use VTP::Task;
use VTP::Product;
use VTP::RESTHandler;
use VTP::QemuHugePages;
use VTP::JSONSchema;
use VTP::AuthConfig;
use VTP::Auth::PAM;
use VTP::Auth::VTP;
use VTP::Auth::Plugin;
use VTP::Auth::LDAP;
use VTP::Auth::AD;
use VTP::VAPI;
use VTP::Alert::DoAlert;
use VTP::Alert::MailServer;
use VTP::Alert::Queue;
use VTP::Alert::Client;
use VTP::Alert::Config;
use VTP::RecycleBin;
use VTP::VMInfo;
use VTP::RDMStorage;
use VTP::PodParser;
use VTP::HotplugCfg;
use VTP::QemuCreateGuide;
use VTP::HotplugDevice;
use VTP::Network;
use VTP::AtomicFile;
use VTP::Storage::Plugin;
use VTP::Storage::DiskPlugin;
use VTP::Storage::NFSPlugin;
use VTP::Storage::VTPLVMPlugin;
use VTP::Storage::ISCSIPlugin;
use VTP::Storage::DirPlugin;
use VTP::ParseScanner;
use VTP::VS::VsManage;
use VTP::VS::VsEnvCheck;
use VTP::VS::VsStatus;
use VTP::VS::VsConfig;
use VTP::VS::VsCheck;
use VTP::VS::VsCollectUserInfo;
use VTP::VS::VsSn;
use VTP::Cluster;
use VTP::ResourceLimit;
use VTP::Ads;
use VTP::Chooser;
use VTP::OVAOperate;
use VTP::Cache;
use VTP::DataReport;
use VTP::QemuBackRecovery;
=DRS_head
use VTP::DRS::DRSUserReport;
use VTP::DRS::DRSDataReport;
use VTP::DRS::DRSMigrateRoute;
use VTP::DRS::DRSHostDataCollector;
use VTP::DRS::DRSHtmlReport;
use VTP::DRS::DRSMain;
use VTP::DRS::DRSVmDataCollector;
use VTP::DRS::DRSMigrateRouteScore;
use VTP::DRS::DRSConfig;
use VTP::DRS::DRSCommon;
use VTP::DRS::DRSDataCollector;
use VTP::DRS::DRSMigratePlan;
use VTP::DRS::DRSMigrateSuggestedRoute;
use VTP::DRS::DRSCommunication;
use VTP::DRS::DRSCVmsDataCollector;
use VTP::DRS::DRSHostEstimate;
=cut

use VTP::INotify;
use VTP::MutexVMs;
use VTP::AccessControl;
use VTP::QemuClone;
use VTP::NodeMmComm;
use VTP::PVNetDev;
use VTP::Frontier;
use VTP::VMPTools;
use VTP::USBRedirect;
use VTP::AccessControl::Resource;
use VTP::AccessControl::Group;
use VTP::AccessControl::ACL;
use VTP::SuggestConfig;
#use VTP::CheckItem;
use VTP::SectionConfig;
use VTP::OpLogClient;
use VTP::Common::Process::Manager;
use VTP::Common::Language::Translate;
use VTP::Common::DB::RedisClient;
use VTP::Common::CfgFile;
use VTP::Common::Lock::ParallelLock;
use VTP::Common::Exception;
use VTP::Common::Device::Nbd;
use VTP::Common::vNet::vNetGroup;
use VTP::Common::SerialNumber;
use VTP::Common::VTPHttp;
use VTP::Common::Log;
use VTP::Common::Clean::CleanList;
use VTP::Common::Label;
use VTP::Common::Sys::Cmd;
use VTP::Common::Backup::ImageColdBackup;
use VTP::Common::Backup::ImageBackup;
use VTP::Common::Backup::ImageHotBackup;
use VTP::Common::Backup::ConfBackup;
use VTP::Common::Task::TaskManager;
use VTP::Common::PubFunc;
use VTP::Common::RPC::HTTPServer;
use plog;
#end
#以上代码有脚本生成:collect_use.sh
my $server;
sub server_start {
    eval {
        $server = VTP::Common::RPC::HTTPServer->new(
            methods => {
                'exec_start' => \&exec_start,
                'debug' => \&debug,
            },
            http => {
                LocalPort => 10002,
                LocalAddr => "127.0.0.1",
            },
            max_works => 1,
            max_child_requests => -1,
        );
        $server->startServer();
    };
    if (my $err = vtp_catch($@)) {
        log_error(action => "start", result => "error", err_msg => $err->get_stack());
        die $err->get_info();
    }
}

my $pro_man;
sub exec_start {
    my ($filename, $basename, $cwd, $argv) = @_;
    eval {
        if (!$pro_man) {
            $pro_man = VTP::Common::Process::Manager->new(
                max_works => 100000,
            );
        }
        
        if ($pro_man->isWorkerBusy()) {
            my $max_works = $pro_man->getWorkerCount();
            $pro_man->setMaxWorker($max_works + 100);
        }
        
        log_debug(
            action => "exec_start", 
            result => "filename=$filename,basename=$basename,cwd=$cwd,argv=".Dumper($argv),
        );
        $pro_man->run(
            {
                code => sub {
                    #在子进程关闭server sock，去掉sock继承
                    $server->close();
                    undef $server;
                    
                    $0 = $basename;
                    @ARGV = @$argv;
                    POSIX::setsid();
                    plog::CL_SetAppName($basename);
                    plog::CL_LogUnInit();

                    #修改工作目录，和脚本启动时保持一致
                    chdir($cwd);
                    eval {
                        require $filename;
                    };
                    if (my $e = vtp_catch($@)) {
                        log_error(action => "exec_start", result => "failed", err_msg => $e->get_stack());
                        log_error(action => "exec_start", result => "failed", err_msg => $e->get_info());
                    }
                },
            }
        );
    };
    if (my $e = vtp_catch($@)) {
        log_error(action => "exec_start", result => "failed", err_msg => $e->get_stack());
        return $e->get_info();
    }
    return '';
}

sub debug {
    my ($enable) = @_;
    $server->debug($enable);
}
