在某些场景下，需要在perl调用一些底层c代码，比如为了提高性能。

perl提供h2xs工具，方便封装c代码为perl接口。大致原理是：h2xs以c代码提供了perl的内部使用的数据结构，并能与c语言支持的类型进行转换，在封装c代码时，允许c代码中使用这些结构，从而实现对接perl接口调用的输入输出。

**参考网址**：

[https://perldoc.perl.org/index-internals.html](https://perldoc.perl.org/index-internals.html)

[https://perldoc.perl.org/perlguts.html](https://perldoc.perl.org/perlguts.html)

[https://perldoc.perl.org/h2xs.html](https://perldoc.perl.org/h2xs.html)

