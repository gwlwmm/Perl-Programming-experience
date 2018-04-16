DBIx是perl操作数据库的一个开源库，支持多种数据库，例如sqlite。DBIx由多个类组成，使用过程：

假设当前工作目录是rootdir

* 建立数据表对应的class

建立rootdir/SchemaExample/Result/User.pm

```
package SchemaExample::Result::User;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('user');
__PACKAGE__->add_columns(
    id   => {data_type => 'INTEGER'},
    name => {data_type => 'TEXT', is_nullable => 0}
};
__PACKAGE__->set_primary_key('id');
1
```

* 用DBIx::Class::Schema连接数据库

```
package SchemaExample;
use strict;
use warnings;
use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_classes(qw/Result::User/);
1

#参数参看开源库文档说明
my $schema = SchemaExample->connect("dbi:SQLite:/home/db/test.db",
    undef, undef, undef,
    {
        on_connect_do => [
            'PRAGMA cache_size = 20000',
            'pragma page_size = 4096',
            'pragma synchronous = 0',
            'pragma journal_mode = OFF',
            'pragma temp_store = 2',
        ]
    });
```

* 执行数据库语句（例如优化数据库配置）

```
$schema->storage->dbh_do(
    sub {
        my ($storage, $dbh, @args) = @_;
        $dbh->do("CREATE TABLE if not exists user (id INTEGER PRIMARY KEY, name TEXT NOT NULL)");
    }
);
```

* 构造查询器

```
my $rs = $schema->resultset('user');
```

* 构造查询条件

```
my $new_rs = $rs->search_rs(条件, 选项);
```

* 示例

```
my $hash = {
    name => 'test1'
};
my $cd   = $rs->create($hash);
my $id   = $cd->id;
my $name = $cd->name;
```

```
my $hash = {
    name => 'test2'
};
my $cond = {
    name => 'test1'
};
my $new_rs = $rs->search_rs($cond);
$new_rs->update($hash);
```

```
my $cond = {
    name => 'test1'
};
my $new_rs = $rs->search_rs($cond);
my $cd     = $new_rs->first;
my $id     = $cd->id;
```

```
my $cond = {
    id => [-and => {'>=', 1}, {'<=', 100}]
};
my $option = {
    rows => 10,
    pages => 2
};
my $new_rs = $rs->search_rs($cond, $option);
my @cds = $new_rs->all();
foreach my $cd (@cds) {
    my $name = $cd->name;
    ...
}
```

注：search\_rs只是封装了查询结构，并不会执行查询，因此一个new\_rs可以被保存，需要查询时再执行$new\_rs-&gt;all等操作。

**如要深入了解DBIx，请仔细阅读以下内容**：

[http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class.pod](http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class.pod)

[http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/Relationship.pm](http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/Relationship.pm)

[http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/Relationship/Base.pm\#condition](http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/Relationship/Base.pm#condition)

[http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/Schema.pm\#resultset](http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/Schema.pm#resultset)

[http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/Schema.pm](http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/Schema.pm)

[http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/ResultSet.pm\#join](http://search.cpan.org/~ribasushi/DBIx-Class-0.082841/lib/DBIx/Class/ResultSet.pm#join)

[http://search.cpan.org/~ilmari/SQL-Abstract-1.84/lib/SQL/Abstract.pm](http://search.cpan.org/~ilmari/SQL-Abstract-1.84/lib/SQL/Abstract.pm)

**编码技巧**：在写查询语句时，最好实测，例如查询sqlite3数据库，可以使用sqlite3命令行构造数据，并按照查询预想查询结果。

再对比DBIx的查询结果，以便检查DBIx的代码是否写的正确。

