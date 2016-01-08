#!/bin/bash -e
# Passing '-e' parameter to bash to exit script immediately if any command fails

# Only run on first Travis-ci job to avoid running for each platform / version
if [ "${TRAVIS_JOB_NUMBER: -1}" != "1" ]
then
  exit 0
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

# rm all the files through git to prevent stale files.
git rm -rf --ignore-unmatch ${HTML_PATH}/api

# Generate the HTML documentation.
echo "Starting doxygen..."
doxygen >doxygen.log 2>error.log

ls
echo "doxygen complete"
NOT_DOCED=`grep "is not documented" error.log | wc -l`
NOT_DOC_MEMBER=`grep "Member.*is not documented" error.log | wc -l`
NOT_DOC_PARAM=`grep "The following parameters of .* are not documented" error.log | wc -l`
echo "Getting undocumented parameters"
DOC_PARAM=`grep "The following parameters of .* are not documented" error.log | awk --field-separator " of " '{ print $2 }' | awk --field-separator " are not documented" '{ print $1"<br/>" }'`
echo "Getting incorrect arguments"
DOC_ERROR=`grep "is not found in the argument list" error.log`
echo "Getting unsuppported tags"
DOC_UNSUPPORTED=`grep "Unsupported xml/html tag" error.log`

echo "<html><body>There are $NOT_DOCED elements not yet documented<br/><br/>There are $NOT_DOC_MEMBER undocumented member elements.<br/>Thefollowing functions have undocumented parameters:<br/>$DOC_PARAM</br>The following errors in dcumentation require fixing:<br/>$DOC_ERROR<br/><br/>$DOC_UNSUPPORTED</body></html>" > ${HTML_PATH}/api/report.html

# Create and commit the documentation repo.
cd ${HTML_PATH}
git add .
git config user.name "${COMMIT_USER}"
git config user.email "${COMMIT_EMAIL}"
# Only push if commit succeeds. This avoids script failing because nothing to commit
git commit -m "Automated API documentation build for changeset ${CHANGESET}." && git push origin gh-pages
cd -
