cd /www/server/panel

# 语法检查
for f in class/data.py class/ssl_info.py class/panelSite.py \
         class_v2/data_v2.py class_v2/panel_ssl_v2.py class_v2/panel_site_v2.py; do
  /www/server/panel/pyenv/bin/python -m py_compile "$f" && echo "OK  $f"
done

# 确认 get_extension( 只剩注释
grep -rn "get_extension(" /www/server/panel --include="*.py" | grep -v /pyenv/
# 预期只看到 panelSSL.py:1310 和 mod/base/web_conf/ssl.py:217 两条注释

grep -n "改用 cryptography" class/ssl_info.py

bt restart


