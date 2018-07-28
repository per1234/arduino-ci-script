# Create a symlink
# Must be run as administrator
cd ContainsSymlink
rm -f IsSymlink
cmd <<<"mklink IsSymlink ..\\ValidLibrary\\"
read -rsp $'\n\nPress any key to continue...\n' -n 1
