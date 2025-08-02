#!/opt/homebrew/bin/zsh -f
# A script for renaming screenshots and adding certain metadata

readonly SCRIPT_NAME=${0:t2:r}

show_usage () {
    echo "usage: ${SCRIPT_NAME} [-v | --verbose, -h | --help ] [-i | --input source] [-o | --output target] [*.args arg files]" 1>&2
}

error_on_invalid_option () {
    echo "${SCRIPT_NAME}: invalid option -- $1" 1>&2
    show_usage
    exit 1
}

# Exit with 2 if the arg is not a directory
# $1: "Input" or "Output"
# $2: An input or output directory
error_if_not_dir () {
    if [[ ! -d $2 ]]; then
        echo "$1 is not a directory: $2" 1>&2
        show_usage
        exit 2
    fi

    return 0
}

################################################################################

output_dir=$PWD
declare -Ua tag_files
while (($#)); do
    case $1 in
        -h | --help   ) show_usage; exit
        ;;
        -v | --verbose) integer -r is_verbose=1
        ;;
        -i | --input  ) error_if_not_dir Input $2; cd "$2"; shift
        ;;
        -o | --output ) error_if_not_dir Output $2; output_dir=$2; shift
        ;;
        -* | --*      ) error_on_invalid_option $1
        ;;
        *.args        ) tag_files+="-@ $1"
        ;;
        *             ) error_on_invalid_option $1
        ;;
    esac
    shift
done

readonly orig_filename_pattern='*2<-1><-9><-9>-<-1><-9>-<-3><-9>*<-2><-9>.<-5><-9>.<-5><-9>*.*(.N)'
declare -Ua screenshot_files
readonly screenshot_files=(${~orig_filename_pattern})
if ((${#screenshot_files} == 0)); then
    echo "No screenshots to process: ${PWD}" 1>&2
    exit 2
fi

readonly timezone=$(date +%z)

# PERL string replacement patterns that will be used by ExifTool
readonly re='^.+?(2[0-1])(\d{2})-([0-1]\d)-([0-3]\d).+([0-2]\d)\.([0-5]\d)\.([0-5]\d)(\s\(\d+?\))?\..+?$'
readonly orig_str_pattern="Filename;s/${re}"
readonly new_filename_pattern="\${${orig_str_pattern}/\$2\$3\$4_\$5\$6\$7\$8.%e/}"
readonly new_datetime_pattern="\${${orig_str_pattern}/\$1\$2-\$3-\$4T\$5:\$6:\$7${timezone}/}"

readonly hardware=$(system_profiler SPHardwareDataType | sed -En 's/^.*Model Name: //p')

exiftool ${is_verbose:+'-v'} -P -struct     ${==screenshot_files}\
    "-directory=${output_dir}"              "-Filename<${new_filename_pattern}"\
    "-AllDates<${new_datetime_pattern}"     "-OffsetTime*=${timezone}"\
    '-MaxAvailHeight<ImageHeight'           '-MaxAvailWidth<ImageWidth'\
    '-RawFileName<FileName'                 '-PreservedFileName<FileName'\
    "-Software=$(sw_vers --productVersion)" "-Model=${hardware}"\
    ${=tag_files}

if (($? == 0)); then
    readonly archive="${output_dir}/Screenshots_$(date +%y%m%d_%H%M%S).tar"
    tar -cf "$archive" ${==screenshot_files}
    gzip ${is_verbose:+'-v'} -1 "$archive"

    rm ${==screenshot_files}
fi
