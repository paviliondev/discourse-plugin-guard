#!/bin/sh

cd /var/discourse/shared/standalone/discourse-plugin-guard && git pull
cd /var/discourse && ./launcher rebuild app
