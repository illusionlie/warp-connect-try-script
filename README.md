# WARP Connect Try Script
这是一个用于尝试在国内通常网络环境下连接到WARP的Windows批处理脚本  
使用比较 **~~玄学的方法~~** ,其中测试端点的代码来自我的 [这个脚本](https://github.com/illusionlie/warp-ip-auto-preference-script)

## 免责声明
这个脚本仅在我的个人计算机上进行过测试  
这个脚本仅供测试并且不一定照常工作

## 警告
警告, 本脚本将会:
 * 提权自身
 * 从远程下载所需文件
 * 在运行时关闭防火墙 (脚本关闭后打开)
 * 记录日志 (日志记录对系统无影响, 但仍然可以关闭)
 * 发起大量网络请求 (用于测试端点)
 * 通过ipconfig刷新DNS缓存
