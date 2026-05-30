# x-ui 安装脚本

## 简介

精简优化版的 x-ui 安装脚本，移除广告、联系方式等无用内容，增强安全性。

## 安装

```bash
bash <(curl -Ls https://raw.githubusercontent.com/a820820/x-ui/main/install.sh)
```

## 功能

- ✅ 一键安装 x-ui 面板
- ✅ 支持更新、卸载
- ✅ 自定义用户名、密码、端口
- ✅ 支持 IPv4/IPv6 双栈
- ✅ WARP 代理配置
- ✅ BBR 加速安装
- ✅ 证书申请 (ACME)

## 安全加固

| 修复项 | 说明 |
|--------|------|
| `--insecure` 移除 | 启用 SSL 证书验证，防止中间人攻击 |
| 临时文件安全 | `/tmp/crontab.tmp` → `/root/.xui_crontab.tmp`，防止竞态劫持 |
| 广告清除 | 删除联系方式、YouTube 频道、博客等推广内容 |
| 菜单选项 | 移除"使用说明书"选项 (原选项14) |

## 注意事项

- 请使用 **root 权限** 运行
- 安装时自动关闭防火墙 (firewalld/ufw)，请自行配置安全组规则
- 每天凌晨 2:00 自动重启 x-ui 服务（维护连接中断）

## 来源

基于 [yonggekkk/x-ui-yg](https://github.com/yonggekkk/x-ui-yg) 修改

- 原始面板: [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui)
- WARP 脚本: [yonggekkk/warp-yg](https://github.com/yonggekkk/warp-yg)
- ACME 脚本: [yonggekkk/acme-yg](https://github.com/yonggekkk/acme-yg)
