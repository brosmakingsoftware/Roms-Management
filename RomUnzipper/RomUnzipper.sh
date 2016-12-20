#!/bin/bash

# Defining colors to be used
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NO_COLOR='\033[0m'


echo -e "${GREEN}------------------------------${NO_COLOR}"
echo -e "${GREEN}ROM UNZIPPER SCRIPT V1.0${NO_COLOR}"
echo -e "${GREEN}------------------------------${NO_COLOR}"
echo ""
echo -e "${GREEN}\
Description:\n\
This script helps you to unzip roms and rename them using the zip file name in one fast execution.\n\
In the past if you used a rom-renamer program on your zipped roms, the program renamed only the \n\
file name of the zip files and not the actual rom file name (the compressed file), because they \n\
don't unzip and zip again the roms.\n\
So, when for some reason you want to unzip your roms, you will notice that some of them doesn't \n\
have the correct name given by the rom-renamer program, and that's the issue that this script \n\
helps you to manage.\n\
This script unzip the rom and renames the it using the name of the zip file, obviously not \n\
replacing the extension of the rom.\n\
Please notice that this script expect the zip files to only have one rom file without folders,\n\
so if one of these two exceptions is found, the zip file is moved to a folder (ZipFilesWithFolders \n\
or ZipsWithMoreThan1File) and ignored from the process, so you can later unzip them manually.\
${NO_COLOR}"
echo ""
echo -e "${YELLOW}REMEMBER: Always backup your roms before running this or any other batch process.${NO_COLOR}"
echo ""
echo ""


# Defining the folder where the roms are located, this value is taken as parameter
ROM_FOLDER=$1

# Defining counters used to final report
zips_with_folders=0
zips_with_more_than_one_file=0
zips_processed=0
zips_renamed=0


# Let's use ROM_FOLDER as our base folder
cd $ROM_FOLDER

# This deletes UnzippedRoms if already exists, so each executing of this script does not interfere with the other
if [ -d "UnzippedRoms" ]
then
	chmod -R a+rw UnzippedRoms
	rm -R UnzippedRoms
fi


echo -e "${GREEN}------------------------------${NO_COLOR}"
echo -e "${GREEN}Starting to check zip files on folder: $ROM_FOLDER${NO_COLOR}"
echo -e "${GREEN}Please wait...${NO_COLOR}"


