#!/bin/sh

CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

if [ $CURRENT_BRANCH != 'master' ] ; then
  exit 0
fi

git clone https://pfiller:${GH_TOKEN}@github.com/harvesthq/bower-chosen.git
rm -rf bower-chosen/*
cp public/bower.json public/*.png public/chosen.jquery.min.js public/chosen.min.css bower-chosen/
cd bower-chosen


LATEST_VERSION=$(git diff bower.json | grep version | cut -d':' -f2 | cut -d'"' -f2 | tail -1)

if [ ! -z $LATEST_VERSION ] ; then
  echo "Tagging version ${LATEST_VERSION}\n"
  git tag -a "v${LATEST_VERSION}" -m "Version ${LATEST_VERSION}"
fi

git remote set-url origin https://pfiller:${GH_TOKEN}@github.com/harvesthq/bower-chosen.git
git add -A
git commit -m "Chosen build to bower-chosen"
git push origin master
git push origin --tags

echo "Done with science"
