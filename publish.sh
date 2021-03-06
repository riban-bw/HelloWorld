#!/bin/bash -e
# Passing '-e' parameter to bash to exit script immediately if any command fails

# Only run on first Travis-CI job to avoid running for each platform / version. Only run for core repository to avoid failure due to wrong encryption keys.
if [ "${TRAVIS_JOB_NUMBER: -1}" != "1" -o "$TRAVIS_REPO_SLUG" != "riban-bw/HelloWorld" ]
then
  echo "Not publishing documentation. Only publish for build 1 of github repository riban-bw/HelloWorld"
  exit 0
fi

# Decrypt ssh key
openssl aes-256-cbc -K "$sshkey" -iv $encrypted_3b52e9352b1f_iv -in travisci_rsa.enc -out  ~/.ssh/id_rsa -d
# openssl aes-256-cbc -K $encrypted_3b52e9352b1f_key -iv $encrypted_3b52e9352b1f_iv -in travisci_rsa.enc -out  ~/.ssh/id_rsa -d
chmod 0600  ~/.ssh/id_rsa

# Settings
REPO_PATH=git@github.com:riban-bw/HelloWorld.git
HTML_PATH=gh-pages
BUILD_PATH="${TRAVIS_BUILD_DIR}"
COMMIT_USER="riban-bw"
COMMIT_EMAIL="brian@riban.co.uk"
CHANGESET=$(git rev-parse --verify HEAD)

# Get a clean version of the HTML documentation repo.
rm -rf ${HTML_PATH}
mkdir -p ${HTML_PATH}
git clone -b gh-pages "${REPO_PATH}" --single-branch ${HTML_PATH}

# rm all the files through git to prevent stale files.
git rm -rf --ignore-unmatch ${HTML_PATH}/api

# Generate the HTML documentation.
echo "Starting doxygen..."
doxygen >doxygen.log 2>error.log
echo "doxygen complete"
NOT_DOCED=`grep "is not documented" error.log | wc -l`
NOT_DOC_MEMBER=`grep "Member.*is not documented" error.log | wc -l`
NOT_DOC_PARAM=`grep "The following parameters of .* are not documented" error.log | wc -l`
DOC_PARAM=`grep "The following parameters of .* are not documented" error.log | awk -F" of " '{ print $2 }' | awk -F" are not documented" '{ print "<li>"$1"</li>" }'` || DOC_PARAM="None"
DOC_ERROR=`grep "is not found in the argument list" error.log | sed "s|$BUILD_PATH/||" | sed 's/</\&lt\;/g' | sed 's/>/\&gt\;/g' | sed 's/^/<li>/' | sed 's/$/<\/li>/'` || DOC_ERROR="None"
DOC_UNSUPPORTED=`grep "Unsupported xml/html tag" error.log | sed "s|$BUILD_PATH/||" | sed 's/</\&lt\;/g' | sed 's/>/\&gt\;/g' | sed 's/^/<li>/' | sed 's/$/<\/li>/'` || DOC_UNSUPPORTED="None"
echo "Creating report"
echo "<html><body><p>There are $NOT_DOCED undocumented elements of which $NOT_DOC_MEMBER are class (or group) member elements.</p><p>The following functions have undocumented parameters (only functions that have some documentation):</p><ul>$DOC_PARAM</ul><p>The following errors in documentation require fixing:</p><ul>$DOC_ERROR</ul><p>The following syntax errors require fixing:</p><ul>$DOC_UNSUPPORTED</ul></body></html>" > "${HTML_PATH}/api/report.html"
echo "Commit API documentation to gh-pages branch"
# Create and commit the documentation repo.
cd ${HTML_PATH}
git add .
git config user.name "${COMMIT_USER}"
git config user.email "${COMMIT_EMAIL}"
# Only push if commit succeeds. This avoids script failing because nothing to commit
git commit -m "Automated API documentation build for changeset ${CHANGESET}." && git push origin gh-pages
cd -
