perl调试详细文档：[https://perldoc.perl.org/perldebug.html](https://perldoc.perl.org/perldebug.html)

# 常规调试

* ## perl -d 脚本文件

常用调试命令：

n--------------------------------------- 执行到当前作用域下一条语句

s---------------------------------------- 单步执行

b 函数名---------------------------- 给某函数打断点

b 行数-------------------------------- 给某一行打断点

f 文件绝对路径------------------- 跳到某个源文件

c -------------------------------------- 执行到断点或结束

c 行数 ------------------------------ 执行到某一行

p 变量名或表达式 ------------- 输出结果

x 变量名 --------------------------- 输出变量详细信息（通常使用这个命令打印变量）

* ## 在代码中打印信息

use Data::Dumper;

print Dumper\(表达式或变量\); 即可打印信息

打印堆栈

use Carp;

print Carp::longmess\(\);

或

print caller\(0\);

* ## 使用die抛出异常

perl -MDevel::SimpleTrace 脚本文件

当脚本有die抛出时，可捕获到出错堆栈

---

# 高级调试

* ## 动态调试----gdb

出问题时，当perl进程正在运行，重启可能破坏现场，那么就可以借助gdb对perl进行调试：

gdb -p 进程pid

执行perl语句：call Perl\_eval\_pv\(Perl\_get\_context\(\), "my $stack = caller\(0\); print\($stack\);", 0\)

上述语句会打印perl当前调用堆栈

* ## 动态调试-----远程

当需要对一个fork的子进程某个逻辑做调试时，可以使用远程调试

call \(void\*\)Perl\_eval\_pv\(\(void\*\)Perl\_get\_context\(\),"eval{require Enbugger;warn q\(stopping\);$ENV{PERLDB\_OPTS}='RemotePort=localhost:4000';Enbugger-&gt;stop;};print STDERR $@",0\)

需要开一个远程终端监听localhost:4000端口

---

# 参考网址

[https://www.slideshare.net/hirose31/inspect-runningperl](https://www.slideshare.net/hirose31/inspect-runningperl)

[https://metacpan.org/pod/App%3a%3aStacktrace](https://metacpan.org/pod/App%3a%3aStacktrace)

[https://github.com/ahiguti/bulkdbg](https://github.com/ahiguti/bulkdbg)

[http://search.cpan.org/~jjore/Enbugger-2.016/lib/Enbugger.pod](http://search.cpan.org/~jjore/Enbugger-2.016/lib/Enbugger.pod)

[http://search.cpan.org/~shay/mod\_perl-2.0.10/docs/devel/debug/c.pod](http://search.cpan.org/~shay/mod_perl-2.0.10/docs/devel/debug/c.pod)

[http://search.cpan.org/~stas/Debug-FaultAutoBT-0.02/FaultAutoBT.pm](http://search.cpan.org/~stas/Debug-FaultAutoBT-0.02/FaultAutoBT.pm)

[http://search.cpan.org/~jjore/Internals-CountObjects-0.05/lib/Internals/CountObjects.pm](http://search.cpan.org/~jjore/Internals-CountObjects-0.05/lib/Internals/CountObjects.pm)

