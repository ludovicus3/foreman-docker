#!/bin/bash

set -e

puppet config set environmentpath "${ENVIRONMENT_PATH}" --section server
