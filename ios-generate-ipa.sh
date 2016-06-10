#!/bin/bash

usage () {
# Outputs Help message.

read -r -d '' HelpMsg << DESCRIPTION

Generates an iOS IPA from the latest
available XCode archive and puts it in the
Mac OS X Downloads directory.
Also generates a QA summary with recent
commits.


usage: ios-generate-ipa -p provisioningProfileName -s SchemeName -c cordovaProjectPath


Assumptions:

- Mac OS X
- User has the default OS X "Downloads" folder
- Script executed in a git project folder
  to generate the output message
- schemeName matches the existing scheme
  - A schemeName can be found in the project folder
  - with xcodebuild -list under "Schemes:"


DESCRIPTION

echo -e "\n$HelpMsg"

}

qaSummary () {
  # Output summary for QA

  echo -e "QA Summary\n\n"
  echo "***********"
  echo -e "$LatestXCARoot iOS Build\n\n"
  echo -e "Latest Build. The current fixes are ready for testing. Please review. \n\n"

  echo -e "Most Recent Commits\n"
  git log --pretty=format:"date: %ci %nhash: %H %nmessage: %s %n%n" -n 3
  echo "***********"

  echo -e "\n\n"

  echo -e "IPA exported: $HOME/Downloads/$LatestXCARoot.ipa"
}


# Extract CLI options.
# p requires an option arg.

options=':p:s:c:h'
while getopts $options option
do
  case $option in
    p  ) ProvProfName=$OPTARG;;
    s  ) SchemeName=$OPTARG;;
    c  ) cordovaProjectPath=$OPTARG;;
    h  ) usage; exit;;
    \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
    :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
    *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
  esac
done

# Exception for missing provisioning profile name
if [ -z ${ProvProfName+x} ]; then exit "Missing option (-p provisioningProfileName)"; fi

# Exception for missing scheme
if [ -z ${SchemeName+x} ]; then exit "Missing option (-s SchemeName)"; fi

# Exception for missing cordova path
if [ -z ${cordovaProjectPath+x} ]; then exit "Missing option (-c cordovaProjectPath)"; fi

xcodebuild -project "$cordovaProjectPath" -scheme "$SchemeName" archive

if [ $? -ne 0 ]
then
  # the last command xcodebuild failed
  echo "Unable to generate XCode archive."
else
  # set XCode archive path
  XCArcPath="$HOME/Library/Developer/Xcode/Archives"
  echo $XCArcPath

  # get most recently modified folder in XCArcPath
  LatestFolder="$(\ls -1dt $XCArcPath/*/ | head -n 1)"

  # get most recent XCode Archive in that folder
  LatestFullXCA="$(ls -t $LatestFolder/ | head -n 1)"

  # extract archive name without extension
  LatestXCARoot="${LatestFullXCA%.*}"
  echo $LatestXCARoot

  # Build the IPA in the Downloads folder.
  xcodebuild -exportArchive -archivePath "$LatestFolder$LatestFullXCA" -exportPath "$HOME/Downloads/$LatestXCARoot" -exportFormat ipa -exportProvisioningProfile "$ProvProfName"

  if [ $? -ne 0 ]
  then
    # the last command xcodebuild failed
    echo "Unable to generate XCode IPA."
  else
    # xcodebuild succeeded
    qaSummary
  fi

fi
