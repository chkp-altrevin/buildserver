#!/bin/bash

# strapi the cool headless cms
echo "Skip registration, defaults etc."
cd $HOME/repos
npx create-strapi-app@latest strapi-base --quickstart
