#!/bin/bash -e

# Only run on first Travis-ci job to avoid running for each platform / version
JOB="${TRAVIS_JOB_NUMBER: -1}"
if [ "$JOB.0" != "1.0" ]
then
  return 0
fi

# Settings
REPO_PATH=git@github.com:riban-bw/HelloWorld.git
HTML_PATH=gh-pages
COMMIT_USER="riban-bw"
COMMIT_EMAIL="brian@riban.co.uk"
CHANGESET=$(git rev-parse --verify HEAD)

# Get a clean version of the HTML documentation repo.
rm -rf ${HTML_PATH}
mkdir -p ${HTML_PATH}
git clone -b gh-pages "${REPO_PATH}" --single-branch ${HTML_PATH}

# Create and commit the documentation repo.
cd ${HTML_PATH}

touch $TRAVIS_JOB_NUMBER
echo "<html><head><title>Test page</title></head><body>1. This is build $CHANGESET.</body></html>" > index.html
echo "<html><body>Version $VERSION</body><html>" > "$VERSION.html"
git add .
git config user.name "${COMMIT_USER}"
git config user.email "${COMMIT_EMAIL}"
git commit -m "Automated API documentation build for changeset ${CHANGESET}."
git push origin gh-pages
cd -
