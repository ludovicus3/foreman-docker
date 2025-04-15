#!/bin/bash

set -e

puppet config set hiera_config $HIERACONFIG --section server