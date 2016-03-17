## Summary

系统需要使用 Python 生成 LUA 代码，进行实际的数据处理

## Install

安装 Python 的依赖关系
pip install -r requirements.txt

安装 luajit
>
    wget -c http://luajit.org/download/LuaJIT-2.0.4.tar.gz

安装 lua 的依赖关系
>
    wget -c http://keplerproject.github.io/luarocks/releases/luarocks-2.3.0.tar.gz
    tar xzfv luarocks-2.3.0.tar.gz
    ./configure
    make
    sudo make install

luarocks install lrexlib-PCRE

