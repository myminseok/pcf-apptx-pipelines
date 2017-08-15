#!/bin/bash
set -e

function retrieveGroupId() {
    local result=$( ruby -r rexml/document -e 'puts REXML::Document.new(File.new(ARGV.shift)).elements["/project/groupId"].text' pom.xml || ./mvnw ${BUILD_OPTIONS} org.apache.maven.plugins:maven-help-plugin:2.2:evaluate -Dexpression=project.groupId |grep -Ev '(^\[|Download\w+:)' )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

function retrieveAppName() {
    local result=$( ruby -r rexml/document -e 'puts REXML::Document.new(File.new(ARGV.shift)).elements["/project/artifactId"].text' pom.xml || ./mvnw ${BUILD_OPTIONS} org.apache.maven.plugins:maven-help-plugin:2.2:evaluate -Dexpression=project.artifactId |grep -Ev '(^\[|Download\w+:)' )
    result=$( echo "${result}" | tail -1 )
    echo "${result}"
}

function outputFolder() {
    echo "target"
}

function testResultsAntPattern() {
    echo "**/surefire-reports/*"
}