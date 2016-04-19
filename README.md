## Summary

[del]系统需要使用 Python 生成 LUA 代码，进行实际的数据处理[/del]
改为直接生成 LUA 脚本，调用外部程序

## Test

    用法: <bin>, <conf_path> <source_type> <log_file>,  list the source type's execute plan
    eg:
    python generate_lua.py etc access_combined samples/apache                  ok
    python generate_lua.py etc splunkd_access samples/splunkd_access.log    test

    python generate_lua.py etc ActiveDirectory samples/splunk-ad.log      fail   
    把line_breaker:  ([\r\n]+---splunk-admon-end-of-event---\r\n[\r\n]*)  变为 ([\r\n]+---splunk-admon-end-of-event---[\r\n]*) 就可以了,可能该行日志不存在\r\n

    python generate_lua.py etc wmi samples/splunk-wmi.log            ok
    python generate_lua.py etc oneapm samples/oneapm_nginx_access.log   ok
    python generate_lua.py etc catalina samples/catalina          ok

## Install

安装 Python 的依赖关系
pip install -r requirements.txt

安装 luajit
>
    wget -c http://luajit.org/download/LuaJIT-2.0.4.tar.gz
    CFLAGS=-fPIC make
    sudo make install

安装 pcre库
>
    sudo dnf/yum/apt-get install pcre-8.38-7


## Test

假定在 ../LogSample 中存在要分析的日志文件
 python t_extract.py etc access_combined ../LogSample/apache/access_log
 python t_extract.py etc catalina ../LogSample/tomcat/catalina1_part_aa
