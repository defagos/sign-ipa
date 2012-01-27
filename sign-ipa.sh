#!/bin/bash

# Constants
VERSION_NBR=1.0
SCRIPT_NAME=`basename $0`
# Directory from which the script is executed
EXECUTION_DIR=`pwd`

# Global variables
error=""
output_dir=""
plist_buddy_command=""
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
    echo "Usage: $SCRIPT_NAME [-o output_dir] [-p plist_buddy_command] [-h] [-v] provision_file "
    echo "       certificate_name ipa_file"
    echo ""
    echo "Mandatory parameters:"
    echo "   provision_file              The path of the .mobileprovision file to use"
    echo "   certificate_name            The name of the keychain certificate to use"
    echo "   ipa_file                    The path of the ipa to sign"
    echo ""
    echo "Options:"
    echo "   -h:                         Display this documentation"
    echo "   -o:                         Output directory. If omitted, same as the original ipa"
    echo "   -p:                         A PlistBuddy to be executed before signing, e.g."
    echo "                                   Set :CFBundleVersion 1.1"
    echo "                               to update the version number to 1.1"
    echo "   -v:                         Display the script version number"
    echo ""
}

cleanup() {
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

# Processing command-line parameters
while getopts ho:p:v OPT; do
    case "$OPT" in
        h)
            usage
            exit 0
            ;;
        o)
            output_dir="$OPTARG"
            ;;
        p)
            plist_buddy_command="$OPTARG"
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

# Execute optional PlistBuddy command
if [ ! -z "$plist_buddy_command" ]; then
    echo "Executing PlistBuddy command..."
    error=$(/usr/libexec/PlistBuddy -c "$plist_buddy_command" "$app_dir/Info.plist" 2>&1 > /dev/null)
    if [ "$?" -ne "0" ]; then
        echo "[ERROR] PlistBuddy command execution failed: $error"
        cleanup
        exit 1
    fi
    
    # Save as binary plist. Not needed (an XML plist works), but the original plist is binary
    plutil -convert binary1 "$app_dir/Info.plist"
fi

# Perform code signing
echo "Signing ipa..."
error=$(codesign -fs "$certificate_name" --resource-rules="$app_dir/ResourceRules.plist" "$app_dir" 2>&1 > /dev/null)
if [ "$?" -ne "0" ]; then
    echo "[ERROR] Code signing failed: $error"
    cleanup
    exit 1
fi

# Verify code signing
echo "Verifying the signature..."
error=$(codesign -v "$app_dir" 2>&1 > /dev/null)
if [ "$?" -ne "0" ]; then
    echo "[ERROR] Code signing verification failed: $error"
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