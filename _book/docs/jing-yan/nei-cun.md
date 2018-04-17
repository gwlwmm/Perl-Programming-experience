perl解释器为了提高性能，在内存方面有这样一个规则： 申请的内存，尤其是hash结构， 内存不会释放回操作系统。

会算作perl内存池资源。如果perl代码中加载了某个大的hash结构，会发现该进程的内存增长了很多，且不会减少。

---

# 检测内存占用

* ## 获取所有perl对象的内存占用情况

```
    use Devel::Gladiator qw(walk_arena arena_ref_counts arena_table);
    use Data::Dumper;
    use Devel::Size qw(size total_size);;
    open STDOUT, ">/sf/data/local/gwl/x/vtpdaemon.arena.$$.txt";
    eval { $self->handle_requests(); };
    my $all = walk_arena();
    my $total = 0;
    foreach my $sv ( @$all ) {
        eval {
            my $x = total_size($sv);
            my $xx = Dumper($sv);
            print "live object: $x, $xx\n" if $x > 2048;
            $total += $x;
        };
    }
    print "total_size:$total\n";
```

* ## 测试大hash结构的内存占用问题

读取大hash后，即使解除引用，内存依然不会减少

创建大hash文件：[perl/jing-yan/create-big-json.pl](/perl/jing-yan/create-big-json.pl)

测试读取大hash文件：[perl/jing-yan/perl-memory-test.pl](/perl/jing-yan/perl-memory-test.pl)

---

# 解决内存占用

perl内存占用主要有两个方面：储存代码， 储存数据结构。

* ## 利用COW（copy-on-write）机制解决代码内存占用问题

一个大项目（使用perl），通常有数十万行代码，根据经验：1万行占用2-3MB左右，那么20万行则40-60MB。如果后端有20个进程

则内存占用是800-1200MB，可想而知，随着进程数增多，内存占用叠加增长。

考虑代码占用的内存是不变的，所以可以首先启动一个进程，加载所有代码，其它所有perl进程都从这个进程fork，则代码的内存占用理论上只有40-60MB。

**技术分析**：linux下，COW机制原理是，父进程申请的内存，操作系统的内存管理建立的是父进程虚拟内存（页表）和物理内存页（页框）的关系，当fork子进程时，操作系统仍然为子进程建立映射，因此父子进程共同引用相同页框，只有在修改时，内核才会复制一个页框承载修改的内存。页框是内核维护的，所以无论父子进程最终是否在相同进程组或是否还维持父子关系，对COW机制都毫无影响。

**详情**：[/perl/jing-yan/perl-memory](/perl/jing-yan/perl-memory)

* ## 修改perl内存管理，解决大hash内存占用问题

大hash问题在于每个hash子项，perl都是申请的小块内存，内核提供两种申请内存的方式，brk和mmap，小内存使用brk。

而brk申请的内存，在调用free时，是要看内存栈顶是否有内存被占用，如果有，则不会释放内存（归还操作系统），因此内存并没有归还操作系统。

### **方法一**：尝试修改perl的编译参数，变更内存申请接口

参考[解释器-安装](/perl/jie-shi-qi/an-zhuang.md)中，编译参数Uusemymalloc

### **方法二**：尝试引入gperftool，优化小内存管理

编译解释器时需要连接tcmalloc：

> -Uusemymalloc -Dusethreads -Duselargefiles -Dlibs="**-ltcmalloc\_minimal** -lnsl -ldl -lm -lcrypt -lutil -lpthread -lc -lunwind" -Dccflags="-DDEBIAN -D\_FORTIFY\_SOURCE=2 -g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security  -fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free" -Dldflags="-Wl,-z,relro" -Dlddlflags="-shared -Wl,-z,relro" -Dcccdlflags=-fPIC -Darchname="x86\_64-linux-gnu" -Dprefix=/usr -Dprivlib=/usr/share/perl/5.14 -Darchlib=/usr/lib/perl/5.14 -Dvendorprefix=/usr -Dvendorlib=/usr/share/perl5 -Dvendorarch=/usr/lib/perl5 -Dsiteprefix=/usr/local -Dsitelib=/usr/local/share/perl/5.14.2 -Dsitearch=/usr/local/lib/perl/5.14.2 -Dman1dir=/usr/share/man/man1 -Dman3dir=/usr/share/man/man3 -Dsiteman1dir=/usr/local/man/man1 -Dsiteman3dir=/usr/local/man/man3 -Duse64bitint -Dman1ext=1 -Dman3ext=3perl -Dpager=/usr/bin/sensible-pager -Uafs -Ud\_csh -Ud\_ualarm -Uusesfio -Uusenm -Ui\_libutil -DDEBUGGING=-g -Doptimize=-O2 -Duseshrplib -Dlibperl=libperl.so.5.14.2 -des

注：上述两种方法，笔者尚未验证成功，方法一是官方提供的内存优化方案（perl6解决了内存问题）。方法二主要是tcmalloc未起到小内存管理的作用，需要调brk申请的内存阈值和tcmalloc的小内存阈值。以及修改perl申请内存的尺寸。

