#!/bin/bash

echo "⚠️ 警告：此操作将永久清除 VPS 中的几乎所有数据！"
read -p "你确定要继续吗？(yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "已取消操作。"
    exit 0
fi

echo "🚨 开始清理..."

# 删除除 root 外的所有用户
echo "🧹 删除所有用户..."
for user in $(awk -F: '$3 >= 1000 { print $1 }' /etc/passwd); do
    userdel -r "$user" 2>/dev/null
done

# 清空常见数据目录
echo "🧹 清空 /home /var/www /opt /srv /mnt /root/data..."
rm -rf /home/* /var/www/* /opt/* /srv/* /mnt/* /root/data/*

# 清空 docker
if command -v docker &>/dev/null; then
    echo "🧹 清空 Docker..."
    docker container stop $(docker ps -aq) 2>/dev/null
    docker system prune -af --volumes
    docker network prune -f
fi

# 清除日志和缓存
echo "🧹 清除日志和缓存..."
rm -rf /var/log/* /var/tmp/* /tmp/* /var/cache/apt/*

# 清除 crontab
echo "🧹 清除定时任务..."
crontab -r 2>/dev/null
rm -rf /var/spool/cron/*

# 清除 SSH 授权密钥
echo "🧹 清除 SSH 授权密钥..."
rm -f /root/.ssh/authorized_keys

# 恢复默认 hostname
echo "🧹 重置主机名..."
echo "localhost" > /etc/hostname
hostnamectl set-hostname localhost

# 可选：清空 /etc 下配置文件（危险操作）
# echo "🧹 清空 /etc 部分配置（保留系统文件）..."
# find /etc -mindepth 1 -not -name "passwd" -not -name "group" -not -name "shadow" -not -name "hostname" -exec rm -rf {} +

# 清理完成提示
echo "✅ 清理完成。"

# 可选：自动重启
read -p "是否立即重启？(yes/no): " reboot_confirm
if [[ "$reboot_confirm" == "yes" ]]; then
    reboot
else
    echo "请手动重启 VPS 以完成模拟重装。"
fi
