# aapanel-bug-fix
some scripts to fix outdates panel version issue


aapanel-nginx-ssl:  
`used to fix aapanel 7.0.25 nginx SSL X509 certificate import error`  

注意事项:  
* 对于较低内存机器，一定要配置swap
* 对于硬盘IO较低并且内存低的机器 (io<1G/s && mem<1G)，尽量不要使用 waf ， task manager 和 statistics 以外的专业版插件，特别是 System hardening, Anti-intrusion。这两个插件会对硬盘持续写入，造成面板持续卡顿。
* 如果使用的是 11.0之后的宝塔面板，一定要关闭 面板空闲休眠。该功能虽然会释放内存，但是对硬盘的压力很高，每次载入面板都需要去硬盘读取。
* 如果在使用soga,可以考虑使用2.12的版本。新版本对硬盘的io也有些要求，不过不多。假设soga在当前目录，使用 `./soga version` 确认当前版本。
