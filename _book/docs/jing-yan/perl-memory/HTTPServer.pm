#** @file
# @file
# @author gwl
# @date 2016/11/2
# @note 是用HTTP当做RCP，对Frontier::RPC2的封装
#*
package VTP::Common::RPC::HTTPServer;

use strict;
use warnings;
use Frontier::RPC2;
use HTTP::Daemon;
use HTTP::Status;
use VTP::Common::Process::Manager;
use VTP::Common::Log;
use Time::HiRes;

#** @method public new()
# @param http (HASH) 参考HTTP::Daemon的new参数
# @param method (HASH) 方法映射，格式：方法名 => 方法处理函数
# @param max_works (int) work数量，server将启动max_works个子进程处理事务
# @param max_child_requests (int) 单个子进程处理多少个请求（达到最大值后将结束进程重新建立新进程），非正数表示无限大
# @return 对象引用
#*
sub new {
    my ($class, %args) = @_;

    #reset the parameter of http server
    $args{http}->{Timeout}   ||= 5;
    $args{http}->{LocalAddr} ||= "0.0.0.0";
    $args{http}->{LocalPort} ||= "10000";
    $args{http}->{ReuseAddr} = 1;

    #$args{http}->{ReusePort} = 1;
    $args{http}->{Listen} ||= 20;
    my $http_server = HTTP::Daemon->new(%{$args{http}});
    my $self = {
        max_works          => $args{max_works}          || 3,
        max_child_requests => $args{max_child_requests} || 1000,
        http_server        => $http_server,
        enable_debug       => 0,
    };
    $self->{methods}  = $args{'methods'};
    $self->{decode}   = new Frontier::RPC2 'use_objects' => $args{'use_objects'};
    $self->{response} = new HTTP::Response 200;
    $self->{response}->header('Content-Type' => 'text/xml');

    log_debug(
        action  => "RPC::HTTPServer new",
        result  => "ok",
        err_msg => "ip=" . $args{http}->{LocalAddr} . ", port=" . $args{http}->{LocalPort}
    );

    return bless $self, $class;
}

#** @method private _httpWorkerFunc()
# @brief 子进程的处理函数
#*
sub _httpWorkerFunc {
    my ($self)             = @_;
    my $http_server        = $self->{http_server};
    my $max_child_requests = $self->{max_child_requests};
    
    my $time_accept = 0;
    my $time_req = 0;
    my $time_dispatch = 0;

    #非正数表示无限大
    $max_child_requests = -1 if $max_child_requests <= 0;
    while ($max_child_requests != 0) {
        $time_accept = Time::HiRes::time()
            if ($self->{enable_debug});
        
        my $conn = $http_server->accept();
        next if !$conn;
        
        $time_accept = (Time::HiRes::time() - $time_accept) * 1000
            if ($self->{enable_debug});
        $time_req = Time::HiRes::time()
            if ($self->{enable_debug});

        my $rq = $conn->get_request();
        $time_req = (Time::HiRes::time() - $time_req) * 1000
            if ($self->{enable_debug});

        if ($rq) {
            $time_dispatch = Time::HiRes::time()
                if ($self->{enable_debug});
            if ($rq->method eq 'POST' && $rq->url->path eq '/RPC2') {
                $self->{response}->content($self->{decode}->serve($rq->content, $self->{methods}));
                $conn->send_response($self->{response});
            } else {
                $conn->send_error(RC_FORBIDDEN);
            }
            $time_dispatch = (Time::HiRes::time() - $time_dispatch) * 1000
                if ($self->{enable_debug});
        }
        $conn->close;
        $conn = undef;
        $max_child_requests-- if $max_child_requests > 0;
        log_debug(
            action => "TimeProf",
            result => "accept:$time_accept(ms),request:$time_req(ms),dispatch:$time_dispatch(ms)",
        );
    }
}

#** @method public startServer()
# @brief 启动服务器，永久保持max_works个子进程在处理，挂掉即重启
#*
sub startServer {
    my ($self) = @_;

    my $worker_man = VTP::Common::Process::Manager->new(
        max_works => $self->{max_works},
        prctl     => 1,
    );
    log_debug(action => "RPC::HTTPServer", result => "start");
    while (1) {
        if ($worker_man->isWorkerBusy()) {
            sleep(5);
            next;
        }
        last if ($worker_man->isStopped());
        $worker_man->run(
            {
                code => sub {
                    eval { $self->_httpWorkerFunc(); };
                    if ($@) {
                        log_error(action => "_httpWorkerFunc", result => "error", err_msg => "$@");
                    }
                }
            }
        );
    }
    log_debug(action => "RPC::HTTPServer", result => "stop");
}

#** @method public close()
# @brief 关闭server
#*
sub close {
    my ($self) = @_;
    $self->{http_server}->close();
}

#** @method public debug()
# @brief 调试开关
# @param enable 为真表示开启调试日志，否则关闭调试日志
#*
sub debug {
    my ($self, $enable) = @_;
    $self->{enable_debug} = $enable;
}

1;