# This loop check and process the zips files
for file in *.zip
do

	# We want to exclude zip files that contain folders because we are expecting just the rom file directly

	# This line prints how many folders the zip has
	folders_count=$(zipinfo "$file" | grep ^d | wc -l)


	# If folders_count is more than 0, then we move the zip to another folder to ignore it
	if [ $folders_count -gt 0 ];
	then
		echo -e "${YELLOW}----------${NO_COLOR}"
		echo -e "${YELLOW}Warning: The following zip contains folders:${NO_COLOR}"
		echo -e "${YELLOW}File: $file${NO_COLOR}"
		echo -e "${YELLOW}Folder Count: $folders_count${NO_COLOR}"
		echo -e "${YELLOW}No folders are expected on zipped roms files${NO_COLOR}"

		mkdir -p ZipsWithFolders
		mv "$file" ZipsWithFolders/

		echo -e "${YELLOW}This file was moved to a folder called \"ZipsWithFolders\" and will not be processed.${NO_COLOR}"

		# Incrementing count for final report
		zips_with_folders=$((zips_with_folders+1))

	else

		# Now we want to exclude zip files that contain more than 1 file, because we are expecting just the rom file directly 

		# This line prints how many files are zipped
		files_count=$(zipinfo -t "$file" | awk '{print $1}')


		# If files_count is more than 1, then we move the zip to another folder to ignore it
		if [ $files_count -gt  1 ];
		then
			echo -e "${YELLOW}----------${NO_COLOR}"
			echo -e "${YELLOW}Warning: The following zip contains more than 1 file:${NO_COLOR}"
			echo -e "${YELLOW}File: $file${NO_COLOR}"
			echo -e "${YELLOW}File Count: $files_count${NO_COLOR}"

			mkdir -p ZipsWithMoreThan1File
			mv "$file" ZipsWithMoreThan1File/

			echo -e "${YELLOW}This file was moved to a folder called \"ZipsWithMoreThan1File\" and will not be processed.${NO_COLOR}"

			# Incrementing count for final report
			zips_with_more_than_one_file=$((zips_with_more_than_one_file+1))

		else

			# At this point the zip is good, which means that it doesn't have zipped folders and just has 1 file
			# So now we want to unzip and rename the rom

			zip_extension=".zip"
			zip_name=${file%$zip_extension}

			
			rom_file_name=$(unzip -Z1 "$file")
			rom_extension=$([[ "$rom_file_name" = *.* ]] && echo ".${rom_file_name##*.}" || echo '')
			rom_name=${rom_file_name%$rom_extension}

			# This created the folder where all the unzipped rom will be
			mkdir -p UnzippedRoms

			# This extracts the rom
			unzip -q "$file" -d UnzippedRoms/

			# File extracted is owned by root, so this open the read/write access to all users
			chmod a+rw UnzippedRoms/"$rom_file_name"

			# If zip name is different than the rom name, we report the missmatch and rename the rom using the zip name
			if [ "$zip_name" != "$rom_name" ]
			then
				echo -e "${YELLOW}----------${NO_COLOR}"
				echo -e "${YELLOW}Found a name missmatch${NO_COLOR}"
				echo -e "${YELLOW}Zip Name: $zip_name${NO_COLOR}"
				echo -e "${YELLOW}Rom Name: $rom_name${NO_COLOR}"
				mv UnzippedRoms/"$rom_file_name" UnzippedRoms/"$zip_name$rom_extension"
				echo -e "${GREEN}Renamed rom to: $zip_name$rom_extension${NO_COLOR}"

				# Incrementing count for final report
				zips_renamed=$((zips_renamed+1))
			fi

			# Incrementing count for final report
			zips_processed=$((zips_processed+1))

		fi
	fi

done

# We are finished, so now we want to print the report of the counters
echo ""
echo ""
echo -e "${GREEN}------------------------------${NO_COLOR}"
echo -e "${GREEN}------------------------------${NO_COLOR}"

# This line prints the count of files on the UnzippedRoms folder
roms_count=$(ls -1 UnzippedRoms | wc -l)

# This sums the 2 counts of ingored files
total_ignored_zips=$((zips_with_folders+zips_with_more_than_one_file))

# Printing the report
echo -e "${GREEN}Report:${NO_COLOR}"
echo -e "${GREEN}Ignored zips (with folders inside)    : $zips_with_folders${NO_COLOR}"
echo -e "${GREEN}Ignored zips (with more than 1 files) : $zips_with_more_than_one_file${NO_COLOR}"
echo -e "${GREEN}Total ignored files                   : $total_ignored_zips${NO_COLOR}"
echo -e "${YELLOW}----------${NO_COLOR}"
echo -e "${GREEN}Processed zips : $zips_processed${NO_COLOR}"
echo -e "${GREEN}Extracted roms : $roms_count${NO_COLOR}"
echo -e "${GREEN}Renamed roms   : $zips_renamed${NO_COLOR}"

exit_code=0

# If the count of processed zips is the same as the count of roms, then we print a positive message, otherwise a error message
if [ $zips_processed -eq $roms_count ];
then
	echo -e "${GREEN}Count of zips processed matches the count of roms extracted.${NO_COLOR}"
else
	echo -e "${RED}ERROR: Count of zips processed DOESN'T MATCH the count of roms extracted${NO_COLOR}"
	echo -e "${RED}Please check the log printed above to find the cause, fix the situation and run again this script.${NO_COLOR}"
	exit_code=1
fi

echo -e "${GREEN}------------------------------${NO_COLOR}"
echo -e "${GREEN}------------------------------${NO_COLOR}"
echo ""
echo ""

echo -e "${YELLOW}----------End of script----------${NO_COLOR}"
exit $exit_code                                                                                                                                                                    