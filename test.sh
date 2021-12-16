#!/bin/bash

# 创建异常函数
error_exit ()
{
  echo "ERROR: $1 !!" 
  exit 1  
}
success_exit ()
{
   echo "SUCCESSSFUL !!  $1 "
}

# 获取部署名称

deploy_name=""
version=""
namespace=""
while getopts ":i:v:n:" opt
do
   case $opt in
     i)
        echo "the image is $OPTARG"
        deploy_name=$OPTARG 
        ;;
     v)
        echo "the version is $OPTARG"
        version=$OPTARG 
        ;;
     n)
        echo "the namespace is $OPTARG"
        namespace=$OPTARG
        ;;
     ?)
       echo "opt $opt OPT : $OPTARG"
       error_exit "Parameters can only be image 、namespace and version"
       exit 1
       ;;
    esac
done

# echo $deploy_name
# echo $version
# 验证部署名称是否为空
if [ -z $deploy_name ]
then
  error_exit "The deployment name cannot be empty"
fi

# 获取下载的报名前缀
name=${deploy_name#*/}

result=""
while [[ "$result" == "" || -z $result ]]
do
   tmp=${name#*/}
   name=$tmp
   result=$name
done

# 操作helm拉取相对应的部署yaml文件
dir=`cd $(dirname $0)`
if [ -z $namespace ]
then
  echo "the namspece is empty"
  `cd $(dirname $0); helm fetch "$deploy_name" --version $version;`
else
   `cd $(dirname $0); helm fetch "$deploy_name" --version $version -n $namespace;`
fi
` tar -zxvf ${name}*.tgz; rm -fr ${name}*.tgz;`
` chmod -R 777 ${name}* `

success_exit "pull $name success"

# 创建启动文件
uuid=`cat /proc/sys/kernel/random/uuid`
install="\`helm install ${name} ../${name} --set imageTag=${version} --namespace=${namespace}\`"
if [ -z $namespace ]
then
   install="\`helm install ${name} ../${name} --set imageTag=${version}\`"
fi
# echo "install : ${install}"
# echo "uuid : $uuid"
`cd $(dirname $0)/${name}; echo "#!/bin/bash" >> startup.sh`
`cd $(dirname $0)/${name}; echo "${install}" >> startup.sh ;chmod -R 777 startup.sh`

# 创建结束脚本
`cd $(dirname $0)/${name}; echo "#!/bin/bash" >> shutdown.sh`

