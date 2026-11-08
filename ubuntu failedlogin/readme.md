pam_exec 复刻 showfailed，完整可执行版

```
sudo tee /usr/local/sbin/login-failed-report >/dev/null <<'EOF'
#!/bin/sh
# pam_exec 以 root 执行：登录会话建立时打印本用户近期失败登录
u="${PAM_USER:-}"
[ -n "$u" ] || exit 0

since="$(date -d '24 hours ago' '+%Y-%m-%d %H:%M:%S')"
rows="$(lastb -w -s "$since" 2>/dev/null | awk -v u="$u" '$1==u')"
n="$(printf '%s\n' "$rows" | grep -c .)"
[ "$n" -gt 0 ] || exit 0

newest="$(printf '%s\n' "$rows" | awk 'NF{print; exit}')"
printf '\n'
printf 'Last failed login: %s\n' "$(printf '%s' "$newest" | cut -c1-76)"
printf 'There were %s failed login attempt(s) for "%s" in the last 24h.\n' "$n" "$u"

if command -v faillock >/dev/null 2>&1; then
    f="$(faillock --user "$u" 2>/dev/null | grep -c ' V ')"
    [ "${f:-0}" -gt 0 ] && printf 'faillock: %s failure(s) currently recorded.\n' "$f"
fi
exit 0
EOF

chmod 0755 /usr/local/sbin/login-failed-report
```

验证：
```
PAM_USER=root /usr/local/sbin/login-failed-report; echo "rc=$?"
lastb -w -s "$(date -d '24 hours ago' '+%Y-%m-%d %H:%M:%S')" | head -5
```

```
# 删掉已失效的两行 pam_lastlog（它们在 login 与 sshd 里，备份成 .bak）
sudo sed -i.bak '/pam_lastlog/d' /etc/pam.d/login /etc/pam.d/sshd

# SSH 会话
echo 'session    optional   pam_exec.so stdout quiet_log /usr/local/sbin/login-failed-report' \
  | sudo tee -a /etc/pam.d/sshd

# 本地 TTY 登录
echo 'session    optional   pam_exec.so stdout quiet_log /usr/local/sbin/login-failed-report' \
  | sudo tee -a /etc/pam.d/login
```



结论：  
Ubuntu 24.04 的 libpam-modules 从发布起就不含 pam_lastlog.so（noble 初始版和 updates 版都没有），/etc/pam.d/* 里那两行是包之间没清理同步的"幽灵配置"，因标了 optional 而静默失效——机器本身没坏，不用再找这个模块。  
落地：用 pam_exec + /usr/local/sbin/login-failed-report 复刻 showfailed，挂到 sshd/login 的 session 段。  

