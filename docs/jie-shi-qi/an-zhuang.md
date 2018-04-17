# 解释器安装

* ## 下载perl解释器源码

[http://www.cpan.org/src/README.html](http://www.cpan.org/src/README.html)

* ## 解压后查看INSTALL（耐心阅读）
* ## 根据参数说明，指定配置参数

> ./Configure -Dinstallusrbinperl -Dusethreads -Duselargefiles -Dccflags="-DDEBIAN -D\_FORTIFY\_SOURCE=2 -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Dldflags= -Wl,-z,relro -Dlddlflags=-shared -Wl,-z,relro" -Dcccdlflags=-fPIC -Darchname=x86\_64-linux-gnu -Dprefix=/usr -Dprivlib=/usr/share/perl/5.14 -Darchlib=/usr/lib/perl/5.14 -Dvendorprefix=/usr -Dvendorlib=/usr/share/perl5 -Dvendorarch=/usr/lib/perl5 -Dsiteprefix=/usr/local -Dsitelib=/usr/local/share/perl/5.14.2 -Dsitearch=/usr/local/lib/perl/5.14.2 -Dman1dir=/usr/share/man/man1 -Dman3dir=/usr/share/man/man3 -Dsiteman1dir=/usr/local/man/man1 -Dsiteman3dir=/usr/local/man/man3 -Duse64bitint -Dman1ext=1 -Dman3ext=3perl -Dpager=/usr/bin/sensible-pager -Uafs -Ud\_csh -Ud\_ualarm -Uusesfio -Uusenm -Ui\_libutil -DDEBUGGING=-g -Doptimize=-O2 -Duseshrplib -Dlibperl=libperl.so.5.14.2 -des

make install

或者

make install DESTDIR=/home/myroot （安装到临时目录）

* ## 查看环境已有的解释器编译参数

perl -V:config\_args

