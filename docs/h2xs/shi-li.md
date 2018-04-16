* **step1，执行：h2xs -n Plibtest**

![](/assets/perl-h2xs-step1.png)

* **step2，修改Plibtest.xs文件实现接口**

```
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"
void echo(const char *str)
{
    printf("%s\n", str);
}

MODULE = Plibtest        PACKAGE = Plibtest        
void 
echo(str)
    char *str
PPCODE:
    echo(str);

INCLUDE: const-xs.inc
```

* **step3，编译**

```
cd Plibtest
perl Makefile.PL
make
make install
```

* **step4，调用接口**

```
perl -e 'use Plibtest; Plibtest::echo("it works!");'
```

结果：![](/assets/perl-h2xs-step4.png)

