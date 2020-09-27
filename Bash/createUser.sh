#!/bin/bash

#This script automates the creation of an AWS IAM user: 
# - Login profile created - Default password must be reset
# - Tag is added
# - Option to add user to group
# - Option to create role and attach managed role policy script automates the creation of an AWS IAM user


create_user () {    #This function creates an IAM user, the login profile, initial password that must be reset, and then oupputs user info into new file
    
	touch ""$name"LoginInfo.txt" #This creates the file where user info will be stored
	aws iam create-user --user-name $name 
	
	while [ $? -ne 0 ]; #This loop repeats the previous function if an error occurred
	do
		echo -n "Please enter another name: "
		read name
		aws iam create-user --user-name $name
	done
	
	aws iam get-user --user-name $name > ""$name"LoginInfo.txt" #Writes user description to created file
    echo -n "User created. Enter default password for login profile: " 
    read pass
	    
	while true
    do
		echo -n "Confirm password: " 
		read pass_confirm
        case $pass_confirm in #This checks to see if the two entries of default password match  
			
			$pass) 	aws iam create-login-profile --user-name $name --password $pass --password-reset-required #Login profile is created for IAM user with password reset requirement
					
					if [ $? -ne 0 ]
					then
						echo -n "Please try password setup again: "
						read pass
					else
						break
					fi
					;;
			
			* ) 	echo -n "Entries don't match. Please enter default password again: " 
					read pass 
					;;		
		esac
	done
}

 
add_to_group () { #This function adds user to group if desired 
   
	echo -n "Insert name of group: "
	read group
	aws iam add-user-to-group --user-name $name --group-name $group
		
		while [ $? -ne 0 ];
		do
			echo -n "Please enter correct group name: "
			read group
			aws iam add-user-to-group --user-name $name --group-name $group
		done
	aws iam get-group --group-name $group >> ""$name"LoginInfo.txt"
	aws iam get-group --group-name $group
	echo -n ""$name" was added to "$group" group. "
}

attach_policy () { #This function asks to create a role for the new user and attach an existing role policy
	
	while true
	do
		echo -n "Would you like to create role for this user and attach a managed policy? Y/N - "
		read yes_no
		case $yes_no in
			
			[Yy]*) 	while true
					do
						echo -n "Are you sure? Y/N - " #Confirmation of decision
						read yes_no
						case $yes_no in
							
							[Yy]*) 	create_role
									
									while [ $? -ne 0 ];
									do
										create_role
									done
									
									echo "Role to be assumed by user:" >> ""$name"LoginInfo.txt"
									aws iam get-role --role-name $role_name >> ""$name"LoginInfo.txt"
									role_policy
									
									while [ $? -ne 0 ];
									do
										role_policy
									done									
									
									echo "Managed policy attached."
									read -rsn1 -p "Task is complete! All user info including login profile, tag, group and role, if created, is in new "$name"LoginInfo.txt file. Press any key to exit.";echo
									exit #Script ends with role creation
									;;
							
							[Nn]*) 	break
									;;
							
							* )  	echo "INVALID ENTRY "
									;;
						esac
					done
					;;

			[Nn]*) 	while true
					do
						echo -n "Are you sure? Y/N - "
						read yes_no
						case $yes_no in
							
							[Yy]*) 	read -rsn1 -p "Task is complete! All user info including login profile, tag, group and role, if created, is in new "$name"LoginInfo.txt file. Press any key to exit.";echo
									exit #script ends with no role creation
									;;
							
							[Nn]*) 	break
									;;
							
							* )    	echo "INVALID ENTRY "
									;;
						esac
					done
					;;
        
			* )    	echo "INVALID ENTRY "
					;;
		esac
	done
}

create_role () { #This function creates role 
	echo -n "Insert role name: "
	read role_name
	echo -n "Insert role policy document: "
	read role_doc
	aws iam create-role --role-name $role_name --assume-role-policy-document $role_doc	
}

role_policy () { #This function attaches existing managed policy to role 
	echo -n "Insert existing managed policy ARN: "
	read arn
	aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/$arn --role-name $role_name
}

echo -n "What is the name of the user you would like to create?: "	#Beginning of script where name of new user is requested
read name

while true
do
	echo -n "Please confirm name of user: | "$name" | Is this correct? Y/N - " #Confirming name of user
	read yes_no 
	case $yes_no in
		[Yy]*) 	create_user 
				echo "Default password:"$pass"" >> ""$name"LoginInfo.txt" #Appends default password at the end of created file
				echo -n "Success! Login profile created. In what department should the user be tagged?: "
				read dep_tag
				
				while true
				do
					aws iam tag-user --user-name $name --tags '{"Key": "Department", "Value": "'$dep_tag'"}' #This adds the tag based on Department
					aws iam list-user-tags --user-name $name
					echo -n "User is tagged as belonging to "$dep_tag" Department. Would you like to change this? Y/N - "
					read yes_no
					case $yes_no in
						
						[Yy]*)  echo -n "In what department should the user be tagged?: "				
								read dep_tag
								;;
							
						[Nn]*)	aws iam list-user-tags --user-name $name >> ""$name"LoginInfo.txt"
								while true
								do
									echo -n "Would you like to add this user to a group? Y/N - " #This asks if the new user should be added to a group
									read yes_no
									case $yes_no in
									
										[Yy]*) 	add_to_group
												attach_policy
												;;

										[Nn]*) 	while true
												do 
													echo -n "Are you sure? Y/N - " 
													read yes_no
													case $yes_no in
														
														[Yy]*) 	attach_policy
																;;
														
														[Nn]*) 	break
																;;
														
														* )    	echo "INVALID ENTRY " 
																;;
													esac
												done										
												;;
												
										* )    	echo "INVALID ENTRY " 
												;;
									esac
								done
								;;								
													
						* )    	echo "INVALID ENTRY " 
								;;
					esac							
				done
				;;					
						
		[Nn]*) 	echo -n "Please re-enter the user's name: "
				read name 
				;;
		
		* )    	echo "INVALID ENTRY " #This is the result if the input is not allowed
				;;
	esac
done















