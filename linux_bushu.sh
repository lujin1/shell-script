#! /bin/sh
# by lujin
# 2017-11-12
# 需要软件包：
# rpm -ivh jdk-8u111-linux-x64.rpm
# apache-tomcat-8.5.4.tar.gz
# auto-del-logfiles.sh

function CiPanGuaZai()
{
db=`ls /dev|grep "db"|wc -l`
dbn=`ls /dev|grep "db"[0-9]"|wc -l`
if [ "$db" -ne "0" ]
then
    echo "有数据盘"
    if [ "$dbn" -ne "0" ]
    then
        echo "已经分区未挂载"
        vdb=`ls /dev|grep "db[0-9]"`
        mkfs.ext4 /dev/$vdb
        UUID=`blkid |grep "db[0-9]"|awk -F ":" '{print $2}'|awk -F "\"" '{print $2}'`
        TYPE=`blkid |grep "db[0-9]"|awk -F ":" '{print $2}'|awk -F "\"" '{print $4}'`
        echo "UUID=$UUID /opt $TYPE defaults,barrier=0 1 1" >> /etc/fstab
        mount -a
    else
        echo "未分区未挂载"
        vdb=`ls /dev|grep "db"`
        echo -e "n\np\n1\n\n\nwq\n" |fdisk /dev/$vdb
        mkfs.ext4 /dev/$vdb
        UUID=`blkid |grep "db[0-9]"|awk -F ":" '{print $2}'|awk -F "\"" '{print $2}'`
        TYPE=`blkid |grep "db[0-9]"|awk -F ":" '{print $2}'|awk -F "\"" '{print $4}'`
        echo "UUID=$UUID /opt $TYPE defaults,barrier=0 1 1" >> /etc/fstab
        mount -a
    fi
else
    echo "无数据盘"
fi
}

function AnZhuangRuanJian()
{
echo "安装LINUX软件"
Rj="lrzsz unar bash-completion"
for i in $Rj
do
    yum -y install $i
done
}

function Mkdir()
{
echo "创建目录"
Dir="tmp logfile  webapps"
for i in $Dir
do
    mkdir -p /opt/$i
done
}

function AnzZhuangJdk()
{
echo "安装 JDK"
rpm -ivh jdk-8u111-linux-x64.rpm
Jdk=`java -version 2>&1 |grep "1.8.0_111"|wc -l`
if [ "$Jdk" -ne "0" ]
then
    echo "安装JDK成功"
else
    echo "安装JDK失败"
    echo "正在退出。。。"
    exit
}

function BuShuTomcat()
{
echo "Tomcat安装配置"
tar -xvf apache-tomcat-8.5.4.tar.gz -C /opt
mv /opt/apache-tomcat-8.5.4 /opt/tomcat

echo "修改目录权限"
chmod 770 -R /opt/tomcat/work
chmod 770 -R /opt/tomcat/temp
chmod 750 -R /opt/tomcat/conf
mkdir -p /opt/tomcat/conf/Catalina
chmod 775 -R /opt/tomcat/conf/Catalina
mkdir /opt/logfiles/tomcat
mkdir /opt/logfiles/tomcat/accessLog
mkdir /opt/logfiles/tomcat/sysLog
mkdir /opt/logfiles/website
chmod -R 775 /opt/logfiles/tomcat

echo "配置setenv"
Mem=`free -gt|grep "Total"|awk '{print $2}'`+1
touch /opt/tomcat/bin/setenv.sh
if [ "$Mem" -eq "8" ]
then
    JAVA_OPTS="-server -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m -Xms4G -Xmx4G -Xmn1G -XX:SurvivorRatio=10 -XX:+UseConcMarkSweepGC -XX:+HeapDumpOnOutOfMemoryError"
else
    JAVA_OPTS="-server -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m -Xms2G -Xmx2G -Xmn512m -XX:SurvivorRatio=10 -XX:+UseConcMarkSweepGC -XX:+HeapDumpOnOutOfMemoryError"
fi
echo $JAVA_OPTS >> /opt/tomcat/bin/setenv.sh
chmod 750 /opt/tomcat/bin/setenv.sh
}

function SheZhiLinux()
{
echo "创建日志删除定时任务"
mkdir /opt/.sh
mv auto-del-logfiles.sh /opt/.sh
chmod +x /opt/.sh/auto-del-logfiles.sh
echo  "0 1 * * * /opt/.sh/auto-del-logfiles.sh" >> /var/spool/cron/root
service crond start
}

# 主程序--main--
CiPanGuaZai
AnZhuangRuanJian
AnzZhuangJdk
BuShuTomcat
SheZhiLinux