#!/bin/bash

cd /var/discourse/shared/standalone/discourse-plugin-guard && git pull
/var/discourse/launcher rebuild app
