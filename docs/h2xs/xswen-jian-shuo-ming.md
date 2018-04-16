## 原理简介

.xs文件分为两部分：

1. xs语句：用于声明封装perl接口
2. c代码：用于编写c代码逻辑，提供给xs语句做接口声明

在编译时，xs文件会被展开xs语句，最终被转换为.c文件。再经编译为so库

---

本章节并不覆盖h2xs有关的所有内容，只介绍一些常用示例

## xs语句

xs语句指定封装的接口属性，放在“MODULE = Plibtest        PACKAGE = Plibtest” 之后

* 返回一个值：接口支持一些常规类型，如char \*，即perl语句中传入的标量。 详细参考前面章节提到的文档说明。

```
I32
testfuncxxx(c, str, i, sv)
    char c
    char *str
    I32 i
    SV *sv
CODE:
    int ret = otherfunc(c, str, i, sv);
    if (ret > 10000) {
        XSRETURN_UNDEF;
    }
    RETVAL = ret;
OUTPUT:
    RETVAL
```

说明：本例中XSRETURN\_UNDEF表示返回undef值

* 返回数组

```
void
_load(file)
    char *file
PREINIT:
    char *perror = PERROR_NO;
    HV   *hv     = NULL;
PPCODE:
    EXTEND(SP, 0);
    hv = ini_load(file, &perror);
    if (hv == NULL) {
        logerr("ini_load", "NULL");
        mXPUSHs(&PL_sv_undef);
    } else {
        mXPUSHs(newRV((SV *)hv));
    }
    if (perror) {
        logerr("_load", "perror");
        mXPUSHs(newSVpv(perror, 0));
    }
```

说明：本例中mXPUSHs\(&PL\_sv\_undef\)表示返回一个undef值（不能把NULL当做undef，否则会出core）。

newRV\(\(SV \*\)hv\)是返回hash引用，不能直接返回HV。

---

使用perl数据结构

常用结构：SV、HV、AV

## **接口的参数输入SV**

* 获取字符串：char \* str = SvPV\(sv, len\)

* 获取结构体：struct xxx \*st = \(struct xxx \*\)SvPVbyte\(sv, len\);

```
inline static stcs_h *sv_to_stcs_h(SV *h_sv)
{
    if (h_sv) {
        STRLEN len = 0;
        stcs_h **h  = NULL;
        if (SvPOK(h_sv) || SvPOKp(h_sv)) {
            h = (stcs_h **)SvPVbyte(h_sv, len);
            if (h && len == sizeof(stcs_h *)) {
                return *h;
            }
            logerrf("SvPVbyte failed", "len=%ld", len);
        }

        //logerrf("SvPOK failed");
    }
    return NULL;
}
```

* 使用建议：

* 尽量使用SvPVbyte， 这个只针对内存字节数而言的，而SvPV可能将字符串中的特殊字符进行转义。

* 判断需要加上SvPOK\(h\_sv\) \|\| SvPOKp\(h\_sv\)，以确认是sv标量，另，不能只判断SvPOK，perl中sv标量具有public和private属性。在运行环境中，标量可能呈现private属性，此时调用接口，SvPOK就判断为false，而SvPOKp为true。

## **返回值**

* 返回undef：

* 在xs语句中XSRETURN\_UNDEF

* SV \*svundef = newSV\(0\); RETVAL=sv\_undef

* 返回SV标量：

```
SV *sv = newSVpv(str, 0);

RETVAL = sv;
```

* 返回HV：

```
HV *hash = (HV *)sv_2mortal((SV *)newHV());
RETVAL = hash;
```

## 其它操作

* hash中嵌入hash：

```
...hash 是HV *变量
HV *hsec = (HV *)sv_2mortal((SV *)newHV());

if (!hsec) {
    return NULL;
}

SV *rv = newRV((SV *)hsec);
const char * key = "test";
if (!hv_store(hash, key, strlen(key), rv, 0)) {
    SvREFCNT_dec(rv);
    hv_undef(hsec);
    return NULL;
}
```

* 减少内存占用：

```
...sv是SV*变量
RETVAL = newRV((SV *)sv_2mortal(sv))
```

注：如果直接返回hv或者sv，在超过作用域后，内存不会立即释放，这会导致内存占用。使用sv\_2mortal是延迟释放sv的内存占用，在超过作用域时，会自动释放。

## 扩展

perl支持直接在perl语言中操作结构体，即pack/unpack，详见：https://perldoc.perl.org/functions/pack.html

有时候，利用这个特性，能和h2xs更好配合使用

