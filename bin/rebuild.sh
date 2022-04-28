#!/bin/bash

yes | /var/discourse/launcher cleanup
/var/discourse/launcher rebuild app
