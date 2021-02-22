#强制推送
###
 # @Description:
 # @version: 1.0.0
 # @Author: peng2.zhang
 # @Date: 2021-02-22 10:55:35
 # @LastEditors: peng2.zhang
 # @LastEditTime: 2021-02-22 17:08:18
###
#!/usr/bin/env bash
set -e
npm run build
cd dist
touch .nojekyll
git init
git add -A
git commit -m 'deploy'
git push -f "https://${access_token}@gitee.com/chu1204505056/vue-admin-beautiful.git" master:gh-pages
git push -f "https://${access_token}@gitee.com/chu1204505056/vue-admin-beautiful-element.git" master:gh-pages
start "https://gitee.com/chu1204505056/vue-admin-beautiful/pages"
start "https://gitee.com/chu1204505056/vue-admin-beautiful-element/pages"
git push -f "https://${access_token}@github.com/chuzhixin/vue-admin-beautiful.git" master:gh-pages
cd -
exec /bin/bash




