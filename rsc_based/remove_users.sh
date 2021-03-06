# get the file containing the student information
while [  -z ${filepath} ]
do
	echo ""
	echo "Please enter the path to the file containing the student information for the students to remove from the account."
	echo "Each line must represent one student and be a comma-separated list of the form:"
	echo "FirstName,LastName,CompanyName,EmailAddress,PhoneNumber,Password"
	echo ""
	
	read filepath
done

if [ ! -f ${filepath} ]
then
	echo "File not found."
	exit 1
fi

# Check to see that the rsc tool is installed.
rsc --version > /dev/null
if [ $? -ne 0 ]
then
	echo "Go to https://github.com/rightscale/rsc/blob/master/README.md and install the rsc tool for your OS."
	exit 1
fi

# Force the user to go through rsc setup to make sure it is configured for the subsequent steps.
echo "Please respond to the rsc setup prompts for the account you'll be populating."
echo "NOTE: The username/password being asked for here is your RightScale username and password."
rsc setup

echo ""

cat ${filepath} |
sed 's/,/ /g' |
while read firstName lastName companyName emailAddress phoneNumber password
do
	echo "Processing ${emailAddress}"

	# Find the user (ignore if not found)
	user_href=`rsc --x1 .links.href cm15 index /api/users "filter[]=email==${emailAddress}"` 
	if [ -z ${user_href} ]
	then
		# skip to the next user since this user is not found.
		echo "User, ${emailAddress}, not found. Skipping to next user"
		echo ""
		continue
	fi

	# Now go through and remove the roles from the user
	# NOTE You must do observer last
	for role in actor observer
	do
		# find the permission if it exists (ignore if it doesn't)
		perm_href=`rsc --pp --xm ":has(.role_title:val(\"${role}\")) > .links" cm15 index /api/permissions "filter[]=user_href==${user_href}" | 
		tr ',' '\n' | 
		grep permissions | 
		cut -d":" -f2 | 
		sed 's/"//g'` &> /dev/null

		# Remove the role if it still exists (ignore if it doesn't)
		rsc --pp cm15 destroy ${perm_href} &> /dev/null
	done
done
