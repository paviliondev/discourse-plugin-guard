#!/bin/bash

cd /var/discourse/shared/standalone/discourse-plugin-guard && git pull
yes | /var/discourse/launcher rebuild app
