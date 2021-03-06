#!/bin/sh

PWD=$( pwd )

LOCK_FILE=$PWD/deploy.lock

if [ -f ${LOCK_FILE} ]; then
  echo ''
  echo 'ABORT! There is an ongoing deploy!'
  echo ''
  echo 'In case you are sure this is a mistake:'
  echo "rm -f $LOCK_FILE"
  echo ''
  exit 0
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_SHA=$(git rev-parse --short HEAD)

#slack notification
webhook_url="https://hooks.slack.com/services/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"
channel="#inspire"
text="deploying $CURRENT_BRANCH ($CURRENT_SHA) to staging"
escapedText=$(echo $text | sed 's/"/\"/g' | sed "s/'/\'/g" )
json="{\"channel\": \"$channel\", \"text\": \"$escapedText\"}"


deploy(){

  echo "DEPLOY: sending message to slack channel $channel"
  curl -s -d "payload=$json" "$webhook_url"

  echo 'bundle install'
  bundle install

  echo 'DEPLOY: exec rake assets:clean RAILS_ENV=staging'
  RAILS_ENV=staging bundle exec rake assets:clean

  echo 'DEPLOY: exec rake assets:precompile RAILS_ENV=staging'
  bundle exec rake assets:precompile RAILS_ENV=staging

  echo 'DEPLOY: set the Procfile to the production procfile'
  rm -rf ./Procfile
  cp -rf ./procfile_staging.proc ./Procfile

  echo 'DEPLOY: git commit -m "Update manifest.yml" public/assets/manifest.yml'
  git add --all
  git commit -am "Update manifest.yml"

  echo "DEPLOY: git push origin $CURRENT_BRANCH"
  git push origin $CURRENT_BRANCH

  echo "DEPLOY: git push staging $CURRENT_BRANCH:master --force"
  git push staging $CURRENT_BRANCH:master --force

  echo ''
  echo 'DEPLOY: done'
}

echo ""
echo "This will push to liveinspired-staging.herokuapp.com"
read -p "Deploy $CURRENT_BRANCH to STAGING?[n] (y/n) " RESP
echo ""

if [ "$RESP" = "y" ]; then
  touch $LOCK_FILE
  deploy
  rm -r $LOCK_FILE
else
  echo "Pff... >_>"
fi
