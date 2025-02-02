#!/usr/bin/env bash

# fail this script immediately if any command fails with a non-zero exit code
set -e
# Treat unset env variables as an error
set -u
# fail on pipeline errors, e.g. when grepping
set -o pipefail

readonly ROOT=".benchmark/benchmarks"
readonly URL="https://opensearch-benchmark-workloads.s3.amazonaws.com/corpora"


# see http://stackoverflow.com/a/246128
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
readonly CURR_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# test number of parameters
if [ $# != 1 ]
then
    echo "Usage: $0 WORKLOAD_NAME"
    exit 1
fi

readonly WORKLOAD=$1

TARGETS=( )

# clone workload descriptions
readonly REPO_TARGET="${ROOT}/workloads/default"
# add to final tar
TARGETS[${#TARGETS[*]}]="${REPO_TARGET}"

if [ ! -d "${HOME}/${REPO_TARGET}" ]
then
    git clone https://github.com/opensearch-project/opensearch-benchmark-workloads.git "${HOME}/${REPO_TARGET}"
fi

# check if the workload actually exists
if [ ! -d "${HOME}/${REPO_TARGET}/${WORKLOAD}" ]
then
    echo "Workload ${WORKLOAD} does not exist in ${HOME}/${REPO_TARGET}."
    exit 1
fi

# download data (unless it exists locally)
readonly FILES=$(cat ${HOME}/${REPO_TARGET}/${WORKLOAD}/files.txt)
for f in ${FILES}; do
    TARGET_ROOT="${ROOT}/data/${WORKLOAD}"
    TARGET_PATH="${TARGET_ROOT}/${f}"
    mkdir -p "${HOME}/${TARGET_ROOT}"
    TARGETS[${#TARGETS[*]}]="${TARGET_PATH}"
    if [ ! -f "${HOME}/${TARGET_PATH}" ]
    then
        curl -o "${HOME}/${TARGET_PATH}" "${URL}/${WORKLOAD}/${f}"
    fi
done

readonly ARCHIVE="benchmark-workload-data-${WORKLOAD}.tar"
# ensure everything is relative to the home directory
# exclude the archive itself to prevent spurious warnings.
tar -C ${HOME} --exclude="${ARCHIVE}" -cf "${ARCHIVE}" ${TARGETS[@]}

echo "Created data for ${WORKLOAD} in ${ARCHIVE}. Next steps:"
echo ""
echo "1. Copy it to the user home directory on the target machine(s)."
echo "2. Extract with tar -xf ${ARCHIVE} (will be extracted to ~/${ROOT})."
