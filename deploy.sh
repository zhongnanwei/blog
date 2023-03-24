#!/usr/bin/env sh

# 确保脚本抛出遇到的错误
set -e


# push_addr=`git remote get-url --push origin` # git提交地址，也可以手动设置，比如：
push_addr=https://github.com/zhongnanwei/zhongnanwei.github.io.git
commit_info=`git describe --all --always --long`
dist_path=docs/.vuepress/dist/ # 打包生成的文件夹路径
push_branch=gh-pages # 推送的分支

# 生成静态文件
# npm run build

# 进入生成的文件夹
cd docs/.vuepress/dist/
git remote remove origin
git remote add origin https://github.com/zhongnanwei/zhongnanwei.github.io.git

git add . 
git commit -m "deploy, $commit_info"
git push --set-upstream origin main --force

cd -
rm -rf $dist_path
