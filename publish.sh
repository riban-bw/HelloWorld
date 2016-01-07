#!/bin/bash -e

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

# Check if this revision has already been documented by another (matrix) build
echo "Build ID: $TRAVIS_BUILD_ID" >> TRAVIS_JOB_NUMBER.txt
echo "Build number: $TRAVIS_BUILD_NUMBER" >> TRAVIS_JOB_NUMBER.txt
echo "Job ID: $TRAVIS_JOB_ID" >> TRAVIS_JOB_NUMBER.txt

echo "<html><head><title>Test page</title></head><body>1. This is build $CHANGESET.</body></html>" > index.html
echo "<html><body>Version $VERSION</body><html>" > "$VERSION.html"
git add .
git config user.name "${COMMIT_USER}"
git config user.email "${COMMIT_EMAIL}"
git commit -m "Automated API documentation build for changeset ${CHANGESET}."
git push origin gh-pages
cd -
