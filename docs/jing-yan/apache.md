apache是后端接入层服务器，通常perl代码由perl解释器执行，解释器进程和apache是两个独立的进程。如果要实现apache响应请求时执行perl代码，按照常规思路：

1. apache与解释器进程进行跨进程通信。但后端的perl进程需要做到高并发响应能力，因为所有请求都会阻塞在apache与解释器进程之间。
2. apache调用解释器进程执行perl代码。但这中间涉及：启动新进程（解释器进程），以及解析代码，甚至初始化一些数据结构。带来的消耗是很大的。

mod\_perl就能很好的解决apache执行perl代码的问题，mod\_perl以apache模块方式（动态库）封装了perl解释器。允许在apache进程中调用perl解释器。 并且在apache启动时，就调用了一系列初始化行为（包括解析perl代码）。

# 配置**mod\_perl**

apache配置中添加

```
PerlRequire /usr/share/vtp-manager/startup.pl
<Location /vapi/>
        SetHandler perl-script
        PerlHandler REST
</Location>
```

在apache父进程初始化时，会调用startup.pl；当收到请求时，会调用REST::handler函数，参数是请求对象。

参考：[http://perl.apache.org/docs/1.0/guide/](http://perl.apache.org/docs/1.0/guide/debug.html)

