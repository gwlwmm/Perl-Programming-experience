查看package的version：perl -e 'use 包;print $包s::VERSION."\n";'

---

\#!/usr/bin/perl

use Crypt::OpenSSL::RSA;

use Crypt::OpenSSL::Bignum;

my $n = Crypt::OpenSSL::Bignum-&gt;new\_from\_hex\(@ARGV\[0\]\);

my $e = Crypt::OpenSSL::Bignum-&gt;new\_from\_hex\("010001"\);

my $rsa\_pubkey = Crypt::OpenSSL::RSA-&gt;new\_key\_from\_parameters\($n, $e\);

print "Public Key : \n".$rsa\_pubkey-&gt;get\_public\_key\_x509\_string\(\);

print "Private Key : \n".$rsa\_pubkey-&gt;get\_private\_key\_string\(\);

---

\#!/usr/bin/perl

use Crypt::OpenSSL::X509;

my $x509 = Crypt::OpenSSL::X509-&gt;new\_from\_file\('a.crt'\);

print $x509-&gt;pubkey\(\)."\n";

---

python调用perl：[http://search.cpan.org/dist/pyperl/perlmodule.pod](http://search.cpan.org/dist/pyperl/perlmodule.pod)

perl调用python：[https://metacpan.org/pod/distribution/Inline-Python/Python.pod](https://metacpan.org/pod/distribution/Inline-Python/Python.pod)

---

文件锁

```
my $fd;

if (!open($fd, "$lock_file")) {

    vtp_throw("open $lock_file failed:$!");

}

if (!flock($fd, LOCK_EX | LOCK_NB)) {

    flock($fd, LOCK_EX);

flock($fd, LOCK_UN);

    close($fd);
```



