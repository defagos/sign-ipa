#!/bin/bash

# Constants
VERSION_NBR=1.0
SCRIPT_NAME=`basename $0`
# Directory from which the script is executed
EXECUTION_DIR=`pwd`

# Global variables
output_dir=""
temp_dir=""
app_dir=""
provision_file=""
provision_filename_no_ext=""
certificate_name=""
ipa_file=""
ipa_filename_no_ext=""
output_ipa_file=""

# User manual
usage() {
    echo ""
    echo "Sign an existing signed ipa using another provisioning profile. On success, an ipa with "
    echo "the same name as the original ipa and the provisioning proflie name as suffix is created."
    echo "This ipa is saved by default in the same directory as the original ipa."
    echo ""
    echo "Usage: $SCRIPT_NAME [-o output_dir] [-h] [-v] provision_file certificate_name ipa_file"
    echo ""
    echo "Mandatory parameters:"
    echo "   provision_file              The path of the .mobileprovision file to use"
    echo "   certificate_name            The name of the keychain certificate to use"
    echo "   ipa_file                    The path of the ipa to sign"
    echo ""
    echo "Options:"
    echo "   -o:                         Output directory. If omitted, same as the original ipa"
    echo "   -h:                         Display this documentation"
    echo "   -v:                         Display the script version number"
    echo ""
}

cleanup() {
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

# Processing command-line parameters
while getopts o:hv OPT; do
    case "$OPT" in
        o)
            output_dir="$OPTARG"
            ;;
        h)
            usage
            exit 0
            ;;
        v)
            echo "$SCRIPT_NAME version $VERSION_NBR"
            exit 0
            ;;
        \?)
            usage
            exit 1
            ;;
    esac
done

# Read the remaining mandatory parameters
shift `expr $OPTIND - 1`
for arg in "$@"; do
    if [ -z "$provision_file" ]; then
        provision_file="$arg"
    elif [ -z "$certificate_name" ]; then
        certificate_name="$arg"
    elif [ -z "$ipa_file" ]; then
        ipa_file="$arg"
    else
       usage
       exit 1
    fi
done

# If the last argument is not filled, incomplete command line
if [ -z "$ipa_file" ]; then
    usage
    exit 1
fi

# Check that the provisioning profile exists
if [ ! -f "$provision_file" ]; then
    echo "[Error] The provisioning profile $provision_file does not exist"
    exit 1
fi

# Check that the ipa exists
if [ ! -f "$ipa_file" ]; then
    echo "[Error] The ipa file $ipa_file does not exist"
    exit 1
fi

# Output directory: Same directory as the original ipa if omitted
if [ -z "$output_dir" ]; then
    output_dir=`dirname "$ipa_file"`
fi

# Create the output directory if it does not exist
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
fi

# Cleanup working directory
temp_dir="$output_dir/ipa_extraction"
if [ -d "$temp_dir" ]; then
   rm -rf "$temp_dir"
fi

# Extract ipa
echo "Extracting ipa..."
unzip -q "$ipa_file" -d "$temp_dir"
if [ "$?" -ne "0" ]; then
    echo "[ERROR] ipa extraction failed"
    cleanup
    exit 1
fi

# Add provisioning profile
echo "Replacing provisioning profile..."
app_dir=`ls -1 "$temp_dir/Payload"`
app_dir="$temp_dir/Payload/$app_dir"
cp "$provision_file" "$app_dir/embedded.mobileprovision"

# 
# /usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1.1" "$app_dir/Info.plist"

# Perform code signing
echo "Signing ipa..."
codesign -fs "$certificate_name" --resource-rules="$app_dir/ResourceRules.plist" "$app_dir" &> /dev/null
if [ "$?" -ne "0" ]; then
    echo "[ERROR] Code signing failed"
    cleanup
    exit 1
fi

# Verify code signing
echo "Verifying the signature..."
codesign -v "$app_dir" &> /dev/null
if [ "$?" -ne "0" ]; then
    echo "[ERROR] Code signing verification failed"
    cleanup
    exit 1
fi

# Create the new ipa
echo "Creating the ipa..."
ipa_filename_no_ext=`basename "$ipa_file"`
ipa_filename_no_ext=${ipa_filename_no_ext%.*}
provision_filename_no_ext=`basename "$provision_file"`
provision_filename_no_ext=${provision_filename_no_ext%.*}
output_ipa_file="$output_dir/$ipa_filename_no_ext($provision_filename_no_ext).ipa"
pushd "$temp_dir" > /dev/null
zip -r "$output_ipa_file" . > /dev/null
popd > /dev/null
if [ "$?" -ne "0" ]; then
    echo "[ERROR] ipa creation failed"
    cleanup
    exit 1
fi

# Cleanup
cleanup

# Done
echo "Successfully created $output_ipa_file"