#!/bin/sh

set -e
set -u

set -x
cd "$(dirname $0)"

tstart="$(date +%s)"
echo "#### Building the upgrobot container"
podman build --timestamp 0 -t upgrobot:latest ..

echo "#### Building the test container"
# TODO Currently the tests are built in, passing as configmaps could be cleaner
podman build --timestamp 0 -t upgrobot-tester:latest .
tbuild="$(date +%s)"

echo "#### Starting the test stack"
podman play kube test-deployment.yaml || (podman play kube test-deployment.yaml --down && podman play kube test-deployment.yaml)
tstackup="$(date +%s)"

echo "#### Following the logs"
podman logs -f upgrobot-test-upgrobot
ttests="$(date +%s)"

success=y
echo "#### Checking the test exit code"
if [ "$(podman inspect upgrobot-test-upgrobot --format='{{.State.ExitCode}}')" -ne 0 ]
then
	success=
fi

echo "#### Removing the stack"
podman play kube test-deployment.yaml --down
ttotal="$(date +%s)"

set +x
echo "#### Finished"
echo "Total time: $((ttotal - tstart)) seconds"
echo "Build time: $((tbuild - tstart)) seconds"
echo "Startup time: $((tstackup - tbuild)) seconds"
echo "Test time: $((ttests - tstackup)) seconds"
if [ -n "$success" ]
then
	echo "#### RUN SUCCEEDED"
	exit 0
else
	echo "#### RUN FAILED"
	exit 1
fi
