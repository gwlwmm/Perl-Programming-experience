# h2xs\_module\_install

```
#!/bin/bash

function log_cmd()
{
    cmd=$1
    echo "******************************************"
    echo $cmd
    $cmd || (echo "$1 failed" && exit 1)
}
function makefile()
{
    DestDir=$1
    INSTALL_BASE=/usr
    if [ ! -z $DestDir ]; then
        INSTALL_BASE=$DestDir/usr
    fi
    log_cmd "perl Makefile.PL INSTALL_BASE=$INSTALL_BASE INSTALLARCHLIB=\$(INSTALL_BASE)/lib/perl5 INSTALLSITEARCH=\$(INSTALL_BASE)/lib/perl5 INSTALLVENDORARCH=\$(INSTALL_BASE)/lib/perl5"

    log_cmd "make"
    if [ -z $DestDir ]; then
        log_cmd "make test"
    fi
    log_cmd "make install UNINST=1"
}
###############################################################################
function print_help()
{
    echo "Usage: $0 -s ./libaaa"
    echo "       $0 -s ./libaaa -d /var/install_tmpdir"
    echo "       -s the package path"
    echo "       -d specify the folder to do a temp install"
}
function main()
{
    if [ $# -eq 0 ]; then
        print_help
        exit 1
    fi

    local ModuleName=
    local DestDir=
    while getopts "s:d:h" arg #选项后面的冒号表示该选项需要参数
    do
        case $arg in
            s)
                ModuleName=$OPTARG
            ;;
            d)
                DestDir=$OPTARG
            ;;
            h)
                print_help
                exit 1
            ;;
            ?) #当有不认识的选项的时候arg为?
                print_help
                exit 1
            ;;
        esac
    done
    if [ -z $ModuleName ]; then
        print_help
        exit 1
    fi

    cd $ModuleName
    if [ -f "Makefile.PL" ]; then
        makefile $DestDir
    else
        echo "该安装包不正确，缺少Makefile.PL"
    fi
    cd -
}

main $*
```



