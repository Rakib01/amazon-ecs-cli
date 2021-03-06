#!/bin/bash
# Copyright 2015-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the
# "License"). You may not use this file except in compliance
#  with the License. A copy of the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and
# limitations under the License.

export VERSION=$(cat $(dirname "${0}")/../VERSION)

export ARTIFACT_TAG_LATEST="latest"
export ARTIFACT_TAG_SHA=$(git rev-parse --short=7 HEAD)
export ARTIFACT_TAG_VERSION="v${VERSION}"


dexec() {
	if ${DRYRUN} ; then
		echo "DRYRUN: ${@}" 1>&2
	else
		echo "RUNNING: ${@}" 1>&2
		"${@}"
	fi
}

check_md5() {
	test_md5="$(md5sum ${1} | sed 's/ .*//')"
	expected_md5="$(cat ${2})"
	if [ ! "${test_md5}" = "${expected_md5}" ]; then
		echo "Computed md5sum ${test_md5} did not match expected md5sum ${expected_md5}"
		return $(false)
	fi
	return $(true)
}

s3_cp() {
	profile=""
	if [[ ! -z "${AWS_PROFILE}" ]]; then
		profile="--profile=${AWS_PROFILE}"
	fi
	acl="public-read"
	if [[ ! -z "${S3_ACL_OVERRIDE}" ]]; then
		acl="${S3_ACL_OVERRIDE}"
	fi
	echo "Copying ${1} to ${2}"
	aws ${profile} s3 cp "${1}" "${2}" "--acl=${acl}"
}

s3_pull_push() {
	profile=""
	if [[ ! -z "${AWS_PROFILE}" ]]; then
		profile="--profile=${AWS_PROFILE}"
	fi
	if [[ ! -z "${AWS_PROFILE_PUSH}" ]]; then
		profile_push="--profile=${AWS_PROFILE_PUSH}"
	else
		profile_push=$profile
	fi
	acl="public-read"
	if [[ ! -z "${S3_ACL_OVERRIDE}" ]]; then
		acl="${S3_ACL_OVERRIDE}"
	fi
	echo "Copying ${1} to ${2}"
	# for partitioned regions, we cannot copy files between buckets directly. Save it locally and copy it over
	tmp=$(mktemp)
	aws ${profile} s3 cp "${1}" "${tmp}"
	aws ${profile_push} s3 cp "${tmp}" "${2}" "--acl=${acl}"
	rm $tmp
}
