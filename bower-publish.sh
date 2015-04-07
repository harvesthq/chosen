#!/bin/sh

CURRENT_BRANCH=`git name-rev --name-only HEAD`

if [ $CURRENT_BRANCH != 'master' ] ; then
  echo "Build not on master. Skipped bower-chosen release"
  exit 0
fi

git config --global user.email "notmyemail@bower-chosen.lol"
git config --global user.name "bower-chosen"

git clone https://pfiller:${GH_TOKEN}@github.com/harvesthq/bower-chosen.git
rm -rf bower-chosen/*
cp public/bower.json public/*.png public/chosen.jquery.js public/chosen.css bower-chosen/
cd bower-chosen

LATEST_VERSION=$(git diff bower.json | grep version | cut -d':' -f2 | cut -d'"' -f2 | tail -1)

if [ -z $LATEST_VERSION ] ; then
  echo "No Chosen version change. Skipped tagging"
else
  echo "Chosen version changed. Tagging version ${LATEST_VERSION}\n"
  git tag -a "v${LATEST_VERSION}" -m "Version ${LATEST_VERSION}"
fi

git remote set-url origin https://pfiller:${GH_TOKEN}@github.com/harvesthq/bower-chosen.git

git add -A
git commit -m "Chosen build to bower-chosen"
git push origin master
git push origin --tags

echo "Chosen published to harvesthq/bower-chosen"
