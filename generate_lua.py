# -*- coding: utf-8 -*-
"""
    测试　日志文件　解析
  
    用法: <bin>, <conf_path> <source_type> <log_file>,  list the source type's execute plan
    python generate_lua.py etc access_combined samples/apache

"""

import os
import sys
import re,time
import spl_common
from distutils.util import strtobool
from jinja2 import Environment, FileSystemLoader

stanza_re = re.compile('\[\[([a-zA-z0-9\-:]*?)\]\]')

def build_normal_regex(regex_expr, transforms, name_group_prefix=''):
    """
        convert to normal regex via transform rules
    """

    rv = regex_expr
    convert_map = {}
    for match in stanza_re.finditer(regex_expr):
        expr = match.group(1)
        toks = expr.split(':')
        expr_name = '_'
        if len(toks) == 1:
            stanza_name = toks[0]
        if len(toks) == 2:
            stanza_name, expr_name = toks
        if len(toks) > 2:
            print 'unknown stanze format %s'% expr
            exit(-1)

        if True:
            transform_define = transforms[stanza_name]
            regex_expr = transform_define['REGEX'].replace('/','\/')
            print expr_name,stanza_name,regex_expr
            if expr_name == '_':
                regex_prefix = name_group_prefix
            else:
                if name_group_prefix:
                    regex_prefix = name_group_prefix + "_" + expr_name + "_"
                else:
                    regex_prefix = expr_name + "_"

            regex_normal_expr = build_normal_regex(regex_expr, transforms, regex_prefix)

            regex_normal_expr = re.sub(r'\?\<(\w+)\>', r'?<%s\1>' % regex_prefix, regex_normal_expr)

            if expr_name == '_':
                convert_map[expr] = "(?:%s)" % regex_normal_expr
            else:
                if regex_normal_expr.find('?<>') != -1:
                    convert_map[expr] = regex_normal_expr.replace('?<>', "?<%s>" % expr_name)
                else:
                    convert_map[expr] = "(?<%s>%s)" % (expr_name, regex_normal_expr)

    for k, v in convert_map.items():
        rv = rv.replace("[[%s]]" % k, v)
    return rv


class DataProcessor(object):
    """
        - 加载数据的处理流程
    """
    def __init__(self, props, transforms):
        self._props = props
        self._transforms = transforms
        self.step_reports = []
        self.step_transform = []
        self.step_extract = []

    def add_report(self, step_name):
        self.step_reports.append(step_name)

    def add_transform(self, step_name):
        self.step_transform.append(step_name)

    def add_extract(self, step_name):
        self.step_extract.append(step_name)

    def get_full_regex(self, step_name, escape=False):
        """
            取得当前表达式的完整形式， 以及包括的 named_group
        """
        transform_define = transforms[step_name]
        regex_expr = transform_define['REGEX']
        rv = build_normal_regex(regex_expr, transforms)
        if escape:
            return rv.replace("\\", "\\\\").replace('\"', '\\"')
        else:
            return rv 

    def get_names(self, step_name):
        transform_define = transforms[step_name]
        regex_expr = transform_define['REGEX']
        rv = build_normal_regex(regex_expr, transforms)
        name = re.findall('\?\<([a-zA-Z_]+?)\>',rv)
        names = list()
        for n in name:
            names.append('\'' + n + '\'')
        return '{' + ','.join(names) + '}'

    def get_names_count(self, step_name):
        transform_define = transforms[step_name]
        regex_expr = transform_define['REGEX']
        rv = build_normal_regex(regex_expr, transforms)
        name = re.findall('\?\<([a-zA-Z_]+?)\>',rv)
        return len(name)


def extract(source_type, props, transforms, log_file):
    """
     1 compile to LUA code via jinja2 template
     2 execute the lua code, strip struct code.
    """
    if source_type not in props:
        print 'source %s not found' % source_type
        exit(-1)

    env = Environment(loader=FileSystemLoader('templates'))
    template = env.get_template('extract.lua')
    namestype_template = env.get_template('sourcetype_namestype.conf')

    max_events = int(props[source_type].get('MAX_EVENTS', props['default'].get('MAX_EVENTS', 250)))
    line_merge = props[source_type].get('SHOULD_LINEMERGE', props['default'].get('SHOULD_LINEMERGE', 'True'))
    line_merge = strtobool(line_merge)
    line_breaker = props[source_type].get('LINE_BREAKER', props['default'].get('LINE_BREAKER', '([\\r\\n]+)'))
    default_line_breaker = line_breaker in ['([\\r\\n]+)', '[\\r\\n]+']

    options = {
        'default_linebreaker': default_line_breaker,
        'custom_linebreaker': not default_line_breaker,
        'linebreaker_regex': line_breaker,
        'multiline': line_merge and True
    }

    processor = DataProcessor(props, transforms)
    for k, v in props[source_type].items():
        if k.startswith('REPORT-'):
            transform_stanza_list = v.split(',')
            for transform_stanza in transform_stanza_list:
                processor.add_report(transform_stanza)

        if k.startswith('TRANSFORMS-'):
            transform_stanza_list = v.split(',')
            for transform_stanza in transform_stanza_list:
                processor.add_transform(transform_stanza)

        if k.startswith('EXTRACT-'):
            rules = v.split(' in ')
            if rules > 1:
                reg_expr = rules[0]
                reg_field = rules[1]
            else:
                reg_expr = rules[0]
                reg_field = '_raw'
            print 'value:\t', reg_expr, '->', reg_field
    
    namestype = {}
    fnamestype = "namestype/%s.conf" %source_type
    if os.path.isfile(fnamestype):
        namestype = spl_common.readConfFile(fnamestype)
    else:
        sourcetype_namestype_generated = namestype_template.render(processor=processor,sourcetype=source_type)
        with open(fnamestype, 'w') as fh:
            fh.write(sourcetype_namestype_generated)
        print('please setting ' + fnamestype + ' fields type!!!')
        exit(-1)
    
    fgenerate_lua = "sourcetype_lua/%s.lua" % source_type
    if ''.join(namestype[source_type].values()) or not namestype[source_type]:
        namestype_list = list()
        for k,v in namestype[source_type].items():
            namestype_list.append(k+'=\''+v+'\'')
        namestype_string = '{' + ','.join(namestype_list) + '}'
        lua_code_generated = template.render(processor=processor,sourcetype=source_type,namestype=namestype_string, max_events=max_events, options=options)
        
        with open(fgenerate_lua, 'w') as fh:
            fh.write(lua_code_generated)
    else:
        print('please setting ' + fnamestype + ' fields type!!!')
        exit(-1)

    try:
        os.system("wc -l %s" % (log_file))
        timebegin = time.time()
        os.system("luajit %s %s" % (fgenerate_lua, log_file))
        timeend = time.time()
        times = timeend - timebegin
        print 'times:',times
    finally:
        #os.remove(fgenerate_lua)
        pass

if __name__ == '__main__':

    fpath = sys.argv[1]

    conf_path = os.path.join(fpath, 'system', 'default')
    fname_props = os.path.join(conf_path, 'props.conf')
    fname_transform = os.path.join(conf_path, 'transforms.conf')

    # load
    if os.path.isfile(fname_props):
        props = spl_common.readConfFile(fname_props)
        transforms = spl_common.readConfFile(fname_transform)
    else:
        print "can not read from config path %s " % fname_props
        exit(-1)

    if len(sys.argv) == 4:
        source_type = sys.argv[2]
        log_file = sys.argv[3]
        extract(source_type, props, transforms, log_file)

# end of file