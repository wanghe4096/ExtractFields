## Summary

系统需要使用 Python 生成 LUA 代码，进行实际的数据处理

## Install

安装 Python 的依赖关系
pip install -r requirements.txt

安装 luajit
>
    wget -c http://luajit.org/download/LuaJIT-2.0.4.tar.gz
    CFLAGS=-fPIC make
    sudo make install

安装 lua 的依赖关系
>
    wget -c http://keplerproject.github.io/luarocks/releases/luarocks-2.3.0.tar.gz
    tar xzfv luarocks-2.3.0.tar.gz
    ./configure
    make
    sudo make install

luarocks install lrexlib-PCRE


## Test

假定在 ../LogSample 中存在要分析的日志文件
 python t_extract.py etc access_combined ../LogSample/apache/access_log
 python t_extract.py etc catalina ../LogSample/tomcat/catalina1_part_aa