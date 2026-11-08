cat > /root/fix_aapanel_x509_regex.py <<'PYEOF'
import os, re, shutil, time

ROOT = "/www/server/panel"
FILES = [
    "class/data.py",
    "class/ssl_info.py",
    "class/panelSite.py",
    "class_v2/data_v2.py",
    "class_v2/panel_ssl_v2.py",
    "class_v2/panel_site_v2.py",
]

PAT = re.compile(
    r"(?P<i>[ \t]*)result\['dns'\] = \[\]\n"
    r"(?P=i)for i in range\(x509\.get_extension_count\(\)\):\n"
    r"(?P=i)    s_name = x509\.get_extension\(i\)\n"
    r"(?P=i)    if s_name\.get_short_name\(\) in \[b'subjectAltName', 'subjectAltName'\]:\n"
    r"(?P=i)        s_dns = str\(s_name\)\.split\(','\)\n"
    r"(?P=i)        for d in s_dns:\n"
    r"(?P=i)            result\['dns'\]\.append\(d\.split\(':'\)\[1\]\)\n"
)

def build_repl(m):
    i = m.group("i")
    lines = [
        "# 取可选名称（pyOpenSSL 26+ 已移除 get_extension，改用 cryptography）",
        "result['dns'] = []",
        "try:",
        "    from cryptography import x509 as _cx509",
        "    try:",
        "        _bcert = x509.to_cryptography()",
        "    except Exception:",
        "        from OpenSSL import crypto as _crypto",
        "        _bcert = _cx509.load_pem_x509_certificate(",
        "            _crypto.dump_certificate(_crypto.FILETYPE_PEM, x509))",
        "    _san = _bcert.extensions.get_extension_for_class(",
        "        _cx509.SubjectAlternativeName)",
        "    result['dns'] = [str(_gn.value) for _gn in _san.value]",
        "except Exception:",
        "    pass",
    ]
    return "".join(i + ln + "\n" for ln in lines)

stamp = time.strftime("%Y%m%d-%H%M%S")
changed = 0
for rel in FILES:
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        print("[MISS]", rel); continue
    src = open(p, encoding="utf-8").read()
    new, n = PAT.subn(build_repl, src)
    if n == 0:
        if "改用 cryptography" in src:
            print("[skip]", rel, "已是新代码")
        else:
            print("[WARN]", rel, "未匹配，请人工检查")
        continue
    shutil.copy2(p, p + ".bak2." + stamp)
    open(p, "w", encoding="utf-8").write(new)
    print("[ OK ]", rel, "替换", n, "处")
    changed += 1

print("共修改文件数:", changed)
PYEOF

/www/server/panel/pyenv/bin/python /root/fix_aapanel_x509_regex.py
